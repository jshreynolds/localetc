# =============================================================================
# kdenlive.nix — Kdenlive's user-authored config, shared across machines.
#
# Kdenlive has no sync of its own: saved effect stacks and custom keyboard
# shortcuts live as loose files under the platform data dir and are lost on
# reinstall. This module points those locations back at dotfiles/kdenlive so
# they are version-controlled like every other config in this repo.
#
# LIVE symlinks (see dotfiles.nix for the two flavors) — Kdenlive WRITES both
# of these itself, so a read-only /nix/store copy would break it. Saving a new
# effect stack in the app drops the .xml straight into the checkout, where git
# shows it as an untracked file to commit.
#
# DIRECTORIES, not individual files — deliberately unlike dotfiles.nix, which
# links single files to keep app-written state out of the repo. Here that state
# IS the payload:
#   effects/         Kdenlive creates a NEW .xml per saved stack; linking files
#                    one by one would only capture the stacks that already
#                    exist, which defeats the point.
#   kxmlgui5/kdenlive/  holds only kdenliveui.rc. Linking the directory means
#                    Kdenlive's rewrite-on-exit lands inside the checkout even
#                    if it writes atomically (temp file + rename), which would
#                    replace a file-level symlink with a regular file.
# Neither directory holds caches or session state — those are under
# ~/.cache/kdenlive (macOS: ~/Library/Caches/kdenlive) and stay out of here.
#
# kdenliveui.rc also carries toolbar/menu layout and a `version` attribute that
# KXMLGUI reconciles against the installed Kdenlive. Sharing it across machines
# therefore shares the whole UI layout, not just the <ActionProperties>
# shortcut block — fine while the machines run comparable versions.
#
# NOT linked: profiles/ (custom project profiles), transitions/, titles/. Add
# them here the same way if they ever hold something worth keeping.
#
# Kdenlive itself is installed per platform, not here: a homebrew cask in
# nix/system/darwin/homebrew.nix, kdePackages.kdenlive in nix/system/linux/apps.nix.
# =============================================================================
{
  config,
  repo,
  isDarwin,
  ...
}:
let
  live = config.lib.file.mkOutOfStoreSymlink;
  # Kdenlive follows QStandardPaths::AppDataLocation, which differs per OS.
  dataDir = if isDarwin then "Library/Application Support" else ".local/share";
in
{
  home.file."${dataDir}/kdenlive/effects".source = live "${repo}/dotfiles/kdenlive/effects";
  home.file."${dataDir}/kxmlgui5/kdenlive".source = live "${repo}/dotfiles/kdenlive/kxmlgui5";
}
