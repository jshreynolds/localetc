# =============================================================================
# core.nix — machine identity and the nix/NixOS fundamentals.
#
# The NixOS counterpart to nix/darwin/core.nix. Same job, one big difference:
#
#   macOS  Determinate Nix owns the nix installation, so nix-darwin is told
#          hands-off (`nix.enable = false`) and nix settings are hand-edited
#          into /etc/nix/nix.custom.conf.
#   NixOS  nix is just another NixOS service. Settings, the daemon and garbage
#          collection are all declared here and applied by `nixos-rebuild`.
#
# `username`, `hostname`, and `home` arrive via specialArgs — they are defined
# exactly once, in the mkNixosHost call in flake.nix.
# =============================================================================
{
  pkgs,
  username,
  hostname,
  home,
  ...
}:
{
  networking.hostName = hostname;
  # DHCP + wifi via nmcli/nmtui. The desktop applet arrives with the desktop.
  networking.networkmanager.enable = true;

  users.users.${username} = {
    isNormalUser = true;
    inherit home;
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

  # ---- shell -----------------------------------------------------------------
  # Generates /etc/zshrc so every zsh (login, ssh, scripts) gets nix paths and
  # completions wired in before the user's own ~/.zshrc runs. Exactly what
  # nix/darwin/core.nix does on the other platform.
  programs.zsh.enable = true;

  # ---- containers ------------------------------------------------------------
  # The linux answer to colima on macOS: docker-client/compose/k9s come from the
  # shared nix/home/packages.nix, and this provides the engine they talk to.
  virtualisation.docker.enable = true;

  # ---- remote access ---------------------------------------------------------
  # Password auth off: keys only (the same keys that reach this repo on GitHub).
  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
  };

  # ---- locale & fonts --------------------------------------------------------
  # NixOS defaults to UTC; a machine you sit in front of wants local time.
  time.timeZone = "Europe/Amsterdam";
  i18n.defaultLocale = "en_US.UTF-8";

  # Same two nerd fonts the macs install, so terminal glyphs match everywhere.
  fonts.packages = with pkgs; [
    nerd-fonts.fira-code
    nerd-fonts._3270
  ];

  # Some packages have non-open-source licenses (terraform is BUSL, for one).
  # nixpkgs refuses to build them unless you opt in. home-manager inherits this
  # because flake.nix sets useGlobalPkgs.
  nixpkgs.config.allowUnfree = true;

  # Compatibility marker for NixOS's stateful defaults. Set to the release you
  # INSTALL from and then NEVER changed — it is not a version selector, and
  # bumping it can silently migrate service state (postgres data dirs, etc).
  #
  # TODO on first install: set this to the release on the installer ISO.
  system.stateVersion = "25.05";
}
