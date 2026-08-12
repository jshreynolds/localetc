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
# CREDENTIALS ARE NOT IN THIS REPO. The connection details are read at runtime
# from ~/.config/storage-box/env, which you create once per machine, chmod 600:
#
#   RCLONE_CONFIG_BOX_TYPE=sftp
#   RCLONE_CONFIG_BOX_HOST=uXXXXXX.your-storagebox.de
#   RCLONE_CONFIG_BOX_USER=uXXXXXX
#   RCLONE_CONFIG_BOX_PORT=23
#   RCLONE_CONFIG_BOX_KEY_FILE=/home/you/.ssh/id_ed25519
#   RCLONE_CONFIG_BOX_KNOWN_HOSTS_FILE=/home/you/.ssh/known_hosts
#   STORAGE_BOX_ROOT=/home/sbox
#
# rclone builds the `box:` remote from those RCLONE_CONFIG_* variables, so no
# rclone.conf is needed. That file is the seam for the sops/agenix work: once
# secrets are encrypted in git, they render to this same path and nothing here
# changes.
#
# Also one-time, per machine:
#   ssh-copy-id -p 23 uXXXXXX@uXXXXXX.your-storagebox.de   (upload the pubkey)
#   ssh-keyscan -p 23 uXXXXXX.your-storagebox.de >> ~/.ssh/known_hosts
# =============================================================================
{
  pkgs,
  lib,
  config,
  isDarwin,
  ...
}:
let
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
        echo "storage-box: no credentials at $env_file (see nix/home/storage-box.nix)" >&2
        exit 1
      fi

      set -a
      # shellcheck disable=SC1090
      . "$env_file"
      set +a

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

  # Linux: a plain oneshot on a timer. Persistent catches up after the machine
  # has been off, which is the normal case here.
  systemd.user.services.storage-box-sync = lib.mkIf (!isDarwin) {
    Unit.Description = "Sync ~/sbox with the Hetzner Storage Box";
    Service = {
      Type = "oneshot";
      ExecStart = lib.getExe storage-box-sync;
    };
  };

  systemd.user.timers.storage-box-sync = lib.mkIf (!isDarwin) {
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
    enable = true;
    config = {
      ProgramArguments = [ (lib.getExe storage-box-sync) ];
      RunAtLoad = true;
      StartInterval = 3600;
    };
  };
}
