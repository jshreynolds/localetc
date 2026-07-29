"""Containerised runs of this repo's checks.

`ci/run-checks.sh` is the single definition of what a check DOES and
`ci/checks.list` the single registry of which checks EXIST; this module only
decides WHERE they run. Keeping both in the repo is what lets `nix flake check`
(darwin, native) and this module (linux, container) agree by construction
rather than by lists being kept in sync — see flake.nix, which reads the very
same manifest.

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
import json
from typing import Annotated

import dagger
from dagger import Doc, Ignore, dag, function, object_type

NIX_IMAGE = "nixos/nix:2.31.2"

MANIFEST = "ci/checks.list"

# Tools the CONTAINER needs that no check declares, because they are ambient
# everywhere else.
#
# gnused: nixos/nix ships grep, find, sort and coreutils but NOT sed, which
# run-checks.sh needs to derive test directories. Without it the python check
# discovered zero test suites and still reported OK — the script now refuses to
# pass on an empty discovery, but the tool still has to be here.
#
# bash and git are deliberately absent: nixos/nix already ships
# bash-interactive and git-minimal, and installing a second copy makes
# `nix profile install` abort on a file conflict (/lib/bash/ln,
# libexec/git-core/git-remote-http). git-minimal has `ls-files`, which is all
# run-checks.sh asks of it.
EXTRA_TOOLS = ("gnused",)

Source = Annotated[
    dagger.Directory,
    Doc(
        "The repository. Keep .git — run-checks.sh scopes itself with "
        "`git ls-files`, which is what keeps vendored trees out, and the "
        "discovery check compares that against its .git-less fallback."
    ),
    # Excluded from the upload only. .venv is already gitignored, so
    # git ls-files would drop it anyway; this just avoids shipping ~976
    # dependency files to the engine on every run.
    Ignore(["**/.venv", "**/node_modules", "**/__pycache__", "result"]),
]


def _parse_manifest(text: str) -> dict[str, list[str]]:
    """ci/checks.list -> {check name: nixpkgs attrs it needs}.

    Same grammar the shell and nix parsers implement: comments, blank lines,
    then `<name> <attr>...`.
    """
    registry = {}
    for line in text.splitlines():
        fields = line.split()
        if not fields or fields[0].startswith("#"):
            continue
        registry[fields[0]] = fields[1:]
    return registry


@object_type
class Checks:
    async def _registry(self, source: Source) -> dict[str, list[str]]:
        return _parse_manifest(await source.file(MANIFEST).contents())

    async def _nixpkgs(self, source: Source) -> str:
        """The flake ref for tools, taken from the repo's own flake.lock.

        Deliberately NOT a second pin maintained by hand. The container and the
        machine then lint with identical tool versions, so `nix flake check`
        and this module cannot reach different verdicts over a nixfmt or
        shellcheck release. The cost is that `nix flake update` moves CI's
        tools too — which is the point of running CI on the update.
        """
        lock = json.loads(await source.file("flake.lock").contents())
        node = lock["nodes"][lock["nodes"]["root"]["inputs"]["nixpkgs"]]
        locked = node["locked"]
        return f"github:{locked['owner']}/{locked['repo']}/{locked['rev']}"

    @function
    async def base(self, source: Source) -> dagger.Container:
        """Container with every check's tools on PATH and the repo at /src.

        One image for all checks rather than one per check: the tool sets
        overlap heavily, and a single `nix profile install` layer is cached
        once and shared by the whole fan-out.
        """
        registry = await self._registry(source)
        tools = sorted(
            {tool for tools in registry.values() for tool in tools}.union(EXTRA_TOOLS)
        )
        nixpkgs = await self._nixpkgs(source)

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
                ["nix", "profile", "install", *(f"{nixpkgs}#{tool}" for tool in tools)]
            )
            .with_mounted_directory("/src", source)
            .with_workdir("/src")
        )

    @function
    async def run(
        self,
        source: Source,
        name: Annotated[
            str, Doc("A check name from ci/checks.list, or 'all'")
        ] = "all",
    ) -> str:
        """Run one check."""
        registry = await self._registry(source)
        if name != "all" and name not in registry:
            raise ValueError(
                f"unknown check {name!r}; {MANIFEST} has: {', '.join(registry)}"
            )
        ctr = await self.base(source)
        return await ctr.with_exec(["bash", "ci/run-checks.sh", name]).stdout()

    async def _outcome(self, source: Source, name: str) -> tuple[bool, str]:
        """(passed, output) for one check. Never raises on a check FAILURE.

        This is what makes the fan-out honest: a bare `asyncio.gather` used to
        propagate the first ExecError and discard every sibling's result, so a
        run reported exactly one failure no matter how many there were. An
        exception that is NOT a failing check (engine trouble, a bad manifest)
        still propagates — that is infrastructure, not a verdict.
        """
        try:
            return True, await self.run(source, name)
        except dagger.ExecError as err:
            # The useful text is on the exception, not the return value.
            return False, "\n".join(filter(None, [err.stdout, err.stderr])).strip()

    @function
    async def all(self, source: Source) -> str:
        """Run every check in the manifest, in parallel, each in its container.

        Parallel rather than `run-checks.sh all` for wall-clock: the base layer
        is shared and cached, so the checks overlap instead of queueing.
        """
        names = list(await self._registry(source))
        outcomes = await asyncio.gather(*(self._outcome(source, n) for n in names))

        report = "\n".join(
            f"===== {name}: {'ok' if passed else 'FAILED'} =====\n{output}"
            for name, (passed, output) in zip(names, outcomes)
        )
        failed = [name for name, (passed, _) in zip(names, outcomes) if not passed]
        if failed:
            raise RuntimeError(f"{report}\n\nFAILED: {' '.join(failed)}")
        return report
