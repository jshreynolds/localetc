# =============================================================================
# nacos — personal machine, aarch64. An M1 MacBook Air running NixOS on Asahi.
#
# PLAIN DATA, not a nix module — see hosts/mac-nl-josrey/default.nix for why.
# Field list and defaults: mkNixosHost in flake.nix.
#
# Two machine files, one job each (same split as hosts/nixpad):
#   ./hardware-configuration.nix  verbatim nixos-generate-config output
#                                 (regenerate freely, never hand-edit)
#   ./boot.nix                    hand-written boot + Apple-Silicon platform
#                                 config: the Asahi module, bootloader, root
#                                 LUKS/LVM unlock, WiFi backend, stateVersion
# =============================================================================
{
  hostname = "nacos";
  username = "jshlyd";
  system = "aarch64-linux";
  work = false;

  apps = [
    # apps only THIS machine gets (shared list: nix/system/linux/apps.nix)
  ];

  modules = [
    ./hardware-configuration.nix
    ./boot.nix
  ];
}
