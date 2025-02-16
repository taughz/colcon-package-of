#!/bin/bash

# Copyright 2024 Tim Perkins
# Licensed under the Apache License, Version 2.0

set -o errexit
set -o nounset
set -o pipefail
IFS=$'\n\t'

COMMIT_MSG=${1:-}
if [ -z "$COMMIT_MSG" ]; then
    echo "ERROR: Must provide commit message!"
    exit 1
fi

REPO_DIR=${2:-}
if [ -z "$REPO_DIR" ] || [ ! -d "$REPO_DIR" ]; then
    echo "ERROR: Must provide Git repo directory!"
    exit 1
fi

pushd "$REPO_DIR" &> /dev/null
export GIT_COMMITTER_NAME="TEST"
export GIT_COMMITTER_EMAIL="TEST@TEST.TEST"
git commit -q --no-verify -m "$COMMIT_MSG" --no-gpg-sign \
    --author "$GIT_COMMITTER_NAME <$GIT_COMMITTER_EMAIL>"
popd &> /dev/null

exit 0
