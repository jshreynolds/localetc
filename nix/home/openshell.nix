# =============================================================================
# openshell.nix — NVIDIA OpenShell, pinned to a release instead of curl|sh.
#
# Upstream ships a `curl -LsSf .../install.sh | sh` installer. On Apple Silicon
# that installer just fabricates a local Homebrew tap, drops the release's
# `openshell.rb` formula into it, and `brew install`s the SAME static tarballs
# fetched below — plus it starts a `brew services` gateway. None of that is
# reproducible. So we skip the installer entirely and package the release
# artifacts directly, the same way rnnoise-models.nix pins its data: exact URL
# + hash, frozen in the store, rolled back with every generation.
#
# What we install (three prebuilt aarch64-darwin binaries from one release):
#   openshell            — the agent CLI
#   openshell-gateway    — local gateway daemon (127.0.0.1:17670)
#   openshell-driver-vm  — backs sandboxed command execution
#
# Deliberately NOT managed here (kept manual, per how it's actually used):
#   - the gateway is NOT a launchd service; start `openshell-gateway` by hand.
#   - one-time, first run only:  openshell gateway add https://127.0.0.1:17670
#     (writes ~/.config/openshell, a real tool-owned dir — never this repo).
#
# The darwin binaries are adhoc/linker-signed with NO entitlements and link
# neither Virtualization nor Hypervisor framework — i.e. byte-identical to what
# the Homebrew formula would place, so nix packaging doesn't degrade sandboxing.
# The one catch: nix strips Mach-O by default, which invalidates that adhoc
# signature and macOS then kills the binary at launch — hence `dontStrip`. We
# mutate nothing else, so the original signature stays valid.
#
# Bumping: change `version` and the three hashes, then `drs`. Hashes come from
# the release's *-checksums-sha256.txt (hex; nix wants SRI), or just:
#   nix store prefetch-file <url>
# =============================================================================
{ pkgs, lib, ... }:
let
  version = "0.0.92";
  base = "https://github.com/NVIDIA/OpenShell/releases/download/v${version}";

  fetchBin =
    { name, hash }:
    pkgs.fetchurl {
      url = "${base}/${name}-aarch64-apple-darwin.tar.gz";
      inherit hash;
    };

  cli = fetchBin {
    name = "openshell";
    hash = "sha256-ww4e/9QJTSYadSB0WgnLEmaBXCMajXvBVU7VrGB6f/g=";
  };
  gateway = fetchBin {
    name = "openshell-gateway";
    hash = "sha256-4IN8FaJ1smgQguBfjpmf+eqxVcxXVGn0ELy94lnuw8I=";
  };
  driverVm = fetchBin {
    name = "openshell-driver-vm";
    hash = "sha256-TvCaN8J058Ijk1bXbP8BOLNEkf2RHzxgnjP8ux8HUyc=";
  };

  openshell = pkgs.stdenvNoCC.mkDerivation {
    pname = "openshell";
    inherit version;

    # Each tarball is a single top-level binary; unpack them straight to bin.
    dontUnpack = true;
    dontStrip = true; # preserve the adhoc Mach-O signature (see header)

    installPhase = ''
      runHook preInstall
      mkdir -p "$out/bin"
      tar -xzf ${cli} -C "$out/bin"
      tar -xzf ${gateway} -C "$out/bin"
      tar -xzf ${driverVm} -C "$out/bin"
      chmod +x "$out/bin/openshell" "$out/bin/openshell-gateway" "$out/bin/openshell-driver-vm"
      runHook postInstall
    '';

    meta = {
      description = "NVIDIA OpenShell — agentic shell with sandboxed execution";
      homepage = "https://github.com/NVIDIA/OpenShell";
      license = lib.licenses.asl20;
      platforms = [ "aarch64-darwin" ];
      mainProgram = "openshell";
    };
  };
in
{
  home.packages = [ openshell ];
}
