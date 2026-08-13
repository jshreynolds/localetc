# =============================================================================
# clipboard.nix — term_copy / term_paste: one clipboard name on every platform.
#
# macOS has pbcopy/pbpaste; the NixOS box runs GNOME on Wayland, so it needs
# wl-copy/wl-paste. Rather than teach every caller that difference, both sides
# get wrapped under one pair of names.
#
# These are SCRIPTS, not shell aliases. dotfiles/config/zellij/config.kdl sets
# `copy_command "term_copy"`, and zellij execs that directly — it never runs an
# interactive zsh, so an alias would be invisible to it. A script on PATH works
# for both zellij and the shell, which keeps that config.kdl line platform-free
# and shared with the macs.
# =============================================================================
{ pkgs, isDarwin, ... }:
let
  copy = if isDarwin then "pbcopy" else "${pkgs.wl-clipboard}/bin/wl-copy";

  # -n: wl-paste appends a trailing newline, pbpaste does not.
  paste = if isDarwin then "pbpaste" else "${pkgs.wl-clipboard}/bin/wl-paste -n";
in
{
  # "$@" passes flags through, so platform-only options (wl-copy -p, for the
  # primary selection) still reach the real tool and fail loudly on the other
  # platform rather than being silently dropped.
  home.packages = [
    (pkgs.writeShellScriptBin "term_copy" ''exec ${copy} "$@"'')
    (pkgs.writeShellScriptBin "term_paste" ''exec ${paste} "$@"'')
  ];
}
