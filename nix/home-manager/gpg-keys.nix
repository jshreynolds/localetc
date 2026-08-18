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

  # sops-nix defaults its unit into graphical-session-pre.target, where the key's
  # passphrase cannot yet be read back out of the login keyring: pinentry falls
  # back to a dialog, and a dialog raised that early dies unanswered. Nothing
  # pulls it in at login now — storage-box.nix's timer does, once the desktop has
  # settled and the lookup is silent again.
  # RemainAfterExit so a consumer's Requires= is satisfied by the run that
  # already happened, rather than decrypting again every time. Activation still
  # restarts it, so an edited secret re-renders.
  systemd.user.services.sops-nix = lib.mkIf (!isDarwin) {
    Install.WantedBy = lib.mkForce [ ];
    Service.RemainAfterExit = true;
  };

  # OnStartupSec, not OnBootSec: in a user manager the latter is measured from
  # system boot, so by login it has usually elapsed already and the timer fires
  # at once — back into the session start, where the keyring isn't up and the
  # decryption fails. Half a minute after login it is up and pinentry answers
  # from it without asking anyone.
  systemd.user.timers.sops-nix = lib.mkIf (!isDarwin) {
    Unit.Description = "Render sops secrets once the session has settled";
    Timer.OnStartupSec = "30s";
    Install.WantedBy = [ "timers.target" ];
  };

  # Public keys only — safe to import unconditionally, and a no-op once present.
  #
  # A failed import is reported but does not abort activation: it costs this
  # machine the ability to ENCRYPT to some other machine, which is no reason to
  # block a rebuild. It must be loud, though — a silent `|| true` here once hid
  # a stale keyboxd lock that made every import time out for days, leaving an
  # empty keyring behind while rebuilds still looked green.
  #
  # Skipped at boot, detected by /run/user/$UID not existing yet: importing there
  # strands a keyboxd holding pubring.db.lock, and every later gpg blocks 40s on
  # it. Rebuilds run from a session, and only a rebuild changes these keys.
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
