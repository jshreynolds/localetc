# =============================================================================
# macos-defaults.nix — macOS system settings (`defaults write`, declaratively).
#
# nix-darwin exposes common settings as typed options under `system.defaults.*`
# (browse them: https://nix-darwin.github.io/nix-darwin/manual/). Anything it
# doesn't know gets a raw escape hatch: `system.defaults.CustomUserPreferences`.
#
# MIGRATION NOTE: the old install/enabled/91-macos-user.sh holds ~140 settings.
# They are being ported here group-by-group (MIGRATION.md phase 6) — a starter
# set is below. Verify a group with `defaults read <domain>` after switching.
# Some changes only show after logout or `killall Dock` / `killall Finder`.
#
# Deliberately NOT ported: Safari settings. Safari is sandboxed on modern
# macOS — terminal writes to com.apple.Safari need Full Disk Access and often
# silently do nothing. Configure Safari by hand (old script kept in git
# history: install/enabled/91-macos-user.sh, "Safari & WebKit" section).
# =============================================================================
{ ... }:
{
  system.defaults = {
    # -- keyboard ------------------------------------------------------------
    NSGlobalDomain = {
      KeyRepeat = 2;                     # fastest key repeat
      InitialKeyRepeat = 20;             # short delay before repeat kicks in
      ApplePressAndHoldEnabled = false;  # hold a key = repeat it, not accent menu
      AppleShowAllExtensions = true;
    };

    # -- trackpad --------------------------------------------------------------
    trackpad.Clicking = true; # tap to click

    # -- screenshots -----------------------------------------------------------
    screencapture = {
      location = "/Users/josrey/Desktop";
      type = "png";
      disable-shadow = true;
    };

    # -- finder ----------------------------------------------------------------
    finder = {
      AppleShowAllFiles = true; # show hidden files
      ShowStatusBar = true;
      ShowPathbar = true;
    };

    # -- dock ------------------------------------------------------------------
    dock = {
      autohide = true;
      autohide-delay = 0.0;
      autohide-time-modifier = 0.0;
      expose-animation-duration = 0.1;
      show-process-indicators = true;
    };
  };
}
