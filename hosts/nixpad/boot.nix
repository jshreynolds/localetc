# =============================================================================
# boot.nix — hand-written boot config for nixpad.
#
# Kept SEPARATE from hardware-configuration.nix on purpose. That file is
# `nixos-generate-config` output and must stay freely regenerable — you overwrite
# the whole thing and lose nothing:
#   sudo nixos-generate-config --show-hardware-config > hosts/nixpad/hardware-configuration.nix
#   nix fmt   # the generator's layout differs from the repo's; re-wrap it (semantics unchanged)
# Anything hand-written about this machine's boot goes HERE instead, so the two
# never mix and there is never a generated file with your edits buried in it.
#
# These lines lived in the old /etc/nixos/configuration.nix; the generator does
# not emit them:
#   - the UEFI bootloader (systemd-boot)
#   - the newest kernel rather than the LTS default
#   - the LUKS unlock for the SWAP device. (The ROOT device's unlock IS
#     generated, and lives in hardware-configuration.nix.)
#
# Machine-specific: reaches the system via `modules` in ./default.nix, nothing
# shared. Bootloader stays per-host (not nix/system/linux/core.nix) because Apple
# Silicon hosts like nacos boot a different way — systemd-boot is not universal.
# =============================================================================
{ pkgs, ... }:
{
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.kernelPackages = pkgs.linuxPackages_latest;

  boot.initrd.luks.devices."luks-ac15a280-8c9b-417e-a3ec-6631d1e98c95".device =
    "/dev/disk/by-uuid/ac15a280-8c9b-417e-a3ec-6631d1e98c95";
}
