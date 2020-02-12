#!/bin/bash -Ee

#- - - - - - - - - - - - - - - - - - - - - - -
readonly ROOT_DIR="$( cd "$( dirname "${0}" )" && pwd )"
export CYBER_DOJO_CREATOR_IMAGE=cyberdojo/creator_mini
export CYBER_DOJO_CREATOR_PORT=4567

#- - - - - - - - - - - - - - - - - - - - - - -
build_images()
{
  docker-compose \
    --file "${ROOT_DIR}/docker-compose.yml" \
    build
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
readonly IP_ADDRESS=$(ip_address)

# - - - - - - - - - - - - - - - - - - - - - -
wait_briefly_until_ready()
{
  local -r port="${1}"
  local -r name="${2}"
  local -r max_tries=20
  printf "Waiting until ${name} is ready"
  for _ in $(seq ${max_tries}); do
    if curl_ready ${port}; then
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
    ready_response
  fi
  docker logs ${name}
  exit 42
}

# - - - - - - - - - - - - - - - - - - -
curl_ready()
{
  local -r port="${1}"
  local -r path=ready?
  local -r url="http://${IP_ADDRESS}:${port}/${path}"
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
  local -r service_name="${1}"
  printf '\n'
  docker-compose \
    --file "${ROOT_DIR}/docker-compose.yml" \
    up \
    --detach \
    --force-recreate \
    "${service_name}"
}

#- - - - - - - - - - - - - - - - - - - - - - -
run_tests()
{
  local -r my_name=creator
  local -r user="${1}" # eg nobody
  local -r type="${2}" # eg client|server
  local -r reports_dir=reports
  local -r coverage_root=/tmp/${reports_dir}
  local -r test_log=test.log
  local -r container_name="test-${my_name}-${type}" # eg test-creator-server

  echo '=================================='
  echo "Running ${type} tests"
  echo '=================================='

  set +e
  docker exec \
    --user "${user}" \
    "${container_name}" \
      sh -c "/test/run.sh ${coverage_root} ${test_log} ${type}"
  set -e

  # You can't [docker cp] from a tmpfs, so tar-piping coverage out...
  local -r test_dir="${ROOT_DIR}/test/${type}" # ...to this dir
  docker exec \
    "${container_name}" \
    tar Ccf \
      "$(dirname "${coverage_root}")" \
      - "$(basename "${coverage_root}")" \
        | tar Cxf "${test_dir}/" -

  echo "Test files copied to test/${type}/${reports_dir}/"
}

#- - - - - - - - - - - - - - - - - - - - - - -
build_images
container_up creator-server
wait_briefly_until_ready ${CYBER_DOJO_CREATOR_PORT} test-creator-server
run_tests nobody server
