#!/bin/bash

THIS_SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

set -e

bundle exec ruby "$THIS_SCRIPT_DIR/step.rb" -a "${apk_path}"