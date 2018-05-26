#!/bin/bash

set -x -e -o pipefail

docker-compose up --exit-code-from wp
