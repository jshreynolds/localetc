{
  # ===========================================================================
  # flake.nix — the front door of this machine's configuration.
  #
  # A *flake* is nix's way of saying: "here are my dependencies (inputs) and
  # here is what I produce (outputs)", with every dependency pinned to an
  # exact commit in flake.lock. Same lock file = same system, every time.
  #
  # Daily driver commands:
  #   sudo darwin-rebuild switch --flake ~/etc     # apply config changes (alias: drs)
  #   nix flake update                             # update all pinned inputs, then drs
  #   darwin-rebuild --list-generations            # see history; every switch is undoable
  # ===========================================================================

  description = "josrey's mac: nix-darwin + home-manager";

  inputs = {
    # The nix package collection. "nixpkgs-unstable" is the rolling branch —
    # the standard choice on macOS (fresher CLI tools, first-class darwin care).
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    # nix-darwin manages macOS itself: system settings, homebrew, launchd.
    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    # "follows" means: use OUR nixpkgs above, not nix-darwin's own copy,
    # so the whole system is built from one package set.
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    # home-manager manages the user environment: packages, dotfiles, zsh.
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, nix-darwin, home-manager }: {
    # `darwin-rebuild switch --flake ~/etc` looks up the attribute named after
    # this machine's hostname — so this MUST stay equal to `scutil --get LocalHostName`.
    darwinConfigurations."mac-nl-josrey-2" = nix-darwin.lib.darwinSystem {
      system = "aarch64-darwin";

      # Each module is a file handling exactly one concern. Start reading at
      # nix/darwin/core.nix.
      modules = [
        ./nix/darwin/core.nix
        ./nix/darwin/homebrew.nix
        ./nix/darwin/macos-defaults.nix

        # home-manager runs as a nix-darwin module so ONE `darwin-rebuild switch`
        # updates system config AND user config together.
        home-manager.darwinModules.home-manager
        {
          home-manager.useGlobalPkgs = true;    # reuse the system nixpkgs (incl. allowUnfree)
          home-manager.useUserPackages = true;  # install user pkgs to /etc/profiles/per-user/josrey
          home-manager.users.josrey = import ./nix/home;
          # If a real file already sits where home-manager wants to place a
          # symlink, rename it to *.hm-backup instead of aborting activation.
          home-manager.backupFileExtension = "hm-backup";
        }
      ];
    };
  };
}
