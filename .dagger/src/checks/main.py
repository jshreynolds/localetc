"""Containerised runs of this repo's checks.

`ci/run-checks.sh` is the single definition of what a check IS; this module
only decides WHERE one runs. Keeping the logic in the script is what lets
`nix flake check` (darwin, native) and this module (linux, container) agree by
construction rather than by two lists being kept in sync — see flake.nix.

SCOPE LIMIT, on purpose: these run in a linux container, so they cover the
shell scripts, python tests, nix formatting and skill metadata. They cannot
build `darwinConfigurations` — that needs macOS plus nix-darwin, i.e. a macOS
runner. A green run here means "the code in this repo is sound", NOT "this
config switches cleanly on a mac".

Usage:
    dagger call all --source=.              # every check, in parallel
    dagger call run --source=. --name=shell # just one
"""

import asyncio
from typing import Annotated

import dagger
from dagger import Doc, Ignore, dag, function, object_type

NIX_IMAGE = "nixos/nix:2.31.2"

# Pinned so a CI run is reproducible. Deliberately NOT wired to the repo's own
# flake.lock: the container only needs lint/test tools, so tying the two would
# mean a routine `nix flake update` could break CI on an unrelated day. Bump
# this by hand when the tools need to move.
NIXPKGS = "github:NixOS/nixpkgs/38a4887411571457d700c51c64a6e49ead2ed5ab"

# Attribute names match nix/home/packages.nix and flake.nix's check inputs, so
# the container runs the same tools the machine does.
#
# gnused is not optional: nixos/nix ships grep, find, sort and coreutils but
# NOT sed, and run-checks.sh needs it to derive test directories. Without it
# the python check discovered zero test suites and still reported OK — the
# script now refuses to pass on an empty discovery, but the tool still has to
# be here.
#
# bash and git are deliberately absent: nixos/nix already ships
# bash-interactive and git-minimal, and installing a second copy makes
# `nix profile install` abort on a file conflict (/lib/bash/ln,
# libexec/git-core/git-remote-http). git-minimal has `ls-files`, which is all
# run-checks.sh asks of it.
TOOLS = ("nixfmt", "shellcheck", "python314", "gnused")

# Mirrors the `case` in ci/run-checks.sh. Kept here only to fan out in
# parallel; the script remains the authority on what each one does.
SUBCOMMANDS = ("nixfmt", "shell", "python", "skills")

Source = Annotated[
    dagger.Directory,
    Doc(
        "The repository. Keep .git — run-checks.sh scopes itself with "
        "`git ls-files`, which is what keeps vendored trees out."
    ),
    # Excluded from the upload only. .venv is already gitignored, so
    # git ls-files would drop it anyway; this just avoids shipping ~976
    # dependency files to the engine on every run.
    Ignore(["**/.venv", "**/node_modules", "**/__pycache__", "result"]),
]


@object_type
class Checks:
    @function
    def base(self, source: Source) -> dagger.Container:
        """Container with the check tools on PATH and the repo mounted at /src.

        The `nix profile install` step is layer-cached by dagger, so it only
        pays its cost when TOOLS or NIXPKGS change.
        """
        return (
            dag.container()
            .from_(NIX_IMAGE)
            .with_env_variable(
                "NIX_CONFIG",
                # flakes: needed for the pinned `github:` refs below.
                # filter-syscalls: nix's seccomp filter fights the container's
                # own sandbox on some runners; off is the documented fix.
                "experimental-features = nix-command flakes\nfilter-syscalls = false",
            )
            .with_exec(
                ["nix", "profile", "install", *(f"{NIXPKGS}#{tool}" for tool in TOOLS)]
            )
            .with_mounted_directory("/src", source)
            .with_workdir("/src")
        )

    @function
    async def run(
        self,
        source: Source,
        name: Annotated[
            str, Doc("Subcommand: nixfmt, shell, python, skills, or all")
        ] = "all",
    ) -> str:
        """Run one check subcommand."""
        return await (
            self.base(source).with_exec(["bash", "ci/run-checks.sh", name]).stdout()
        )

    @function
    async def all(self, source: Source) -> str:
        """Run every check in parallel, each in its own container.

        Parallel rather than `run-checks.sh all` so a failure names itself and
        one broken check doesn't mask the others.
        """
        results = await asyncio.gather(
            *(self.run(source, name) for name in SUBCOMMANDS)
        )
        return "\n".join(
            f"===== {name} =====\n{output}"
            for name, output in zip(SUBCOMMANDS, results)
        )
