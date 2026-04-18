#!/bin/bash
set -e
shopt -s globstar

exec luacheck g/**/*.lua \
  --globals checkArg \
  --no-self \
  --ignore '411/err' '431/err' '411/ok' '431/ok' '212/.*' \
  --codes
