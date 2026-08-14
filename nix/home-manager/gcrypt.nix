# =============================================================================
# gcrypt.nix — point git-remote-gcrypt at the same keys sops already uses.
#
# A gcrypt remote encrypts objects client-side, so the forge hosting it only
# ever stores ciphertext. gcrypt keeps the packfile keys in a manifest,
# encrypts that manifest to `remote.<name>.gcrypt-participants` and signs it
# with `gcrypt-signingkey`. Both are plain PGP fingerprints — the same
# per-machine keys secrets/ already distributes — so each machine has ONE key
# to look after, not two, and `secrets/pubkeys/*.asc` is the single roster:
# a machine with a public key there gets the encrypted repos below.
#
# gpg-keys.nix imports those same files into the keyring at activation, which
# is what makes the fingerprints usable here. (`gcrypt.gpg-args =
# --trust-model always`, which stops gpg refusing to encrypt to keys you never
# signed, is set globally in git.nix.)
#
# Why an activation script and not a config file: participants live in each
# repo's own .git/config, which no nix module can write, and repo-local keys
# beat anything an `includeIf` could contribute. So this reconciles the config
# of every listed repo at each rebuild, and is a no-op once it already matches.
#
# IMPORTANT: adding a key re-keys nothing by itself. gcrypt rewrites the
# manifest on PUSH only, and that push must come from a machine that is already
# a participant — the same two-machine dance as enrolling a sops recipient
# (secrets/README.md §5):
#
#   on a current participant:  git -C <repo> commit --allow-empty -m rekey
#                              git -C <repo> push
#   on the new machine:        git clone gcrypt::<url>
#
# Until that push happens, a newly listed machine can read secrets and still
# not clone.
# =============================================================================
{
  pkgs,
  lib,
  config,
  ...
}:
let
  pubkeys = ../../secrets/pubkeys;

  # Every repo whose gcrypt remote is kept in sync with the key roster.
  repos = [
    {
      path = "${config.home.homeDirectory}/worksidian";
      remote = "origin";
    }
  ];

  syncCalls = lib.concatMapStringsSep "\n" (r: ''sync_repo "${r.path}" "${r.remote}"'') repos;
in
{
  # After the pubkeys are imported: a fingerprint is only useful here once the
  # matching public key is actually in the keyring.
  home.activation.gcryptParticipants = lib.hm.dag.entryAfter [ "importGpgPubkeys" ] ''
    gpg=${lib.getExe pkgs.gnupg}
    git=${pkgs.git}/bin/git

    participants=$(
      for key in ${pubkeys}/*.asc; do
        [ -e "$key" ] || continue
        "$gpg" --show-keys --with-colons "$key" \
          | ${pkgs.gawk}/bin/awk -F: '$1=="fpr"{print $10; exit}'
      done | ${pkgs.coreutils}/bin/sort -u | ${pkgs.findutils}/bin/xargs
    ) || true

    # This machine signs the manifest with whichever participant key it holds
    # the secret half of. gcrypt rejects a manifest signed by a non-participant.
    signingkey=""
    for fpr in $participants; do
      if "$gpg" --list-secret-keys "$fpr" >/dev/null 2>&1; then
        signingkey="$fpr"
        break
      fi
    done

    # Only ever writes on a real change, so a matching repo stays silent.
    sync_repo() {
      local repo="$1" remote="$2" current

      [ -d "$repo/.git" ] || return 0

      current=$("$git" -C "$repo" config --get "remote.$remote.gcrypt-participants" || true)
      if [ "$current" != "$participants" ]; then
        run "$git" -C "$repo" config "remote.$remote.gcrypt-participants" "$participants"
        echo "gcrypt: $repo participants -> $participants"
      fi

      current=$("$git" -C "$repo" config --get "remote.$remote.gcrypt-signingkey" || true)
      if [ -n "$signingkey" ] && [ "$current" != "$signingkey" ]; then
        run "$git" -C "$repo" config "remote.$remote.gcrypt-signingkey" "$signingkey"
        echo "gcrypt: $repo signingkey -> $signingkey"
      fi
    }

    # A bad roster must not abort a rebuild — it costs this machine a vault
    # push, which is no reason to block everything else. It must be loud, though.
    if [ -z "$participants" ]; then
      echo "gcrypt: no public keys in ${pubkeys} — repos left alone" >&2
    elif [ -z "$signingkey" ]; then
      echo "gcrypt: no secret key for any participant — this machine cannot push the vault" >&2
    else
      ${syncCalls}
    fi
  '';
}
