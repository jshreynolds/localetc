# =============================================================================
# core.nix — machine identity and the nix/macOS fundamentals.
#
# Nix concept: a *module* is just a function from `{ ... }` (things nix hands
# you, like `pkgs` or `config`) to an attribute set of option values. nix-darwin
# merges all modules together and builds the system from the result.
# =============================================================================
{ ... }:
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
  # (homebrew, system.defaults user domains, home-manager).
  system.primaryUser = "josrey";
  users.users.josrey.home = "/Users/josrey";

  # Machine name — replaces the scutil calls in the old 90-macos-system.sh.
  networking.hostName = "mac-nl-josrey-2";
  networking.computerName = "mac-nl-josrey-2";
  networking.localHostName = "mac-nl-josrey-2";

  # nix-darwin generates /etc/zshrc so every zsh (login, ssh, scripts) gets
  # nix paths and completions wired in before the user's own ~/.zshrc runs.
  programs.zsh.enable = true;

  # Some packages have non-open-source licenses (terraform is BUSL, for one).
  # nixpkgs refuses to build them unless you opt in. home-manager inherits
  # this because flake.nix sets useGlobalPkgs.
  nixpkgs.config.allowUnfree = true;

  # Compatibility marker for nix-darwin's internal state format. Set once at
  # install time and then NEVER changed — it is not a version selector.
  system.stateVersion = 6;

  # If activation ever fails with an assertion about the nixbld group id
  # (Determinate uses 350, classic nix used 30000), uncomment:
  # ids.gids.nixbld = 350;
}
