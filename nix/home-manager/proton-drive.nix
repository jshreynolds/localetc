# =============================================================================
# proton-drive.nix — the official Proton Drive CLI, pinned to a release.
#
# Not in nixpkgs: Proton ships prebuilt per-platform binaries (their TypeScript
# SDK compiled with bun), so this pins URL + hash directly, the same way
# openshell.nix and rnnoise-models.nix do.
#
# There is no Proton Drive *desktop* app for Linux — this CLI is the only
# native client, and it has no background sync engine.
#
# Bumping: new version + hashes from
# https://proton.me/download/drive/cli/index.html (published as SHA-512 hex;
# `nix hash convert --hash-algo sha512 --to sri <hex>` gives the SRI form).
# =============================================================================
{
  pkgs,
  lib,
  isDarwin,
  ...
}:
let
  version = "0.7.0";

  # nix system -> upstream target directory, and that binary's hash
  builds = {
    aarch64-darwin = {
      target = "darwin-arm64";
      hash = "sha512-e1/0/1nn0WSmKYpiObjS97H/seupTlPek6Y367EMYtEAYywo6sFE5yJ1XChFT+kze5zD9dCcmW4X7tmgeZLS7Q==";
    };
    aarch64-linux = {
      target = "linux-arm64";
      hash = "sha512-c8aAFxcbV/ThEmsUd90Smo2OcYn+QjhxRfzLSAijrB2jIO8Q2DdUNkcG3oDsxwDdjgQyHw1gwgLiDVRvkwTvww==";
    };
    x86_64-linux = {
      target = "linux-x64";
      hash = "sha512-Wlr/y+wE6pJqMtEOI2wTQiJ/G21BbLeX+I+UOyxPHc9TtYl6EV8cGqnOjOkv1jfhxQvSI7BIZld2gfBYTszbxg==";
    };
  };

  inherit (pkgs.stdenv.hostPlatform) system;
  build = builds.${system} or (throw "proton-drive: no upstream build for ${system}");

  proton-drive = pkgs.stdenv.mkDerivation {
    pname = "proton-drive";
    inherit version;

    src = pkgs.fetchurl {
      url = "https://proton.me/download/drive/cli/${version}/${build.target}/proton-drive";
      inherit (build) hash;
    };

    dontUnpack = true;
    dontStrip = true; # bun keeps its payload past the last ELF section

    # Linux binaries are ordinary dynamic glibc executables; darwin needs no
    # patching. Do NOT add anything to the runpath — a longer RUNPATH makes
    # patchelf produce an ELF that segfaults the dynamic loader at startup.
    nativeBuildInputs = lib.optional (!isDarwin) pkgs.autoPatchelfHook;
    buildInputs = lib.optional (!isDarwin) pkgs.stdenv.cc.cc.lib;

    installPhase = ''
      runHook preInstall
      install -Dm755 $src $out/bin/proton-drive
      runHook postInstall
    '';

    meta = {
      description = "Official Proton Drive command-line client";
      homepage = "https://github.com/ProtonDriveApps/sdk";
      license = lib.licenses.mit;
      platforms = builtins.attrNames builds;
      mainProgram = "proton-drive";
    };
  };
in
{
  home.packages = [ proton-drive ] ++ lib.optional (!isDarwin) pkgs.pass;

  # The CLI defaults to bun's keychain API, which dlopens libsecret and cannot
  # find it on NixOS. `pass` is the supported alternative; macOS keeps the
  # default, where bun uses the system Keychain.
  # One-time, per Linux host:  pass init <your-gpg-key-id>
  home.sessionVariables = lib.mkIf (!isDarwin) {
    PROTON_DRIVE_CREDENTIALS_STORE = "pass";
  };
}
