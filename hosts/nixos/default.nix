# =============================================================================
# nixos — personal machine, being migrated off macOS.
#
# PLAIN DATA, not a nix module — see hosts/mac-nl-josrey/default.nix for why.
# Field list and defaults: mkNixosHost in flake.nix.
#
# THREE FACTS TO CONFIRM before the first switch:
#   1. `system` — x86_64-linux for a PC, aarch64-linux for Apple Silicon under
#      Asahi.
#   2. `hostname`/`username` — must match the installed system, and `hostname`
#      must match this folder's name and the key in flake.nix.
#   3. ./hardware.nix — replace the placeholder with the real
#      `nixos-generate-config` output, or this will not boot.
#
# Until then this host earns its keep by proving nix/home evaluates on linux
# (`nix eval .#nixosConfigurations.nixos...`), which is what keeps darwin-only
# packages out of the shared modules.
# =============================================================================
{
  hostname = "nixos";
  username = "jreynolds";
  system = "x86_64-linux";
  work = false;

  apps = [
    # apps only THIS machine gets (shared list: nix/nixos/apps.nix)
  ];

  modules = [ ./hardware.nix ];
}
