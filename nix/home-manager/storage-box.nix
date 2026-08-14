# =============================================================================
# storage-box.nix — two-way sync of ~/sbox folders with a Hetzner Storage Box,
# on every machine.
#
# rclone bisync over SFTP. A Storage Box has no shell, so nothing can run on
# the far end — it is a dumb hub, and each machine reconciles against it on a
# timer. Edits may happen on any machine, just not on two at once: bisync
# compares against the previous run's listing, so it can tell a new file from a
# deleted one without a daemon watching the tree.
#
# The connection details are encrypted in secrets/storage-box.env and rendered
# by sops to ~/.config/storage-box/env at activation. Edit them with:
#
#   sops secrets/storage-box.env
#
# Editing alone changes nothing on the machine: sops-nix decrypts the copy of
# this file in the nix store, so a rebuild is what re-renders the env file.
#
# rclone builds the `box:` remote straight from those RCLONE_CONFIG_BOX_*
# variables, so no rclone.conf exists anywhere. The two path variables are set
# below rather than in the secret: they are not secret, and they differ between
# macOS and linux homes.
#
# Also one-time, per machine:
#   ssh-copy-id -s -p 23 uXXXXXX@uXXXXXX.your-storagebox.de  (upload the pubkey;
#     -s copies over SFTP — without it ssh-copy-id needs a shell the box lacks)
#   ssh-keyscan -p 23 uXXXXXX.your-storagebox.de >> ~/.ssh/known_hosts
# =============================================================================
{
  pkgs,
  lib,
  config,
  isDarwin,
  hostname,
  ...
}:
let
  # A machine can only decrypt the secret if secrets/*.env was encrypted to its
  # key, i.e. if it has a public key in the repo (see secrets/pubkeys/README.md).
  # Machines that don't are skipped entirely rather than declaring a secret that
  # sops-nix would then fail to render — a failed sops-nix.service fails the
  # whole activation, which would block every rebuild on that machine until
  # another machine got around to running `sops updatekeys`.
  isSopsRecipient = builtins.pathExists ../../secrets/pubkeys/${hostname}.asc;

  # Add a name here to sync another folder from the same box. Each entry pairs
  # ~/sbox/<name> with <STORAGE_BOX_ROOT>/<name>.
  folders = [ "yellingatrobots" ];

  envFile = "${config.xdg.configHome}/storage-box/env";
  localRoot = "${config.home.homeDirectory}/sbox";

  storage-box-sync = pkgs.writeShellApplication {
    name = "storage-box-sync";
    runtimeInputs = [ pkgs.rclone ];
    text = ''
      env_file="${envFile}"
      if [ ! -r "$env_file" ]; then
        echo "storage-box: sops has not rendered $env_file — is the gpg key present?" >&2
        exit 1
      fi

      set -a
      # shellcheck disable=SC1090
      . "$env_file"
      set +a

      # Not secret, and home differs per platform, so not in the sops file.
      export RCLONE_CONFIG_BOX_KEY_FILE="$HOME/.ssh/id_ed25519"
      export RCLONE_CONFIG_BOX_KNOWN_HOSTS_FILE="$HOME/.ssh/known_hosts"

      if [ -z "''${STORAGE_BOX_ROOT:-}" ]; then
        echo "storage-box: STORAGE_BOX_ROOT not set in $env_file" >&2
        exit 1
      fi

      state="''${XDG_STATE_HOME:-$HOME/.local/state}/storage-box"
      mkdir -p "$state"

      folders=(${lib.escapeShellArgs folders})
      for folder in "''${folders[@]}"; do
        local_dir="${localRoot}/$folder"
        mkdir -p "$local_dir"

        # bisync refuses to run until both sides have been seeded once.
        args=()
        if [ ! -e "$state/$folder.seeded" ]; then
          echo "storage-box: seeding $folder"
          args+=(--resync)
        fi

        rclone bisync "$local_dir" "box:$STORAGE_BOX_ROOT/$folder" ''${args[@]+"''${args[@]}"} \
          --create-empty-src-dirs \
          --resilient \
          --recover \
          --conflict-resolve newer \
          --transfers 4 \
          --checkers 8 \
          --log-level INFO

        touch "$state/$folder.seeded"
      done
    '';
  };
in
{
  home.packages = [ storage-box-sync ];

  sops.secrets."storage-box.env" = lib.mkIf isSopsRecipient {
    sopsFile = ../../secrets/storage-box.env;
    format = "dotenv";
    path = envFile;
    mode = "0600";
  };

  # Linux: a plain oneshot on a timer. Persistent catches up after the machine
  # has been off, which is the normal case here. Not scheduled on a machine
  # without the key: nothing would have rendered the env file, so every run
  # would fail. `storage-box-sync` stays on PATH and says so if run by hand.
  systemd.user.services.storage-box-sync = lib.mkIf (!isDarwin && isSopsRecipient) {
    Unit.Description = "Sync ~/sbox with the Hetzner Storage Box";
    Service = {
      Type = "oneshot";
      ExecStart = lib.getExe storage-box-sync;
    };
  };

  systemd.user.timers.storage-box-sync = lib.mkIf (!isDarwin && isSopsRecipient) {
    Unit.Description = "Hourly Hetzner Storage Box sync";
    Timer = {
      OnBootSec = "5m";
      OnUnitActiveSec = "1h";
      Persistent = true;
    };
    Install.WantedBy = [ "timers.target" ];
  };
}
// lib.optionalAttrs isDarwin {
  launchd.agents.storage-box-sync = {
    enable = isSopsRecipient;
    config = {
      ProgramArguments = [ (lib.getExe storage-box-sync) ];
      RunAtLoad = true;
      StartInterval = 3600;
    };
  };
}
