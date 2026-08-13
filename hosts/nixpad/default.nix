# =============================================================================
# nixpad — personal machine, being migrated off macOS. First real NixOS box.
#
# PLAIN DATA, not a nix module — see hosts/mac-nl-josrey/default.nix for why.
# Field list and defaults: mkNixosHost in flake.nix.
#
# `hostname` is nixpad (not "nixos") on purpose: a machine literally named
# `nixos` running NixOS is one word doing two jobs. The attribute key in
# flake.nix, this folder's name, and networking.hostName all follow.
#
# Two machine files, one job each:
#   ./hardware-configuration.nix  verbatim nixos-generate-config output
#                                 (regenerate freely, never hand-edit)
#   ./boot.nix                    hand-written boot config (bootloader, kernel,
#                                 swap LUKS unlock)
# =============================================================================
{
  hostname = "nixpad";
  username = "jshlyd";
  system = "x86_64-linux";
  work = false;

  apps = [
    # apps only THIS machine gets (shared list: nix/system/linux/apps.nix)
  ];

  modules = [
    ./hardware-configuration.nix
    ./boot.nix
  ];
}
