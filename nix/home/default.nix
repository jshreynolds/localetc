# =============================================================================
# default.nix — entry point of the home-manager configuration.
#
# Nix concept: importing a directory loads its default.nix. flake.nix points
# home-manager at this folder; `imports` below pulls in the sibling files,
# each of which handles one concern.
#
# `username` and `home` arrive via extraSpecialArgs — defined once, in
# the mkHost call in flake.nix.
# =============================================================================
{ username, home, ... }:
{
  imports = [
    ./packages.nix # every CLI tool and language runtime
    ./shell.nix # zsh: aliases, environment variables, PATH
    ./git.nix # git and jujutsu
    ./programs.nix # tools where home-manager wires config + shell integration
    ./dotfiles.nix # config files: nix-managed vs live-editable symlinks
    ./skills.nix # agent skills: ~/.agents/skills, mirrored to claude/codex
    ./rnnoise-models.nix # pinned .rnnn models for ffmpeg's arnndn filter
    ./openshell.nix # NVIDIA OpenShell, pinned to a release (skips curl|sh installer)
  ];

  home.username = username;
  home.homeDirectory = home;

  # Compatibility marker recording which home-manager release first managed
  # this home. Set once, then NEVER changed — it is not a version selector.
  home.stateVersion = "25.05";
}
