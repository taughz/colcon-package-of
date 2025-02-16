#!/bin/bash

# Copyright 2024 Tim Perkins
# Licensed under the Apache License, Version 2.0

set -o errexit
set -o nounset
set -o pipefail
IFS=$'\n\t'

if ! command -v git &> /dev/null; then
    echo "ERROR: Git must be installed!" >&2
    exit 1
fi

if ! command -v python &> /dev/null; then
    echo "ERROR: Python must be installed!" >&2
    exit 1
fi

if ! python -m venv -h &> /dev/null; then
    echo "ERROR: Python cannot create virtual environments!"
    exit 1
fi

if ! command -v ros2 &> /dev/null; then
    echo "ERROR: ROS 2 must be installed!" >&2
    exit 1
fi

echo "The test environment is OK" >&2

exit 0
