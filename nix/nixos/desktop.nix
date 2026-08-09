# =============================================================================
# desktop.nix — the graphical session, shared by every NixOS host.
#
# This is the one subsystem the macs have no counterpart to: on macOS the OS
# *is* the desktop, so nix/darwin only tweaks its defaults. On NixOS the desktop
# is something this repo has to draw itself — display server, login manager,
# desktop environment, audio, printing. It lives here, once, so nixpad and nacos
# get the same environment (the arch difference between them is a hardware
# concern — GPU accel for Apple Silicon belongs in that host's boot/hardware
# files, not in this arch-neutral module).
#
# GNOME on Wayland, chosen to match what nixpad already ran under /etc/nixos.
# Everything below came from that configuration.nix, now shared instead of
# living on one machine.
# =============================================================================
{
  pkgs,
  ...
}:
{
  # ---- display server + login + desktop --------------------------------------
  # xserver.enable is still the switch that pulls in the graphics stack even for
  # a Wayland session (GNOME defaults to Wayland); it also carries the X11
  # keymap below, honoured by both X11 and Wayland sessions.
  services.xserver.enable = true;
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  # Keyboard layout for the graphical session.
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # ---- printing --------------------------------------------------------------
  services.printing.enable = true; # CUPS

  # ---- audio -----------------------------------------------------------------
  # PipeWire replaces PulseAudio: same apps, one server for audio + video +
  # JACK. pulseaudio must be OFF for pipewire to take the seat; the pulse
  # emulation below is what PulseAudio-only apps talk to.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true; # lets pipewire request realtime scheduling
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
}
