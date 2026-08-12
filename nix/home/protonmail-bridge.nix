# =============================================================================
# protonmail-bridge.nix — the headless Proton Mail Bridge, on every machine.
#
# Bridge is a local IMAP/SMTP gateway: it holds the Proton session, decrypts
# mail, and serves it on 127.0.0.1 so an ordinary mail client can read it.
# It requires a PAID Proton plan. It is not a mail client — point Thunderbird,
# Evolution or Apple Mail at the ports it reports.
#
# One module rather than a linux/ + darwin/ pair: same daemon, same login, same
# ports — only the service manager differs, and splitting it would duplicate
# the explanation. (Same call as docker-credential-helpers in packages.nix.)
#
# One-time, per machine:  protonmail-bridge --cli  ->  login  ->  info
# `info` prints the IMAP/SMTP ports and the generated bridge password, which is
# what the mail client authenticates with — never your Proton password.
#
# Credentials live in the platform keychain: gnome-keyring on NixOS (declared
# in nix/nixos/desktop.nix), the system Keychain on macOS.
# =============================================================================
{
  pkgs,
  lib,
  isDarwin,
  ...
}:
{
  # Linux: home-manager's module draws the systemd user service (bound to
  # graphical-session.target, so the keyring is unlocked first) and installs
  # the package.
  services.protonmail-bridge.enable = !isDarwin;

  home.packages = lib.optional isDarwin pkgs.protonmail-bridge;
}
// lib.optionalAttrs isDarwin {
  # macOS has no equivalent module: same --noninteractive daemon under launchd.
  launchd.agents.protonmail-bridge = {
    enable = true;
    config = {
      ProgramArguments = [
        (lib.getExe pkgs.protonmail-bridge)
        "--noninteractive"
      ];
      RunAtLoad = true;
      KeepAlive = true;
    };
  };
}
