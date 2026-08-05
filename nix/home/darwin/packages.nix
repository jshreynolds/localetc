# =============================================================================
# darwin/packages.nix — CLI tools that only exist, or only make sense, on macOS.
#
# The cross-platform list is nix/home/packages.nix; this is strictly the extra
# macOS layer. A tool belongs here if it fails to build on linux (apple dev
# tooling) or is a macOS-specific answer to a problem the other platform solves
# differently (colima vs virtualisation.docker.enable).
# =============================================================================
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # -- apple dev -------------------------------------------------------------
    xcbeautify
    xcodegen

    # -- containers ------------------------------------------------------------
    colima # the docker ENGINE on macOS (docker context points here).
    # NixOS uses virtualisation.docker.enable instead; the docker CLI itself is
    # cross-platform and lives in the shared packages.nix.

    # ~/.docker/config.json sets credsStore=osxkeychain, and docker-client does
    # not ship the helper. It used to arrive undeclared via Rancher Desktop's
    # ~/.rd/bin; without it every registry pull fails to resolve credentials.
    docker-credential-helpers
  ];
}
