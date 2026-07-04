# =============================================================================
# default.nix — entry point of the home-manager configuration.
#
# Nix concept: importing a directory loads its default.nix. flake.nix points
# home-manager at this folder; `imports` below pulls in the sibling files,
# each of which handles one concern.
# =============================================================================
{ ... }:
{
  imports = [
    ./packages.nix # every CLI tool and language runtime
    ./shell.nix    # zsh: aliases, environment variables, PATH
    ./git.nix      # git and jujutsu
    ./programs.nix # tools where home-manager wires config + shell integration
    ./dotfiles.nix # config files: nix-managed vs live-editable symlinks
  ];

  home.username = "josrey";
  home.homeDirectory = "/Users/josrey";

  # Compatibility marker recording which home-manager release first managed
  # this home. Set once, then NEVER changed — it is not a version selector.
  home.stateVersion = "25.05";
}
