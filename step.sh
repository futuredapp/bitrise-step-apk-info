#!/bin/bash

THIS_SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

set -e

export BUNDLE_GEMFILE="$THIS_SCRIPT_DIR/Gemfile"

echo
echo "=> Preparing step ..."
echo
bundle install --without test --jobs 20 --retry 5

echo
echo "=> Running the step ..."
echo
bundle exec ruby "$THIS_SCRIPT_DIR/step.rb" -d "${deploy_path}"