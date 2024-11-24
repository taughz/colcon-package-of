# Copyright 2024 Tim Perkins
# Licensed under the Apache License, Version 2.0

from pathlib import Path
import shlex
import subprocess
import sys

import pytest


@pytest.mark.linter
def test_black():
    print()
    py_paths = find_python_files(Path(__file__).parents[1])
    format_ok = [black_formatting_ok(p) for p in py_paths]
    assert all(format_ok), "Some files are are not formatted by Black"


def find_python_files(root_path):
    return [*Path(root_path).resolve().rglob("*.py")]


def black_formatting_ok(src_path):
    """Invoke Black as a subprocess because it doesn't actually have an API."""
    black_result = subprocess.run(
        shlex.split(f"black -q --check '{src_path}'"),
        capture_output=True,
        check=False,
        text=True,
    )
    format_ok = black_result.returncode == 0
    if not format_ok:
        print("Bad formatting in:", src_path, file=sys.stderr)
        print(black_result.stderr, file=sys.stderr)
    else:
        print("Good formatting in:", src_path)
    return format_ok
