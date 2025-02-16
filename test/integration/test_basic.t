# test_basic.t

# Copyright 2024 Tim Perkins
# Licensed under the Apache License, Version 2.0

Check the testing environment:

  $ $TESTDIR/check_env.sh
  The test environment is OK

Setup Colcon in a virtual environment:

  $ REPO_ROOT=$(cd $TESTDIR/../.. && pwd)
  $ ACTIVATE_SCRIPT=$($TESTDIR/setup_colcon.sh $TESTDIR/requirements.txt $REPO_ROOT .)

Enter virtual environment:

  $ . $ACTIVATE_SCRIPT

Display usage:

  $ colcon package-of --help
  usage: colcon package-of [-h] [--base-paths [PATH ...]] [--paths [PATH ...]]
                           [--topological-order] [--strict]
                           [--git-diff [GIT_DIFF]] [--names-only | --paths-only]
                           [FILE-PATHS ...]
  
  Get packages of files.
  
  positional arguments:
    FILE-PATHS            File paths to get the packages of
  
  options:
    -h, --help            show this help message and exit
    --topological-order, -t
                          Order output based on topological ordering (breadth-
                          first)
    --strict, -s          Operate in strict mode where unmatched files are an
                          error
    --git-diff [GIT_DIFF], -g [GIT_DIFF]
                          Get the list of files from Git diff
    --names-only, -n      Output only the name of each package but not the path
    --paths-only, -p      Output only the path of each package but not the name
  
  Discovery arguments:
    --base-paths [PATH ...]
                          The base paths to recursively crawl for packages
                          (default: .)
    --paths [PATH ...]    The paths to check for a package. Use shell wildcards
                          (e.g. `src/*`) to select all direct subdirectories

Set up the mock workspace:

  $ $TESTDIR/setup_mock_ws.sh .
  going to create a new package
  package name: pkg1
  package format: 3
  version: 0.0.0
  description: TEST
  maintainer: ['TEST <TEST@TEST.TEST>']
  licenses: ['MIT']
  build type: ament_python
  dependencies: []
  library_name: lib1
  going to create a new package
  package name: pkg2
  package format: 3
  version: 0.0.0
  description: TEST
  maintainer: ['TEST <TEST@TEST.TEST>']
  licenses: ['MIT']
  build type: ament_python
  dependencies: ['pkg1']
  library_name: lib2
  going to create a new package
  package name: pkg3
  package format: 3
  version: 0.0.0
  description: TEST
  maintainer: ['TEST <TEST@TEST.TEST>']
  licenses: ['MIT']
  build type: ament_python
  dependencies: ['pkg2']
  node_name: node3
  library_name: lib3
  going to create a new package
  package name: pkg4
  package format: 3
  version: 0.0.0
  description: TEST
  maintainer: ['TEST <TEST@TEST.TEST>']
  licenses: ['MIT']
  build type: ament_python
  dependencies: ['pkg1']
  node_name: node4
  library_name: lib4
  going to create a new package
  package name: pkg5
  package format: 3
  version: 0.0.0
  description: TEST
  maintainer: ['TEST <TEST@TEST.TEST>']
  licenses: ['MIT']
  build type: ament_python
  dependencies: ['pkg3', 'pkg4']
  node_name: node5

Find packages for the given files:

  $ colcon package-of src/pkg1/package.xml
  pkg1\tsrc/pkg1\t(ros.ament_python) (esc)

  $ colcon package-of src/pkg3/test/test_pep257.py
  pkg3\tsrc/pkg3\t(ros.ament_python) (esc)

Try finding something not belonging to a package:

  $ colcon package-of src/pkgX/this/does/not/exist

Find multiple packages:

  $ colcon package-of src/pkg1/package.xml src/pkg2/pkg2/lib2/__init__.py
  pkg1\tsrc/pkg1\t(ros.ament_python) (esc)
  pkg2\tsrc/pkg2\t(ros.ament_python) (esc)

  $ colcon package-of src/pkg3/test/test_pep257.py src/pkgX/this/does/not/exist
  pkg3\tsrc/pkg3\t(ros.ament_python) (esc)

Print only package names:

  $ colcon package-of -n src/pkg1/package.xml
  pkg1

  $ colcon package-of --names-only src/pkg3/test/test_pep257.py
  pkg3

Print only package paths:

  $ colcon package-of -p src/pkg1/package.xml
  src/pkg1

  $ colcon package-of --paths-only src/pkg3/test/test_pep257.py
  src/pkg3

Exit virtual environment:

  $ deactivate
