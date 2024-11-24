# Copyright 2024 Tim Perkins
# Licensed under the Apache License, Version 2.0

from pathlib import Path
import shlex
import subprocess

from colcon_core.package_augmentation import augment_packages
from colcon_core.package_discovery import add_package_discovery_arguments
from colcon_core.package_discovery import discover_packages
from colcon_core.package_identification import get_package_identification_extensions
from colcon_core.plugin_system import satisfies_version
from colcon_core.topological_order import topological_order_packages
from colcon_core.verb import VerbExtensionPoint


class PackageOfVerb(VerbExtensionPoint):
    """Get packages of files."""

    def __init__(self):
        """Initialize the extension."""
        super().__init__()
        satisfies_version(VerbExtensionPoint.EXTENSION_POINT_VERSION, "^1.0")

    def add_arguments(self, *, parser):
        """Add arguments for the extension."""
        add_package_discovery_arguments(parser)
        parser.add_argument(
            "--topological-order",
            "-t",
            action="store_true",
            default=False,
            help="Order output based on topological ordering (breadth-first)",
        )
        parser.add_argument(
            "--strict",
            "-s",
            action="store_true",
            default=False,
            help="Operate in strict mode where unmatched files are an error",
        )
        parser.add_argument(
            "--git-diff",
            "-g",
            nargs="?",
            default=None,
            const="HEAD",
            help="Get the list of files from Git diff",
        )
        group = parser.add_mutually_exclusive_group()
        group.add_argument(
            "--names-only",
            "-n",
            action="store_true",
            default=False,
            help="Output only the name of each package but not the path",
        )
        group.add_argument(
            "--paths-only",
            "-p",
            action="store_true",
            default=False,
            help="Output only the path of each package but not the name",
        )
        parser.add_argument(
            "file_paths",
            metavar="FILE-PATHS",
            nargs="*",
            default=[],
            help="File paths to get the packages of",
        )

    def main(self, *, context):
        """Determine matching packages and print the result."""
        args = context.args
        # Make sure the Git revision is not a file (common error)
        args.git_diff = "HEAD" if args.git_diff == "" else args.git_diff
        if args.git_diff and Path(args.git_diff).exists():
            return (
                "The Git revision appears to be a file, which is probably a mistake: "
                f"{args.git_diff}\n(Hint: Try using the '--git-diff=REV' syntax to "
                "specify the revision!)"
            )
        # Discover packages using the known discovery extensions
        extensions = get_package_identification_extensions()
        descriptors = discover_packages(args, extensions)
        # Augmenting packages fills the dependency information, etc, which is
        # necessary for topological sorting
        augment_packages(descriptors)
        # Get topologically sorted package decorators
        decorators = topological_order_packages(
            descriptors, recursive_categories=("run",)
        )
        if not args.topological_order:
            decorators = sorted(decorators, key=lambda d: d.descriptor.name)
        # Get packages and file paths ready
        pkgs = [d.descriptor for d in decorators]
        file_paths = {Path(p) for p in args.file_paths}
        # Find files based on Git
        if args.git_diff:
            git_repos = self._determine_git_repos(args.base_paths, pkgs)
            git_file_paths = self._get_all_git_diff_files(git_repos, args.git_diff)
            if git_file_paths is None:
                return (
                    "Failed to get Git file paths, possibly due to bad revision: "
                    f"{args.git_diff}\n(Hint: Try using the '--git-diff=REV' syntax to "
                    "specify the revision!)"
                )
            file_paths.update(git_file_paths)
        # Resolve the file paths
        file_paths = {Path(p).resolve() for p in file_paths}
        # Match the file paths
        matched_pkgs = self._match_file_paths_to_pkgs(pkgs, file_paths)
        # Check for unmatched file paths
        if args.strict and len(file_paths) != 0:
            return "\n".join(
                f"Unmatched file path: {self._relative_path(p)}" for p in file_paths
            )
        # Format and print the output (same as the list verb)
        self._print_packages(
            matched_pkgs,
            names_only=args.names_only,
            paths_only=args.paths_only,
            sorted_order=not args.topological_order,
        )

    def _determine_git_repos(self, base_paths, pkgs):
        """Check the base paths and all package paths for Git repos.

        Other paths are not checked, and no recursive crawl is performed. In
        this way, this function leverages the built-in package discovery. It is
        not necessary to check directories given by ``--path`` separately
        because those are always individual package paths anyway.

        """
        git_repos = set()
        base_paths = [Path(p).resolve() for p in base_paths]
        pkg_paths = [Path(pkg.path).resolve() for pkg in pkgs]
        for base_path in base_paths:
            if (base_path / ".git").is_dir():
                git_repos.add(base_path)
        for pkg_path in pkg_paths:
            if (pkg_path / ".git").is_dir():
                git_repos.add(pkg_path)
        return git_repos

    def _get_all_git_diff_files(
        self, git_repos, git_rev, /, unstaged=True, untracked=True
    ):
        file_paths = set()
        for git_repo in git_repos:
            git_file_paths = self._get_git_diff_files(
                git_repo, git_rev, unstaged=unstaged, untracked=untracked
            )
            if git_file_paths is None:
                return None
            file_paths.update(git_file_paths)
        return file_paths

    def _get_git_diff_files(self, git_repo, git_rev, /, unstaged=True, untracked=True):
        file_paths = set()
        git_repo = Path(git_repo)
        git_rev = "HEAD" if not git_rev else git_rev
        staged_opt = "--staged" if not unstaged else ""
        untracked = unstaged and untracked
        diff_result = subprocess.run(
            shlex.split(f"git diff --name-only {staged_opt} {git_rev} --"),
            capture_output=True,
            cwd=git_repo,
            check=False,
            text=True,
        )
        if diff_result.returncode != 0:
            return None
        file_paths.update(git_repo / p for p in diff_result.stdout.splitlines())
        if untracked:
            ls_result = subprocess.run(
                shlex.split("git ls-files --others --exclude-standard"),
                capture_output=True,
                cwd=git_repo,
                check=False,
                text=True,
            )
            if ls_result.returncode != 0:
                return None
            file_paths.update(git_repo / p for p in ls_result.stdout.splitlines())
        return file_paths

    def _match_file_paths_to_pkgs(self, pkgs, file_paths, /):
        """Match packages to file paths, preserving order."""
        matched_pkgs = []
        for pkg in pkgs:
            matched_pkg = None
            matched_paths = set()
            pkg_path = Path(pkg.path).resolve()
            for file_path in file_paths:
                if file_path.is_relative_to(pkg_path):
                    matched_pkg = pkg
                    matched_paths.add(file_path)
            if matched_pkg:
                matched_pkgs.append(matched_pkg)
                file_paths.difference_update(matched_paths)
            if len(file_paths) == 0:
                break
        return matched_pkgs

    def _relative_path(self, file_path):
        file_path = Path(file_path)
        try:
            return file_path.relative_to(Path.cwd())
        except ValueError:
            return file_path

    def _print_packages(
        self, pkgs, /, names_only=False, paths_only=False, sorted_order=False
    ):
        """Print a list of packages."""
        lines = []
        for pkg in pkgs:
            if names_only:
                lines.append(pkg.name)
            elif paths_only:
                lines.append(str(pkg.path))
            else:
                lines.append(f"{pkg.name}\t{str(pkg.path)}\t({pkg.type})")
        if not sorted_order:
            lines.sort()
        for line in lines:
            print(line)
