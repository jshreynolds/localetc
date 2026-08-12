# =============================================================================
# default.nix — entry point of the home-manager configuration.
#
# Nix concept: importing a directory loads its default.nix. flake.nix points
# home-manager at this folder — from BOTH the nix-darwin and the NixOS
# builder — and `imports` below pulls in the sibling files, each of which
# handles one concern.
#
# Everything in this directory is platform-neutral; the platform-specific
# extras live in ./darwin or ./linux and exactly one of them is imported.
# If a module here fails to evaluate on linux, that is the bug the linux
# systems in flake.nix exist to surface.
#
# `username`, `home`, `repo`, `isDarwin` and `work` arrive via extraSpecialArgs
# — written once, in hosts/<hostname>/default.nix.
# =============================================================================
{
  username,
  home,
  isDarwin,
  ...
}:
{
  imports = [
    ./packages.nix # every cross-platform CLI tool and language runtime
    ./shell.nix # zsh: aliases, environment variables, PATH
    ./git.nix # git and jujutsu
    ./programs.nix # tools where home-manager wires config + shell integration
    ./dotfiles.nix # config files: nix-managed vs live-editable symlinks
    ./agents.nix # agent skills + subagent specs: ~/.agents/skills (mirrored to claude/codex), ~/.claude/agents
    ./rnnoise-models.nix # pinned .rnnn models for ffmpeg's arnndn filter
    ./protonmail-bridge.nix # headless IMAP/SMTP gateway for Proton Mail
    ./proton-drive.nix # pinned Proton Drive CLI (not in nixpkgs)
    ./storage-box.nix # rclone bisync of ~/sbox with the Hetzner Storage Box

    # Exactly one of these — the platform's own packages, paths and aliases.
    (if isDarwin then ./darwin else ./linux)
  ];

  home.username = username;
  home.homeDirectory = home;

  # Compatibility marker recording which home-manager release first managed
  # this home. Set once, then NEVER changed — it is not a version selector.
  home.stateVersion = "25.05";
}
