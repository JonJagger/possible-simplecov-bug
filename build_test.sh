#!/bin/bash -Eeu

#- - - - - - - - - - - - - - - - - - - - - - -
readonly ROOT_DIR="$( cd "$( dirname "${0}" )" && pwd )"
readonly MY_NAME=bug
readonly USERNAME=nobody
readonly TEST_TYPE=server

readonly BUG_IMAGE_NAME="cyberdojo/${MY_NAME}"
readonly BUG_CONTAINER_NAME="test-${MY_NAME}-${TEST_TYPE}"
readonly BUG_PORT=4567

#- - - - - - - - - - - - - - - - - - - - - - -
build_image()
{
  docker build \
    --build-arg BUG_PORT=${BUG_PORT} \
    --tag ${BUG_IMAGE_NAME} \
    "${ROOT_DIR}/app"
}

# - - - - - - - - - - - - - - - - - - - - - -
ip_address()
{
  if [ -n "${DOCKER_MACHINE_NAME}" ]; then
    docker-machine ip ${DOCKER_MACHINE_NAME}
  else
    printf localhost
  fi
}

# - - - - - - - - - - - - - - - - - - - - - -
wait_until_ready()
{
  local -r name=test-${MY_NAME}-${TEST_TYPE}
  printf "Waiting until ${name} is ready"
  local -r max_tries=20
  local -r my_ip_address=$(ip_address)
  for _ in $(seq ${max_tries}); do
    if curl_ready ${my_ip_address}; then
      printf '.OK\n'
      return
    else
      printf .
      sleep 0.05
    fi
  done
  printf 'FAIL\n'
  echo "not ready after ${max_tries} tries"
  if [ -f "$(ready_filename)" ]; then
    cat ready_response
  fi
  docker logs ${name}
  exit 42
}

# - - - - - - - - - - - - - - - - - - -
curl_ready()
{
  local -r ip_address="${1}"
  local -r port="${BUG_PORT}"
  local -r path=ready?
  local -r url="http://${ip_address}:${port}/${path}"
  rm -f "$(ready_filename)"
  curl \
    --fail \
    --output $(ready_filename) \
    --silent \
    -X GET \
    "${url}"
  [ "$?" == '0' ] && [ "$(ready_response)" == '{"ready?":true}' ]
}

# - - - - - - - - - - - - - - - - - - -
ready_response()
{
  cat "$(ready_filename)"
}

# - - - - - - - - - - - - - - - - - - -
ready_filename()
{
  printf /tmp/curl-custom-ready-output
}

# - - - - - - - - - - - - - - - - - - -
container_up()
{
  printf '\n'
  docker container rm ${BUG_CONTAINER_NAME} --force 2> /dev/null || true
  docker run \
    --detach \
    --init \
    --name "${BUG_CONTAINER_NAME}" \
    --publish ${BUG_PORT}:${BUG_PORT} \
    --tmpfs /tmp \
    --user ${USERNAME} \
    --volume ${ROOT_DIR}/test:/test:ro \
    "${BUG_IMAGE_NAME}"
}

#- - - - - - - - - - - - - - - - - - - - - - -
run_tests()
{
  local -r reports_dir=reports
  local -r coverage_root=/tmp/${reports_dir}
  local -r test_log=test.log

  echo '=================================='
  echo "Running ${TEST_TYPE} tests"
  echo '=================================='

  set +e
  docker exec \
    --user "${USERNAME}" \
    "${BUG_CONTAINER_NAME}" \
      sh -c "/test/run.sh ${coverage_root} ${test_log} ${TEST_TYPE}"
  set -e

  # You can't [docker cp] from a tmpfs, so tar-piping coverage out...
  local -r test_dir="${ROOT_DIR}/test/${TEST_TYPE}" # ...to this dir
  docker exec \
    "${BUG_CONTAINER_NAME}" \
    tar Ccf \
      "$(dirname "${coverage_root}")" \
      - "$(basename "${coverage_root}")" \
        | tar Cxf "${test_dir}/" -

  echo "Coverage files copied to test/${TEST_TYPE}/${reports_dir}/"
}

#- - - - - - - - - - - - - - - - - - - - - - -
build_image
container_up
wait_until_ready
rm "${ROOT_DIR}/test/${TEST_TYPE}/reports/index.html"
run_tests
open "${ROOT_DIR}/test/${TEST_TYPE}/reports/index.html"
