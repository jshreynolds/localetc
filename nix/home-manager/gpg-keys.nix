# =============================================================================
# gpg-keys.nix — GPG key hygiene: distribute public keys, warn before expiry.
#
# Two jobs, both consequences of the per-machine key layout used for sops:
# every machine holds its own secret key and the other machines' public keys.
#
#   1. Import secrets/pubkeys/*.asc at activation, so each machine can encrypt
#      to all the others. Refreshing a key is then a rebuild, not a manual
#      export/import between three machines.
#
#   2. Warn daily once any key in the keyring is within 30 days of expiry. The
#      machine keys are made without one, but signing keys and imported keys
#      often carry one. An expired key can still DECRYPT everything it ever
#      could — only encrypting to it fails — so this is a nuisance alarm, not
#      an emergency one. Extend with `gpg --quick-set-expire <FPR> <spec>`: the
#      expiry sits on the primary only, and an expired primary is enough to
#      make the key unusable for encryption.
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
  #
  # A failed import is reported but does not abort activation: it costs this
  # machine the ability to ENCRYPT to some other machine, which is no reason to
  # block a rebuild. It must be loud, though — a silent `|| true` here once hid
  # a stale keyboxd lock that made every import time out for days, leaving an
  # empty keyring behind while rebuilds still looked green.
  #
  # Skipped when no user session exists, which on linux means the boot run of
  # home-manager-<user>.service — the same unit a rebuild restarts, so this is
  # the only thing that tells the two apart. With use-keyboxd, importing before
  # login spawns `keyboxd --daemon` with no /run/user/$UID to hold its socket,
  # so it lands in ~/.gnupg and outlives activation holding pubring.db.lock. The
  # session's gpg then looks under /run/user/$UID, finds nothing, starts a second
  # keyboxd, and that one waits ~40s on the lock and times out. sops-nix.service
  # is ordered before graphical-session-pre.target, so GNOME — mouse included —
  # hangs for those 40s and no secret gets rendered. Nothing is lost by waiting:
  # these keys only change with the repo, and that means a rebuild.
  home.activation.importGpgPubkeys = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if ${if isDarwin then "true" else ''[ -d "/run/user/$(id -u)" ]''}; then
      for key in ${pubkeys}/*.asc; do
        [ -e "$key" ] || continue
        run ${lib.getExe pkgs.gnupg} --batch --quiet --import "$key" \
          || echo "gpg-keys: failed to import $key — cannot encrypt to that machine" >&2
      done
    else
      echo "gpg-keys: no user session — deferring pubkey import to the next rebuild" >&2
    fi
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
