# colcon-package-of

Given a set of files, output a list of packages which contain those files.

```text
$ colcon package-of src/pkgX/foo.txt src/pkgY/bar.txt
pkgX    src/pkgX    (python)
pkgY    src/pkgY    (python)
```

The `--names-only` and `--paths-only` options can be used to adjust the output.

For convince, there is also a `--git-diff` option, which is basically equivalent
to using `git diff` with `xargs`. If there are added, deleted, modified, or
untracked files corresponding to a package, that package will be listed:

``` text
$ touch src/pkgA/newfoo.txt
$ rm src/pkgB/oldbar.txt
$ colcon package-of --git-diff HEAD
pkgA    src/pkgA    (python)
pkgB    src/pkgB    (python)
```

## Example Usage

Let's say you have a list of modified files, and you want to incrementally build
only the packages corresponding to those files. You can do this:

```text
MY_PKGS=$(colcon package-of -n $MY_FILES)
[ -z "$MY_PKGS" ] || colcon build --packages-above $MY_PKGS
```

You may be able to take advantage of the `--git-diff` option in CI, to build
only the packages that have changed since the last commit:

``` text
DIFF_PKGS=$(colcon package-of -n --git-diff HEAD^)
[ -z "$DIFF_PKGS" ] || colcon build --packages-above $DIFF_PKGS
```

## Minimum Python Version

Unlike `colcon-core` which supports Python 3.6, `colcon-package-of` requires
Python 3.10 due to use of `Path.is_relative_to`, etc.

## OS Support

This package is tested on Linux (Ubuntu 22.04) and MacOS. It is not tested on
Windows (yet).
