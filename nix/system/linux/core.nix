# =============================================================================
# core.nix — the NixOS-ONLY half of machine identity and the nix fundamentals.
#
# Everything both platforms say identically — hostName, the user's home, zsh,
# fonts, allowUnfree — is in nix/core.nix, which flake.nix imports alongside
# this file. What remains below has no macOS counterpart, or means something
# different there. The big one:
#
#   macOS  Determinate Nix owns the nix installation, so nix-darwin is told
#          hands-off (`nix.enable = false`) and nix settings are hand-edited
#          into /etc/nix/nix.custom.conf.
#   NixOS  nix is just another NixOS service. Settings, the daemon and garbage
#          collection are all declared here and applied by `nixos-rebuild`.
#
# `username` arrives via specialArgs — written exactly once, in
# hosts/<hostname>/default.nix.
# =============================================================================
{
  pkgs,
  lib,
  username,
  ...
}:
{
  # DHCP + wifi via nmcli/nmtui. The desktop applet arrives with the desktop.
  # (networking.hostName is shared — see nix/core.nix.)
  networking.networkmanager.enable = true;

  # The rest of the account. `home` is set in nix/core.nix, because macOS needs
  # that one line too.
  users.users.${username} = {
    isNormalUser = true;
    description = username;
    # wheel = sudo; networkmanager = manage wifi; docker = talk to the daemon
    # enabled below without sudo.
    extraGroups = [
      "wheel"
      "networkmanager"
      "docker"
    ];
    # The login shell. programs.zsh.enable below is what puts it in
    # /etc/shells and generates /etc/zshrc; this line opts the user into it.
    shell = pkgs.zsh;
  };

  # ---- nix itself ------------------------------------------------------------
  # Flakes are still nominally experimental, and this whole repo is one.
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  # Lets this user add substituters and build without sudo.
  nix.settings.trusted-users = [
    "root"
    username
  ];
  # macOS gets this by hand (`sudo determinate-nixd gc`); here it is declarative.
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };
  # Hard-link identical files in the store. Cheap disk win, no downside.
  nix.optimise.automatic = true;

  # ---- containers ------------------------------------------------------------
  # The linux answer to colima on macOS: docker-client/compose/k9s come from the
  # shared nix/home-manager/packages.nix, and this provides the engine they talk to.
  virtualisation.docker.enable = true;

  # ---- remote access ---------------------------------------------------------
  # Password auth off: keys only (the same keys that reach this repo on GitHub).
  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
  };

  # ---- locale ----------------------------------------------------------------
  # NixOS defaults to UTC; a machine you sit in front of wants local time.
  # (macOS gets both of these from the OS installer, not from nix.)
  time.timeZone = "Europe/Amsterdam";
  i18n.defaultLocale = "en_US.UTF-8";
  # UI language stays US English (defaultLocale above); formats — dates, paper
  # size, measurement, money — follow Dutch conventions. Companion to the
  # Amsterdam timezone: every machine here sits in NL.
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "nl_NL.UTF-8";
    LC_IDENTIFICATION = "nl_NL.UTF-8";
    LC_MEASUREMENT = "nl_NL.UTF-8";
    LC_MONETARY = "nl_NL.UTF-8";
    LC_NAME = "nl_NL.UTF-8";
    LC_NUMERIC = "nl_NL.UTF-8";
    LC_PAPER = "nl_NL.UTF-8";
    LC_TELEPHONE = "nl_NL.UTF-8";
    LC_TIME = "nl_NL.UTF-8";
  };

  # Compatibility marker for NixOS's stateful defaults. Set to the release you
  # INSTALL from and then NEVER changed — it is not a version selector, and
  # bumping it can silently migrate service state (postgres data dirs, etc).
  #
  # nixpad installed from 26.05 (its /etc/nixos carried this value), so that is
  # the shared default. It is `mkDefault` because the install release is
  # per-machine: nacos installed from 26.11 and overrides this in its own
  # hosts/nacos/boot.nix, and any future host that differs does the same.
  system.stateVersion = lib.mkDefault "26.05";
}
