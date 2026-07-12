{
  # ===========================================================================
  # flake.nix — entrypoint of this machine's configuration.
  #
  # A *flake* is nix's way of saying: "here are my dependencies (inputs) and
  # here is what I produce (outputs)", with every dependency pinned to an
  # exact commit in flake.lock. Same lock file = same system, every time.
  #
  # This repo is assumed to live at ~/etc on every machine (the live dotfile
  # symlinks and the drs alias depend on that).
  #
  # Daily driver commands:
  #   sudo darwin-rebuild switch --flake ~/etc     # apply config changes (alias: drs)
  #   nix flake update                             # update all pinned inputs, then drs
  #   darwin-rebuild --list-generations            # see history; every switch is undoable
  # ===========================================================================

  description = "declarative macOS: nix-darwin + home-manager";

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

  outputs =
    {
      self,
      nixpkgs,
      nix-darwin,
      home-manager,
    }:
    let
      lib = nixpkgs.lib;
      pkgs = nixpkgs.legacyPackages.aarch64-darwin;

      shellScripts = [
        "ai/skill-add"
        "ai/skill-sync"
        "bin/hf-download"
        "bin/kubeshell"
        "bin/leet"
        "bin/rando.sh"
        "bin/show_color"
      ];

      pythonScripts = [
        "ai/skills/biweekly-chatlayer-briefing/scripts/fetch_content.py"
        "ai/skills/start-of-day/scripts/sod.py"
        "ai/skills/start-of-day/scripts/test_sod.py"
        "ai/skills/start-of-day/scripts/urls.py"
        "ai/skills/vault-doctor/scripts/vault_doctor.py"
        "ai/skills/vault-doctor/scripts/test_vault_doctor.py"
        "bin/git_set_local_conf"
        "bin/rename_spaces.py"
      ];

      # ---- one machine = one mkHost call -----------------------------------
      # `hostname` must equal `scutil --get LocalHostName` on that machine.
      # `username` must equal the macOS account short name (`whoami`).
      # `casks`/`brews`/`masApps` are OPTIONAL host-specific apps, merged onto
      # the shared lists in nix/darwin/homebrew.nix.
      # Everything else (home directory, module wiring) is derived from these
      # facts and passed to every module via specialArgs — no other file
      # hardcodes who or where you are.
      mkHost =
        {
          hostname,
          username,
          casks ? [ ],
          brews ? [ ],
          masApps ? { },
        }:
        let
          home = "/Users/${username}";
        in
        nix-darwin.lib.darwinSystem {
          system = "aarch64-darwin";

          # specialArgs makes these available as arguments in every darwin
          # module: `{ username, hostname, home, hostCasks, ... }:`
          specialArgs = {
            inherit username hostname home;
            hostCasks = casks;
            hostBrews = brews;
            hostMasApps = masApps;
          };

          # Each module is a file handling exactly one concern. Start reading
          # at nix/darwin/core.nix.
          modules = [
            ./nix/darwin/core.nix
            ./nix/darwin/homebrew.nix
            ./nix/darwin/macos-defaults.nix

            # home-manager runs as a nix-darwin module so ONE `darwin-rebuild
            # switch` updates system config AND user config together.
            home-manager.darwinModules.home-manager
            {
              home-manager.useGlobalPkgs = true; # reuse the system nixpkgs (incl. allowUnfree)
              home-manager.useUserPackages = true; # install user pkgs to /etc/profiles/per-user/<username>
              home-manager.users.${username} = import ./nix/home;
              # same idea as specialArgs, but for the home modules
              home-manager.extraSpecialArgs = { inherit username home; };
              # If a real file already sits where home-manager wants to place a
              # symlink, rename it to *.hm-backup instead of aborting activation.
              home-manager.backupFileExtension = "hm-backup";
            }
          ];
        };
    in
    {
      # `nix fmt` formats every .nix file in the repo with the official style.
      formatter.aarch64-darwin = pkgs.nixfmt-tree;

      checks.aarch64-darwin = {
        nix-format =
          pkgs.runCommand "localetc-nix-format-check"
            {
              nativeBuildInputs = [ pkgs.nixfmt ];
            }
            ''
              cd ${self}
              find . -name '*.nix' -print0 | xargs -0 nixfmt --check
              touch $out
            '';

        shell-scripts =
          pkgs.runCommand "localetc-shellcheck"
            {
              nativeBuildInputs = [ pkgs.shellcheck ];
            }
            ''
              shellcheck ${lib.concatMapStringsSep " " (path: "${self}/${path}") shellScripts}
              touch $out
            '';

        python-scripts =
          pkgs.runCommand "localetc-python-checks"
            {
              nativeBuildInputs = [ pkgs.python314 ];
            }
            ''
              cd ${self}
              export PYTHONPYCACHEPREFIX="$TMPDIR/pycache"
              python3 -m py_compile ${lib.concatStringsSep " " pythonScripts}
              python3 -m unittest discover -s ai/skills/start-of-day/scripts
              python3 -m unittest discover -s ai/skills/vault-doctor/scripts
              touch $out
            '';

        skill-metadata =
          pkgs.runCommand "localetc-skill-metadata-check"
            {
              nativeBuildInputs = [ pkgs.python314 ];
            }
            ''
              cd ${self}
              python3 - <<'PY'
              from pathlib import Path
              import sys

              failures = []
              for path in sorted(Path("ai/skills").glob("*/SKILL.md")):
                  text = path.read_text(encoding="utf-8")
                  if not text.startswith("---\n"):
                      failures.append(f"{path}: missing frontmatter")
                      continue
                  end = text.find("\n---", 4)
                  if end == -1:
                      failures.append(f"{path}: unclosed frontmatter")
                      continue
                  frontmatter = text[4:end]
                  for key in ("name:", "description:"):
                      if key not in frontmatter:
                          failures.append(f"{path}: missing {key}")

              if failures:
                  print("\n".join(failures), file=sys.stderr)
                  raise SystemExit(1)
              PY
              touch $out
            '';
      };

      # `darwin-rebuild switch --flake ~/etc` picks the attribute matching the
      # machine's hostname — so each machine needs its own line here.
      darwinConfigurations = {
        # work machine
        "mac-nl-josrey" = mkHost {
          hostname = "mac-nl-josrey";
          username = "josrey";
          casks = [
            # apps only THIS machine gets (shared list: nix/darwin/homebrew.nix)
          ];
        };

         # work machine
        "mac-nl-josrey-2" = mkHost {
          hostname = "mac-nl-josrey-2";
          username = "josrey";
          casks = [
            # apps only THIS machine gets (shared list: nix/darwin/homebrew.nix)
          ];
        };

        # personal machine
        "playbook" = mkHost {
          hostname = "playbook";
          username = "jreynolds";
          casks = [
            "lulu"
            "scrivener"
            "thinkorswim"
          ];
        };
      };
    };
}
