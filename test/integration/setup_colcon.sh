#!/bin/bash

# Copyright 2024 Tim Perkins
# Licensed under the Apache License, Version 2.0

# shellcheck disable=SC1090

set -o errexit
set -o nounset
set -o pipefail
IFS=$'\n\t'

REQUIREMENTS_TXT=${1:-}
if [ -z "$REQUIREMENTS_TXT" ] || [ ! -f "$REQUIREMENTS_TXT" ]; then
    echo "ERROR: Must provide requirements to install Colcon!"
    exit 1
fi

COLCON_TEST_PKG_DIR=${2:-}
if [ -z "$COLCON_TEST_PKG_DIR" ] || [ ! -d "$COLCON_TEST_PKG_DIR" ]; then
    echo "ERROR: Must provide package-under-test directory!"
    exit 1
fi

VENV_DEST_DIR=${3:-}
if [ -z "$VENV_DEST_DIR" ] || [ ! -d "$VENV_DEST_DIR" ]; then
    echo "ERROR: Must provide destination for the virtual environment!"
    exit 1
fi

# Clear the Python path to avoid interferance
export PYTHONPATH=""

# Setup virtual environment
VENV_DIR="$VENV_DEST_DIR/.venv"
python -m venv "$VENV_DIR" >&2

# Activate virtual environment
ACTIVATE_SCRIPT="$VENV_DIR/bin/activate"
. "$ACTIVATE_SCRIPT" >&2

# Install Colcon and the package under test
pip install -q --require-virtualenv -r "$REQUIREMENTS_TXT" -e "$COLCON_TEST_PKG_DIR" >&2

echo "$ACTIVATE_SCRIPT"

exit 0
