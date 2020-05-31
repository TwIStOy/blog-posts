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

  git init
  git config user.name "GitHub Actions"
  git config user.email "github-actions-bot@users.noreply.github.com"
  git add .

  remote_repo="https://${GITHUB_TOKEN}@github.com/${PAGES_REPOSITORY}.git"
  remote_branch=$PAGES_BRANCH

  git push --force "${remote_repo}" master:${remote_branch}
}

main "$@"
