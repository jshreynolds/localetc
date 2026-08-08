# =============================================================================
# core.nix — the system options that are IDENTICAL on macOS and NixOS.
#
# nix-darwin and NixOS are separate module systems, but they deliberately share
# a lot of option NAMES. Where both spell an option the same way and this repo
# wants the same value on every machine, it is written here — once — instead of
# in nix/darwin/core.nix and nix/nixos/core.nix side by side.
#
# Both builders import this file first; see mkDarwinHost / mkNixosHost in
# flake.nix. The platform cores then add what only their platform has.
#
# WHAT DOES NOT BELONG HERE: anything one platform spells differently, or means
# differently. Two things look tempting and are not shareable:
#
#   system.stateVersion   an int on nix-darwin (its internal state format) and
#                         a release string on NixOS. Same name, different
#                         option, different value — it stays in both cores.
#   nix.*                 opposite intent by design: Determinate Nix owns nix on
#                         the macs (nix.enable = false), while on NixOS nix is
#                         just another service this repo configures.
#
# `username`, `hostname` and `home` arrive via specialArgs — written exactly
# once, in hosts/<hostname>/default.nix.
# =============================================================================
{
  pkgs,
  username,
  hostname,
  home,
  ...
}:
{
  # Machine name. macOS has two more names for the same machine (computerName,
  # localHostName) — nix/darwin/core.nix sets those.
  networking.hostName = hostname;

  # Where this user's home is. The rest of the account differs per platform:
  # NixOS declares a full user (groups, login shell), macOS only needs the path.
  users.users.${username}.home = home;

  # Generates /etc/zshrc so every zsh (login, ssh, scripts) gets nix paths and
  # completions wired in before the user's own ~/.zshrc runs. Both platforms
  # implement this option; home-manager's programs.zsh layers on top of it.
  programs.zsh.enable = true;

  # The two nerd fonts, so terminal glyphs match on every machine. macOS
  # installs them into /Library/Fonts/Nix Fonts, NixOS into the font path.
  fonts.packages = with pkgs; [
    nerd-fonts.fira-code
    nerd-fonts._3270
  ];

  # Some packages have non-open-source licenses (terraform is BUSL, for one).
  # nixpkgs refuses to build them unless you opt in. home-manager inherits this
  # because flake.nix sets useGlobalPkgs.
  nixpkgs.config.allowUnfree = true;
}
