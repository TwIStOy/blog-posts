#!/usr/bin/env bash

set -e
set -o pipefail

if [[ -z "$GITHUB_TOKEN" ]]; then
  echo "Set the GITHUB_TOKEN env variable."
  exit 1
fi

main() {
  git submodule update --init --recursive

  version=$(/tmp/zola --version)
  echo "Using $version"

  /tmp/zola build

  cd public

  ls
  echo "twistoy.cn" >> CNAME
}

main "$@"
