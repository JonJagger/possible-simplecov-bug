#!/bin/bash -Eeu

export RUBYOPT='-W2'

rackup \
  --env production \
  --host 0.0.0.0   \
  --port ${PORT}   \
  --warn           \
    /app/config.ru
