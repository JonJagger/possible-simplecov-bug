
# build_test.sh
This relies on `docker` and `curl`.
It will:
- build the docker image
- run a container from the image
- run the tests inside the container
- tar-pipe the coverage files out of the container
- open the coverage `index.html` in a browser

# 0.17.0
`app/Gemfile` contains
```
gem 'simplecov', "0.17.0"
```
Run `build_test.sh`
The coverage has one entry for the `app` and `test` groups.

# 0.18.1
Edit `app/Gemfile` to
```
gem 'simplecov', "0.18.1"
```
Run `build_test.sh`
The coverage has one entry for the `app` group but none for `test` group :-(

# Notes
- The tests are run from `test/run.sh`
- It ensures `test/coverage.rb` is required first.
