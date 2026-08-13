# =============================================================================
# gpg-keys.nix — GPG key hygiene: distribute public keys, warn before expiry.
#
# Two jobs, both consequences of the per-machine key layout used for sops:
# every machine holds its own secret key and the other machines' public keys,
# and every key expires after two years.
#
#   1. Import secrets/pubkeys/*.asc at activation, so each machine can encrypt
#      to all the others. Refreshing a key is then a rebuild, not a manual
#      export/import between three machines.
#
#   2. Warn daily once any key is within 30 days of expiry. An expired key can
#      still DECRYPT everything it ever could — only encrypting to it fails —
#      so this is a nuisance alarm, not an emergency one. Extend with
#      `gpg --quick-set-expire <FPR> 2y`: the expiry sits on the primary only,
#      and an expired primary is enough to make the key unusable for encryption.
#
# The secret keys themselves are never in this repo, and never generated here:
# each machine makes its own, with a passphrase this repo never sees.
# =============================================================================
{
  pkgs,
  lib,
  config,
  isDarwin,
  ...
}:
let
  pubkeys = ../../secrets/pubkeys;

  gpg-expiry-check = pkgs.writeShellApplication {
    name = "gpg-expiry-check";
    runtimeInputs = [
      pkgs.gnupg
      pkgs.coreutils
    ]
    ++ lib.optional (!isDarwin) pkgs.libnotify;
    text = ''
      now=$(date +%s)
      limit=$((now + 30 * 86400))
      msgs=""

      while read -r keyid expiry; do
        case "$expiry" in
          "" | *[!0-9]*) continue ;;
        esac
        [ "$expiry" -le "$limit" ] || continue
        days=$(((expiry - now) / 86400))
        msgs="$msgs$keyid expires in $days days ($(date -d "@$expiry" +%F))"$'\n'
      done < <(gpg --list-keys --with-colons | awk -F: '$1=="pub" || $1=="sub" {print $5, $7}')

      [ -n "$msgs" ] || exit 0

      printf 'gpg keys nearing expiry:\n%s' "$msgs"
      if command -v notify-send >/dev/null 2>&1; then
        notify-send "GPG key expiry" "$msgs"
      elif [ -x /usr/bin/osascript ]; then
        /usr/bin/osascript -e 'display notification "A GPG key expires within 30 days" with title "GPG"'
      fi
    '';
  };
in
{
  home.packages = [ gpg-expiry-check ];

  # Where sops looks for the secret key that decrypts secrets/.
  sops.gnupg.home = "${config.home.homeDirectory}/.gnupg";

  # Public keys only — safe to import unconditionally, and a no-op once present.
  home.activation.importGpgPubkeys = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    for key in ${pubkeys}/*.asc; do
      [ -e "$key" ] || continue
      run ${lib.getExe pkgs.gnupg} --batch --quiet --import "$key" || true
    done
  '';

  systemd.user.services.gpg-expiry-check = lib.mkIf (!isDarwin) {
    Unit.Description = "Warn about GPG keys nearing expiry";
    Service = {
      Type = "oneshot";
      ExecStart = lib.getExe gpg-expiry-check;
    };
  };

  systemd.user.timers.gpg-expiry-check = lib.mkIf (!isDarwin) {
    Unit.Description = "Daily GPG key expiry check";
    Timer = {
      OnCalendar = "daily";
      Persistent = true;
    };
    Install.WantedBy = [ "timers.target" ];
  };
}
// lib.optionalAttrs isDarwin {
  launchd.agents.gpg-expiry-check = {
    enable = true;
    config = {
      ProgramArguments = [ (lib.getExe gpg-expiry-check) ];
      RunAtLoad = true;
      StartInterval = 86400;
    };
  };
}
