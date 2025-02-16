# test_git_diff.t

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

Detect nothing if there is no diff:

  $ colcon package-of -g

Make an unstaged change and find the package:

  $ echo "<!-- TEST -->" >> src/pkg1/package.xml
  $ colcon package-of -g
  pkg1\tsrc/pkg1\t(ros.ament_python) (esc)

  $ colcon package-of --git-diff
  pkg1\tsrc/pkg1\t(ros.ament_python) (esc)

Stage the change and find the package:

  $ git add -A
  $ colcon package-of -g
  pkg1\tsrc/pkg1\t(ros.ament_python) (esc)

Commit the change and there will be no diff:

  $ $TESTDIR/do_git_commit.sh "UPDATE" .
  $ colcon package-of -g

Add a new file to the repo:

  $ echo "TEST" > src/pkg1/TEST.txt
  $ colcon package-of -g
  pkg1\tsrc/pkg1\t(ros.ament_python) (esc)

Do another commit:

  $ git add -A
  $ $TESTDIR/do_git_commit.sh "UPDATE2" .
  $ colcon package-of -g

Make changes in multiple directories:

  $ echo "TEST" >> src/pkg2/LICENSE
  $ echo "# TEST" >> src/pkg3/pkg3/lib3/__init__.py
  $ echo "# TEST" >> src/pkg3/pkg3/node3.py
  $ echo "# TEST" >> src/pkg4/pkg4/lib4/__init__.py
  $ echo "# TEST" >> src/pkg5/pkg5/node5.py
  $ git add src/pkg3/pkg3/lib3/__init__.py
  $ git add src/pkg3/pkg3/node3.py
  $ colcon package-of -g
  pkg2\tsrc/pkg2\t(ros.ament_python) (esc)
  pkg3\tsrc/pkg3\t(ros.ament_python) (esc)
  pkg4\tsrc/pkg4\t(ros.ament_python) (esc)
  pkg5\tsrc/pkg5\t(ros.ament_python) (esc)

Do another commit:

  $ git add -A
  $ $TESTDIR/do_git_commit.sh "UPDATE3" .
  $ colcon package-of -g

Make changes outside of a package:

  $ echo "TEST" >> src/README.txt
  $ colcon package-of -g

Then again with strict mode:

  $ colcon package-of -s -g
  Unmatched file path: src/README.txt
  [1]

Use the diff to an explicit commit:

Exit virtual environment:

  $ deactivate
