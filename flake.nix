{
  # ===========================================================================
  # flake.nix — entrypoint of every machine's configuration.
  #
  # A *flake* is nix's way of saying: "here are my dependencies (inputs) and
  # here is what I produce (outputs)", with every dependency pinned to an
  # exact commit in flake.lock. Same lock file = same system, every time.
  #
  # TWO PLATFORMS, ONE HOME. macOS machines are built by nix-darwin
  # (`darwinConfigurations`) and Linux machines by NixOS (`nixosConfigurations`),
  # but BOTH mount the same home-manager config from nix/home — so the shell,
  # tools, dotfiles and agent skills are identical everywhere. The only
  # per-platform code lives in nix/darwin, nix/nixos, nix/home/darwin and
  # nix/home/linux. See mkDarwinHost / mkNixosHost below.
  #
  # ONE MACHINE = ONE FOLDER. Every per-machine fact lives in
  # hosts/<hostname>/default.nix — username, work-or-not, its own casks/apps,
  # and any nix that belongs to that machine alone. This file holds only the
  # two mkHost functions and the roster at the bottom. Where the repo is checked
  # out is such a fact too (`repo`, default ~/etc); change it there, nowhere
  # else.
  #
  # Daily driver commands:
  #   macOS  sudo darwin-rebuild switch --flake ~/etc   # alias: drs
  #   NixOS  sudo nixos-rebuild  switch --flake ~/etc   # alias: nrs
  #   nix flake update                                  # update pinned inputs, then rebuild
  # ===========================================================================

  description = "declarative machines: nix-darwin + NixOS, one home-manager";

  inputs = {
    # The nix package collection. "nixpkgs-unstable" is the rolling branch —
    # the standard choice on macOS (fresher CLI tools, first-class darwin care).
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    # nix-darwin manages macOS itself: system settings, homebrew, launchd.
    # (NixOS needs no equivalent input — its modules ship inside nixpkgs.)
    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    # "follows" means: use OUR nixpkgs above, not nix-darwin's own copy,
    # so the whole system is built from one package set.
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    # home-manager manages the user environment: packages, dotfiles, zsh.
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Apple Silicon (Asahi) support for NixOS: the patched kernel, GPU/mesa
    # overlay, WiFi/firmware and the m1n1 -> u-boot boot chain. Only the
    # aarch64 Mac hosts pull its module in (see hosts/nacos/boot.nix); it is a
    # no-op for every other machine. `follows` keeps the whole system on our
    # one nixpkgs, so the asahi mesa overlay patches the same mesa the desktop
    # uses.
    nixos-apple-silicon.url = "github:nix-community/nixos-apple-silicon";
    nixos-apple-silicon.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      nix-darwin,
      home-manager,
      nixos-apple-silicon,
    }:
    let
      lib = nixpkgs.lib;

      # Systems this repo can be evaluated for. Darwin hosts are all Apple
      # Silicon; the linux entries cover a NixOS machine on either arch (and
      # keep `nix flake check` honest about the shared home modules — an
      # accidentally darwin-only package in nix/home/ fails to evaluate here,
      # on a mac, long before it reaches the linux box).
      systems = [
        "aarch64-darwin"
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = f: lib.genAttrs systems f;

      # ci/checks.list is the registry: one line per check, `<name> <tools>...`.
      # Parsed here at eval time (pure — just readFile) so this file never
      # carries its own copy of the list, and `nix flake check` cannot disagree
      # with `dagger call all` about which checks exist.
      #
      # Parsed once, resolved per system: the file gives *names*, and
      # checkRegistry turns those names into packages from one system's pkgs.
      checkEntries =
        let
          fieldsOf = line: builtins.filter (f: f != "") (lib.splitString " " line);
          isEntry = fields: fields != [ ] && !(lib.hasPrefix "#" (builtins.head fields));
        in
        builtins.filter isEntry (map fieldsOf (lib.splitString "\n" (builtins.readFile ./ci/checks.list)));

      checkRegistry =
        pkgs:
        builtins.listToAttrs (
          map (fields: {
            name = builtins.head fields;
            # Tools are nixpkgs attribute names, so the same column that feeds
            # `<pinned-nixpkgs>#<attr>` in the container feeds pkgs.<attr> here.
            value = map (attr: pkgs.${attr}) (builtins.tail fields);
          }) checkEntries
        );

      # Every check is `ci/run-checks.sh <subcommand>`. The script discovers
      # what to check by shebang, so nothing is listed here and nothing drifts
      # — the two hand-maintained lists that used to live at this spot had gone
      # stale (3 shell scripts and all 6 ingest-meetings python files, incl. 53
      # tests, were silently unchecked). The same script is what .dagger runs,
      # so container CI and `nix flake check` cannot disagree.
      mkCheck =
        pkgs: name: tools:
        pkgs.runCommand "localetc-${name}" { nativeBuildInputs = tools; } ''
          cd ${self}
          export PYTHONPYCACHEPREFIX="$TMPDIR/pycache"
          bash ci/run-checks.sh ${name}
          touch $out
        '';

      # ---- forcing evaluation of every host, without building it -------------
      # `.dagger/src/checks` says outright that it never builds a host config
      # (needs macOS, or an hour on real NixOS hardware) — a green `dagger call
      # all` means the repo's OWN code is sound, not that a host switches
      # cleanly. This closes part of that gap for `nix flake check`, which runs
      # natively and can afford to ask the real question.
      #
      # A derivation's `.drvPath` is a string, known once nix has EVALUATED and
      # INSTANTIATED it — referencing that string costs nothing to build (no
      # sandbox network, no multi-hour NixOS closure), but surfaces exactly the
      # "path does not exist" / assertion failures that would otherwise wait
      # for `drs` on the real machine.
      #
      # Each host is checked under its OWN system only (`nix flake check`
      # already scopes `checks.<system>` that way): a darwin host's modules are
      # free to assert `stdenv.isDarwin`, so evaluating one under a foreign
      # system's pkgs is not something to rely on, even where it happens to
      # work today.
      mkHostEvalCheck =
        pkgs: name: toplevel:
        pkgs.runCommand "localetc-hosteval-${name}" { } ''
          : "${toplevel.drvPath}"
          touch $out
        '';

      # { <hostname> = <toplevel derivation>; ... } across both platforms —
      # darwinConfigurations' build output IS `.system`; nixosConfigurations'
      # is `.config.system.build.toplevel`. Same shape, different name, same
      # "look tempting to share, aren't" case nix/core.nix's header warns about.
      hostToplevels =
        (lib.mapAttrs (_: cfg: cfg.system) self.darwinConfigurations)
        // (lib.mapAttrs (_: cfg: cfg.config.system.build.toplevel) self.nixosConfigurations);

      hostSystems =
        (lib.mapAttrs (_: cfg: cfg.pkgs.stdenv.hostPlatform.system) self.darwinConfigurations)
        // (lib.mapAttrs (_: cfg: cfg.pkgs.stdenv.hostPlatform.system) self.nixosConfigurations);

      hostEvalChecks =
        system: pkgs:
        lib.mapAttrs' (
          name: toplevel: lib.nameValuePair "hosteval-${name}" (mkHostEvalCheck pkgs name toplevel)
        ) (lib.filterAttrs (name: _: hostSystems.${name} == system) hostToplevels);

      # ---- the facts every module is allowed to know --------------------------
      # Written once per machine in hosts/<hostname>/default.nix, derived here,
      # then handed to every module (system AND home) via specialArgs. No other
      # file hardcodes who you are, where your home is, or which platform it
      # sits on:
      #
      #   username  the account short name (`whoami`)
      #   hostname  the machine name
      #   home      /Users/<username> on macOS, /home/<username> on NixOS
      #   repo      absolute path of this checkout, e.g. /Users/josrey/etc
      #   isDarwin  platform switch; picks nix/home/darwin vs nix/home/linux
      #   work      is this a corporate machine? gates the Sinch shell profile
      #             and the work skills repo. Personal machines set false.
      #
      # isDarwin is passed explicitly rather than read from
      # `pkgs.stdenv.isDarwin` because nix/home/default.nix needs it in
      # `imports`, which is evaluated before pkgs is safely available there.
      # One fact, one source: modules use this arg everywhere, never stdenv.

      # Default checkout directory under $HOME. The only place the name is
      # written; a host that clones elsewhere passes its own absolute `repo`.
      repoDirName = "etc";

      # home-manager is wired identically under nix-darwin and NixOS — same
      # option names, same home modules — so the block lives here once instead
      # of being copy-pasted into both builders.
      hmModule =
        {
          username,
          home,
          repo,
          isDarwin,
          work,
        }:
        {
          home-manager.useGlobalPkgs = true; # reuse the system nixpkgs (incl. allowUnfree)
          home-manager.useUserPackages = true; # install user pkgs to /etc/profiles/per-user/<username>
          home-manager.users.${username} = import ./nix/home;
          # same idea as specialArgs, but for the home modules
          home-manager.extraSpecialArgs = {
            inherit
              username
              home
              repo
              isDarwin
              work
              ;
          };
          # If a real file already sits where home-manager wants to place a
          # symlink, rename it to *.hm-backup instead of aborting activation.
          home-manager.backupFileExtension = "hm-backup";
        };

      # ---- one macOS machine = one mkDarwinHost call --------------------------
      # `hostname` must equal `scutil --get LocalHostName` on that machine.
      # `casks`/`brews`/`masApps` are OPTIONAL host-specific apps, merged onto
      # the shared lists in nix/darwin/homebrew.nix.
      # `modules` is the escape hatch for nix that belongs to ONE machine — see
      # the note at the `++ modules` line below.
      mkDarwinHost =
        {
          hostname,
          username,
          home ? "/Users/${username}",
          repo ? "${home}/${repoDirName}",
          work ? true,
          casks ? [ ],
          brews ? [ ],
          masApps ? { },
          modules ? [ ],
        }:
        nix-darwin.lib.darwinSystem {
          system = "aarch64-darwin";

          # specialArgs makes these available as arguments in every darwin
          # module: `{ username, hostname, home, hostCasks, ... }:`
          specialArgs = {
            inherit
              username
              hostname
              home
              repo
              work
              ;
            isDarwin = true;
            hostCasks = casks;
            hostBrews = brews;
            hostMasApps = masApps;
          };

          # Each module is a file handling exactly one concern. Start reading
          # at nix/core.nix, then nix/darwin/core.nix.
          modules = [
            ./nix/core.nix # the options BOTH platforms set identically
            ./nix/darwin/core.nix
            ./nix/darwin/homebrew.nix
            ./nix/darwin/macos-defaults.nix
            ./nix/darwin/login-items.nix

            # home-manager runs as a nix-darwin module so ONE `darwin-rebuild
            # switch` updates system config AND user config together.
            home-manager.darwinModules.home-manager
            (hmModule {
              inherit
                username
                home
                repo
                work
                ;
              isDarwin = true;
            })
          ]
          # The host's OWN nix files, from its folder under hosts/. Appended
          # last, so a machine can override anything above it.
          #
          # Reading note: an attribute name never shadows the enclosing scope
          # (this set is not `rec`), so `modules` on THIS line is the function
          # argument declared above — not the list being defined.
          ++ modules;
        };

      # ---- one NixOS machine = one mkNixosHost call ---------------------------
      # `system` is explicit here (macs are all aarch64-darwin; a linux box can
      # be either arch). Unlike macOS, nix itself is NixOS's job — there is no
      # Determinate handshake to make, see nix/nixos/core.nix.
      #
      # `apps` is the counterpart of mkDarwinHost's `casks`: OPTIONAL
      # host-specific GUI apps, given as nixpkgs attribute names and merged onto
      # the shared list in nix/nixos/apps.nix.
      mkNixosHost =
        {
          hostname,
          username,
          system,
          home ? "/home/${username}",
          repo ? "${home}/${repoDirName}",
          work ? false,
          apps ? [ ],
          modules ? [ ],
        }:
        nixpkgs.lib.nixosSystem {
          inherit system;

          specialArgs = {
            inherit
              username
              hostname
              home
              repo
              work
              ;
            isDarwin = false;
            hostApps = apps;
            # The Asahi flake input, for the aarch64 Mac hosts to import in
            # their boot.nix. Handed to every NixOS host; the others ignore it.
            appleSilicon = nixos-apple-silicon;
          };

          modules = [
            ./nix/core.nix # the same shared file mkDarwinHost imports
            ./nix/nixos/core.nix
            ./nix/nixos/apps.nix
            ./nix/nixos/desktop.nix # GNOME + audio + printing, shared by every NixOS host
            # hardware-configuration.nix / boot.nix are NOT here: they describe
            # one machine, so they live in that machine's folder and arrive via
            # `modules` below.

            # Same deal as darwin: ONE `nixos-rebuild switch` updates system
            # config AND user config together.
            home-manager.nixosModules.home-manager
            (hmModule {
              inherit
                username
                home
                repo
                work
                ;
              isDarwin = false;
            })
          ]
          # The host's OWN nix files — on this platform that always includes
          # its hardware.nix. Same note as mkDarwinHost above: `modules` here
          # is the function argument, not the list being defined.
          ++ modules;
        };
    in
    {
      # `nix fmt` formats every .nix file in the repo with the official style.
      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt-tree);

      # One derivation per line of ci/checks.list, so `nix build
      # .#checks.<system>.python` and `ci/run-checks.sh python` are the same
      # thing. Each stays its own derivation: they run in parallel and cache
      # independently. Adding a check here means adding a line there.
      #
      # The checks are platform-agnostic (shellcheck, python, nixfmt), so every
      # system gets the same set and `nix flake check` works on mac and NixOS
      # alike.
      checks = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        (lib.mapAttrs (mkCheck pkgs) (checkRegistry pkgs)) // (hostEvalChecks system pkgs)
      );

      # ---- the machine roster -------------------------------------------------
      # ONE MACHINE = ONE FOLDER under hosts/, plus one line here.
      #
      # `hosts/<hostname>/default.nix` is plain data — the facts above, written
      # out for that machine. `import` reads it; the mkHost function turns it
      # into a system. Anything else in the folder is ordinary nix, pulled in by
      # that file's `modules` list (every NixOS host's hardware.nix, for one).
      #
      # The attribute name must equal the machine's hostname: that is what
      # `darwin-rebuild switch --flake ~/etc` matches on.

      darwinConfigurations = {
        # work machine
        "mac-nl-josrey" = mkDarwinHost (import ./hosts/mac-nl-josrey);
        # personal machine
        "playbook" = mkDarwinHost (import ./hosts/playbook);
      };

      # Same as darwin above, for `nixos-rebuild`. Separate namespace, so a
      # machine mid-migration can legitimately appear in both.
      nixosConfigurations = {
        # personal machine, being migrated off macOS (first real NixOS box)
        "nixpad" = mkNixosHost (import ./hosts/nixpad);
        "nacos" = mkNixosHost (import ./hosts/nacos);
      };
    };
}
