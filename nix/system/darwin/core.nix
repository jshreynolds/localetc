# =============================================================================
# core.nix — the macOS-ONLY half of machine identity and the nix fundamentals.
#
# Nix concept: a *module* is just a function from `{ ... }` (things nix hands
# you, like `pkgs` or `config`) to an attribute set of option values. nix-darwin
# merges all modules together and builds the system from the result.
#
# Everything both platforms say identically — hostName, the user's home, zsh,
# fonts, allowUnfree — is in nix/core.nix, which flake.nix imports alongside
# this file. What remains below has no NixOS counterpart, or means something
# different there.
#
# `username` and `hostname` arrive via specialArgs — they are written exactly
# once, in hosts/<hostname>/default.nix.
# =============================================================================
{
  username,
  hostname,
  ...
}:
{
  # CRITICAL: Determinate Nix owns the nix installation on this machine —
  # the daemon, /etc/nix/nix.conf, upgrades, and garbage collection.
  # `nix.enable = false` tells nix-darwin "hands off nix itself"; without it
  # the two would fight over nix.conf and the daemon launchd job.
  #
  # Consequences (all nix-darwin `nix.*` options are inert):
  #   - nix settings (trusted-users, substituters, ...) are hand-edited into
  #     /etc/nix/nix.custom.conf, then:
  #     sudo launchctl kickstart -k system/systems.determinate.nix-daemon
  #   - upgrade nix:  sudo determinate-nixd upgrade
  #   - garbage-collect old generations:  sudo determinate-nixd gc
  nix.enable = false;

  # nix-darwin needs to know which user owns user-scoped things
  # (homebrew, system.defaults user domains, home-manager). No NixOS
  # equivalent — there, "the user" is just an entry in users.users.
  system.primaryUser = username;

  # The two EXTRA names macOS gives the same machine. networking.hostName is
  # the shared one and lives in nix/core.nix.
  networking.computerName = hostname;
  networking.localHostName = hostname;

  # Compatibility marker for nix-darwin's internal state format. Set once at
  # install time and then NEVER changed — it is not a version selector.
  system.stateVersion = 6;

  # If activation ever fails with an assertion about the nixbld group id
  # (Determinate uses 350, classic nix used 30000), uncomment:
  # ids.gids.nixbld = 350;
}
