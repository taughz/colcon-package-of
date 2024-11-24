# colcon-package-of

Given a set of file paths, output a list of packages which contain those files.

```text
colcon package-of src/pkgX/foo.txt src/pkgY/bar.txt
```

Will output something like this:

```text
pkgX    src/pkgX    (python)
pkgY    src/pkgY    (python)
```

Additionally, `--names-only` and `--paths-only` options are available.

## Minimum Python Version

Unlike `colcon-core` which support Python 3.6, `colcon-package-of` requires
Python 3.10 due to use of `Path.is_relative_to`, etc.

## OS Support

This package is tested on Linux (Ubuntu 22.04) and MacOS. It is not tested on
Windows (yet).
