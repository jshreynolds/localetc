# =============================================================================
# boot.nix — hand-written boot + Apple-Silicon platform config for nacos.
#
# Same split as hosts/nixpad/boot.nix: hardware-configuration.nix stays verbatim
# `nixos-generate-config` output (freely regenerable), and everything
# hand-written about THIS machine's boot lives here. But nacos is an M1 MacBook
# Air running under Asahi, so the boot story is not nixpad's:
#
#   - It needs the whole Asahi stack — a patched kernel, the mesa GPU overlay,
#     WiFi/firmware, and the m1n1 -> u-boot chain that stands in for a normal
#     UEFI. That comes from the `nixos-apple-silicon` flake input, reaching this
#     module as `appleSilicon` via specialArgs (see mkNixosHost in flake.nix).
#     Its module auto-applies the mesa overlay and drops m1n1/u-boot into
#     systemd-boot's extraFiles, so importing it is all that's required.
#   - The kernel is therefore NOT set here (contrast nixpad's
#     `boot.kernelPackages = linuxPackages_latest`) — `hardware.asahi.enable`
#     pins the asahi kernel and unsetting it would break the GPU/firmware.
#   - Apple Silicon exposes no writable EFI variable store, so
#     `canTouchEfiVariables` is FALSE here where nixpad sets it true.
#   - Root is ext4-on-LVM-on-LUKS. On Asahi the installer wrote the root LUKS
#     unlock into the hand-kept configuration.nix (not into the generated
#     hardware file the way nixpad's was), so it lives here, next to the initrd
#     LVM that finds vg-root once the container is open.
#
# Vendored, on purpose: the machine's peripheral firmware (WiFi, webcam,
# ambient-light sensor) lives at ./vendorfw/firmware.cpio in this folder, and
# `peripheralFirmwareDirectory` below points the asahi module at it. It has to
# be here because a flake evaluates PURELY: the module's default reads the
# absolute path /boot/vendorfw off the ESP, which pure eval is forbidden to
# touch, so it resolves to null and the build asserts out. Only git-tracked
# files are visible to a pure build, hence the copy. The upstream module's own
# docs tell flake users to do exactly this. It is non-redistributable Apple
# firmware but not a secret — regenerate it from macOS with the Asahi installer
# and re-copy from /boot/vendorfw if it ever changes.
# =============================================================================
{ appleSilicon, ... }:
{
  imports = [ appleSilicon.nixosModules.default ];

  # The Asahi kernel, GPU/mesa overlay, m1n1+u-boot boot chain and firmware
  # extraction. Set explicitly (the module warns against relying on its
  # historical default-true).
  hardware.asahi.enable = true;

  # Where the peripheral firmware.cpio lives — this folder, not the ESP, so a
  # pure flake build can see it. See the header comment for the full why.
  hardware.asahi.peripheralFirmwareDirectory = ./vendorfw;

  # UEFI via systemd-boot; the asahi module installs m1n1/u-boot alongside it.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = false;

  # Unlock the LUKS container, then let the initrd's LVM find vg-root inside it.
  boot.initrd.luks.devices.cryptroot = {
    device = "/dev/disk/by-uuid/51d3e62e-a199-4163-8f1b-6ca4535c3ebf";
    allowDiscards = true;
    bypassWorkqueues = true;
  };
  boot.initrd.services.lvm.enable = true;

  # iwd instead of wpa_supplicant: the Asahi-recommended backend for this
  # machine's Broadcom WiFi. (NetworkManager itself is enabled in
  # nix/system/linux/core.nix; this only swaps its wifi driver.)
  networking.networkmanager.wifi.backend = "iwd";

  # nacos was installed from 26.11; the shared default in nix/system/linux/core.nix is
  # 26.05 (nixpad's install release). stateVersion tracks the install release
  # for stateful defaults and must not follow upgrades, so it is pinned here.
  system.stateVersion = "26.11";
}
