
# build_test.sh
`build_test.sh` relies on `docker` and `curl`.
When it runs it will:
- build the docker image
- run a container from the image
- run the tests inside the container
- tar-pipe the coverage files out of the container
- open the coverage `index.html` in a browser

# 0.17.0
`app/Gemfile` contains
```
gem 'simplecov', '0.17.0'
```
Run `build_test.sh`
index.html has several entries/tabs; `app` and `test` both contain at least one file :-)

# 0.18.5
Edit `app/Gemfile` to either of these...
```
gem 'simplecov', '0.18.5'
gem 'simplecov', github: 'colszowka/simplecov'
```
Run `build_test.sh`
index.html has several entries/tabs; `test` is now empty :-(



# Notes
- The tests are run from `test/run.sh`
- It ensures `test/coverage.rb` is required first.
