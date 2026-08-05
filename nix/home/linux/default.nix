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
# NOT here on purpose, pending an actual desktop on the machine:
#   - clipboard: dotfiles/config/zellij/config.kdl hardcodes `pbcopy`. Fix it
#     when a display server exists (wl-copy on wayland, xclip on X11).
#   - GUI apps: the macs get them from homebrew casks (nix/darwin/homebrew.nix);
#     the NixOS equivalents belong in a desktop module that does not exist yet.
# =============================================================================
{ ... }:
{
  programs.zsh.shellAliases = {
    # The counterpart to `drs` on the macs. Deliberately a different name —
    # `drs` means darwin-rebuild, and an alias that lies about which tool it
    # runs is worse than two names to remember.
    nrs = "sudo nixos-rebuild switch --flake ~/etc";
  };
}
