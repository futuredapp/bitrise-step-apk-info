#!/bin/bash

THIS_SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

set -e

export BUNDLE_GEMFILE="$THIS_SCRIPT_DIR/Gemfile"

bundle update --bundler
bundle config set --local without "test"
bundle install --jobs 20 --retry 5

bundle exec ruby "$THIS_SCRIPT_DIR/step.rb" -a "${apk_path}"
