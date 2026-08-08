# =============================================================================
# nacos — personal machine, aarch64.
#
# PLAIN DATA, not a nix module — see hosts/mac-nl-josrey/default.nix for why.
# Field list and defaults: mkNixosHost in flake.nix.
#
# Same three facts to confirm as hosts/nixos/default.nix — in particular
# ./hardware.nix is still the placeholder and will not boot anything.
# =============================================================================
{
  hostname = "nacos";
  username = "jreynolds";
  system = "aarch64-linux";
  work = false;

  apps = [
    # apps only THIS machine gets (shared list: nix/nixos/apps.nix)
  ];

  modules = [ ./hardware.nix ];
}
