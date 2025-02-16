#!/bin/bash

# Copyright 2024 Tim Perkins
# Licensed under the Apache License, Version 2.0

set -o errexit
set -o nounset
set -o pipefail
IFS=$'\n\t'

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

WS_DIR=${1:-}
if [ -z "$WS_DIR" ] || [ ! -d "$WS_DIR" ]; then
    echo "ERROR: Must provide a workspace directory!"
    exit 1
fi

ros2_pkg_create() {
    ros2 pkg create "$@" | grep -Ev "^(creating|destination directory)" >&2
}

ros2_pkg_create \
    --description TEST \
    --license MIT \
    --destination-directory "$WS_DIR/src" \
    --build-type ament_python \
    --maintainer-email TEST@TEST.TEST \
    --maintainer-name TEST \
    --library-name lib1 \
    pkg1

ros2_pkg_create \
    --description TEST \
    --license MIT \
    --destination-directory "$WS_DIR/src" \
    --build-type ament_python \
    --dependencies pkg1 \
    --maintainer-email TEST@TEST.TEST \
    --maintainer-name TEST \
    --library-name lib2 \
    pkg2

ros2_pkg_create \
    --description TEST \
    --license MIT \
    --destination-directory "$WS_DIR/src" \
    --build-type ament_python \
    --dependencies pkg2 \
    --maintainer-email TEST@TEST.TEST \
    --maintainer-name TEST \
    --library-name lib3 \
    --node-name node3 \
    pkg3

ros2_pkg_create \
    --description TEST \
    --license MIT \
    --destination-directory "$WS_DIR/src" \
    --build-type ament_python \
    --dependencies pkg1 \
    --maintainer-email TEST@TEST.TEST \
    --maintainer-name TEST \
    --library-name lib4 \
    --node-name node4 \
    pkg4

ros2_pkg_create \
    --description TEST \
    --license MIT \
    --destination-directory "$WS_DIR/src" \
    --build-type ament_python \
    --dependencies pkg3 pkg4 \
    --maintainer-email TEST@TEST.TEST \
    --maintainer-name TEST \
    --node-name node5 \
    pkg5

# Ignore future log directories
cat <<EOF > "$WS_DIR/.gitignore"
/build/
/install/
/log/
EOF

# Create a Git repo with one commit
pushd "$WS_DIR" &> /dev/null
git init -q
git add -A
"$SCRIPT_DIR/do_git_commit.sh" "INIT" .
popd &> /dev/null

exit 0
