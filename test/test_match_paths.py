# Copyright 2024 Tim Perkins
# Licensed under the Apache License, Version 2.0

from dataclasses import dataclass
from pathlib import Path

from colcon_package_of.verb.package_of import PackageOfVerb


@dataclass
class MockPackage:
    name: str
    path: str


def test_match_paths():
    po_verb = PackageOfVerb()
    pkgs = [
        MockPackage("pkgX", "/ws/src/pkgX"),
        MockPackage("pkgY", "/ws/src/pkgY"),
        MockPackage("pkgA", "/ws/src/pkgA"),
        MockPackage("pkgB", "/ws/src/pkgB"),
    ]
    file_paths = {
        Path("/ws/src/pkgA/file.txt"),
        Path("/ws/src/pkgY/a/b/c/file.txt"),
        Path("/ws/src/pkgX/1/2/3file.txt"),
        Path("/ws/src/pkgQ/_/_/_/file.txt"),
    }
    m_pkgs = po_verb._match_file_paths_to_pkgs(pkgs, file_paths)
    # Check results
    assert len(m_pkgs) == 3, "Unexpected number of matched packages"
    assert m_pkgs[0].name == "pkgX", "Unexpected ordering of packages"
    assert m_pkgs[1].name == "pkgY", "Unexpected ordering of packages"
    assert m_pkgs[2].name == "pkgA", "Unexpected ordering of packages"
    # Check unmatched files
    assert len(file_paths) == 1, "Unexpected number of unmatched file paths"
    assert next(iter(file_paths)).is_relative_to(
        "/ws/src/pkgQ"
    ), "Unexpected matched file"
