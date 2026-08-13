# =============================================================================
# linux/packages.nix — CLI tools that only exist, or only make sense, on NixOS.
#
# The cross-platform list is nix/home-manager/packages.nix; this is strictly the extra
# linux layer. A tool belongs here if it fails to build on darwin or is the
# linux-specific answer to a problem macOS solves differently.
# =============================================================================
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # -- wayland ---------------------------------------------------------------
    # wl-copy/wl-paste. clipboard.nix already references these by store path for
    # term_copy/term_paste; listed here so they are also on PATH by their own
    # names (macOS's pbcopy/pbpaste come with the OS, so there is no counterpart
    # line in darwin/packages.nix).
    wl-clipboard
  ];
}
