# =============================================================================
# linux/default.nix — the NixOS-only half of the home configuration.
#
# Imported by nix/home/default.nix when isDarwin is false; nix/home/darwin is
# imported instead otherwise.
#
# Deliberately small. Almost everything the Mac has is already cross-platform
# and lives in nix/home/*.nix; what remains here is the handful of things whose
# macOS equivalent named a Mac-only path or command. It stays ONE file until
# there is enough to split (the darwin side started this way too).
#
# The desktop itself now exists: nix/nixos/desktop.nix draws a GNOME/Wayland
# session, and the GUI apps live in nix/nixos/apps.nix. The clipboard split is
# handled cross-platform in nix/home/clipboard.nix (term_copy/term_paste).
# =============================================================================
{ repo, ... }:
{
  imports = [
    ./packages.nix # linux-only tools (wl-clipboard)
  ];

  programs.zsh.shellAliases = {
    # The counterpart to `drs` on the macs. Deliberately a different name —
    # `drs` means darwin-rebuild, and an alias that lies about which tool it
    # runs is worse than two names to remember.
    nrs = "sudo nixos-rebuild switch --flake ${repo}";
  };
}
