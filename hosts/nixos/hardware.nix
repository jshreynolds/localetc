# =============================================================================
# hardware.nix — PLACEHOLDER. This does not describe any real machine.
#
# NixOS refuses to evaluate a configuration with no root filesystem and no
# bootloader, so without this file `nix flake check` cannot even look at the
# nixosConfiguration — and the whole point of having one before the machine
# exists is to prove the SHARED home modules (nix/home) evaluate on linux.
# Hence: the smallest set of options that satisfies those assertions.
#
# It will not boot anything. The device labels below are invented.
#
# ---- REPLACE ME, on the machine, before the first switch --------------------
#   sudo nixos-generate-config --show-hardware-config \
#     > ~/etc/hosts/nixos/hardware.nix
#   git add hosts/nixos/hardware.nix    # nix only sees files git knows about
#   sudo nixos-rebuild switch --flake ~/etc
#
# That output supersedes this file entirely — kernel modules, real filesystem
# UUIDs, swap, CPU microcode. Keep the bootloader lines if the generated config
# does not carry them (it usually does not): systemd-boot for UEFI, or
# boot.loader.grub for legacy BIOS.
#
# This file describes ONE machine and lives in that machine's folder — it
# reaches the system through `modules` in ./default.nix. Every NixOS host has
# its own; nothing here is shared.
# =============================================================================
{
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/BOOT";
    fsType = "vfat";
  };

  swapDevices = [ ];
}
