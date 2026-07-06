# =============================================================================
# macos-defaults.nix — macOS system settings (`defaults write`, declaratively).
#
# Two mechanisms, both applied on every `drs`:
#   1. `system.defaults.<group>.*` — settings nix-darwin knows about: typed,
#      documented, checked at build time.
#      Browse them: https://nix-darwin.github.io/nix-darwin/manual/
#   2. `system.defaults.CustomUserPreferences.<domain>.<key>` — a thin
#      declarative wrapper over raw `defaults write` for everything else.
#
# Some changes only show after logout or a `killall Dock` / `killall Finder`.
#
# NOT managed here — Safari, Contacts, Calendar, and Mail preference domains
# are TCC-protected: `defaults write` to them either fails and ABORTS the
# activation, or silently does nothing. Configure those apps by hand.
#
# Manual one-time steps on a new machine:
#   - System Settings → Privacy & Security: grant your terminal Full Disk
#     Access if you want to script Mail/Safari prefs
#   - Keyboard shortcuts / Mission Control preferences
# =============================================================================
{ home, ... }:
{
  system.defaults = {
    # -- global: keyboard, text, panels, scrollbars ----------------------------
    NSGlobalDomain = {
      KeyRepeat = 2; # fastest key repeat
      InitialKeyRepeat = 20; # short delay before repeat kicks in
      ApplePressAndHoldEnabled = false; # hold a key = repeat it, not accent menu
      AppleKeyboardUIMode = 3; # full keyboard access (tab through all controls)
      AppleShowAllExtensions = true;
      AppleShowScrollBars = "Always";

      # expanded save & print dialogs by default
      NSNavPanelExpandedStateForSaveMode = true;
      NSNavPanelExpandedStateForSaveMode2 = true;
      PMPrintingExpandedStateForPrint = true;
      PMPrintingExpandedStateForPrint2 = true;

      # kill the "smart" text mangling (matters when pasting into terminals)
      NSAutomaticCapitalizationEnabled = false;
      NSAutomaticDashSubstitutionEnabled = false;
      NSAutomaticPeriodSubstitutionEnabled = false;
      NSAutomaticQuoteSubstitutionEnabled = false;
      NSAutomaticSpellingCorrectionEnabled = false;

      "com.apple.mouse.tapBehavior" = 1; # tap to click
      "com.apple.springing.enabled" = true;
      "com.apple.springing.delay" = 0.0; # spring-loaded folders, no delay

      # no-frills: kill window animations, instant dialog resize, dense sidebars
      NSAutomaticWindowAnimationsEnabled = false;
      NSWindowResizeTime = 0.001;
      NSTableViewDefaultSizeMode = 1; # small sidebar icons
    };

    # -- trackpad ----------------------------------------------------------------
    trackpad.Clicking = true; # tap to click

    # -- security -----------------------------------------------------------------
    screensaver = {
      askForPassword = true;
      askForPasswordDelay = 0; # require password immediately after sleep
    };

    # -- screenshots ---------------------------------------------------------------
    screencapture = {
      location = "${home}/Downloads"; # desktop icons are hidden, Desktop would swallow these
      type = "png";
      disable-shadow = true;
    };

    # -- finder ---------------------------------------------------------------------
    finder = {
      AppleShowAllFiles = true; # show hidden files
      ShowStatusBar = true;
      ShowPathbar = true;
      _FXShowPosixPathInTitle = true;
      _FXSortFoldersFirst = true;
      FXEnableExtensionChangeWarning = false;
      FXPreferredViewStyle = "clmv"; # column view by default
      NewWindowTarget = "Home"; # new windows open at ~
      CreateDesktop = false; # fully empty desktop — no icons, ever
    };

    # -- dock --------------------------------------------------------------------
    dock = {
      orientation = "left";
      autohide = true;
      autohide-delay = 0.0;
      autohide-time-modifier = 0.0;
      expose-animation-duration = 0.1;
      launchanim = false;
      mineffect = "scale";
      minimize-to-application = true;
      show-process-indicators = true;
      showhidden = true; # hidden apps get translucent icons
      show-recents = false;
      static-only = true; # only show RUNNING apps in the dock
      persistent-apps = [ ]; # no pinned apps
      mru-spaces = false; # don't rearrange Spaces by recent use

      # hot corners disabled — no accidental mouse-triggered UI
      wvous-tl-corner = 1;
      wvous-tr-corner = 1;
      wvous-bl-corner = 1;
      wvous-br-corner = 1;
    };

    # -- window manager ----------------------------------------------------------
    WindowManager = {
      EnableStandardClickToShowDesktop = false; # clicking wallpaper doesn't hide windows

      # native tiling off — Rectangle owns window tiling; edge-drag snapping
      # from macOS would fight Rectangle's own snap areas
      EnableTilingByEdgeDrag = false;
      EnableTopTilingByEdgeDrag = false;
      EnableTilingOptionAccelerator = false;
      EnableTiledWindowMargins = false; # if native tiling is ever used: no gaps
    };

    # -- activity monitor -----------------------------------------------------------
    ActivityMonitor = {
      OpenMainWindow = true;
      ShowCategory = 100; # all processes
      SortColumn = "CPUUsage";
      SortDirection = 0;
    };

    # -- everything nix-darwin has no typed option for -------------------------------
    CustomUserPreferences = {
      # printing: quit the print app when jobs finish
      "com.apple.print.PrintingPrefs"."Quit When Finished" = true;

      # crash reporter: no dialogs
      "com.apple.CrashReporter".DialogType = "none";

      # help viewer in normal (non-floating) windows
      "com.apple.helpviewer".DevMode = true;

      # locale & units
      NSGlobalDomain = {
        AppleLanguages = [ "en" ];
        AppleLocale = "en_US@currency=USD";
        AppleMeasurementUnits = "Centimeters";
        AppleMetricUnits = true;
        WebKitDeveloperExtras = true; # web inspector in every WebKit view
        NSUseAnimatedFocusRing = false; # no focus-ring animation when tabbing
      };

      # don't litter .DS_Store on network shares and USB drives
      "com.apple.desktopservices" = {
        DSDontWriteNetworkStores = true;
        DSDontWriteUSBStores = true;
      };

      # finder bits without typed options
      "com.apple.finder" = {
        DisableAllAnimations = true;
        WarnOnEmptyTrash = false;
        FXInfoPanesExpanded = {
          General = true;
          OpenWith = true;
          Privileges = true;
        };
      };

      # Time Machine: stop offering every new disk as a backup target
      "com.apple.TimeMachine".DoNotOfferNewDisksForBackup = true;

      # TextEdit: plain text, UTF-8
      "com.apple.TextEdit" = {
        RichText = 0;
        PlainTextEncoding = 4;
        PlainTextEncodingForWrite = 4;
      };

      # App Store & software updates: check daily, auto-install security bits
      "com.apple.appstore" = {
        AutoPlayVideoSetting = "off";
        UserSetAutoPlayVideoSetting = true;
      };
      "com.apple.SoftwareUpdate" = {
        AutomaticCheckEnabled = true;
        ScheduleFrequency = 1;
        AutomaticDownload = 1;
        CriticalUpdateInstall = 1;
        ConfigDataInstall = 1;
      };
      "com.apple.commerce" = {
        AutoUpdate = true;
        AutoUpdateRestartRequired = true;
      };

      # advertising: no personalized ads
      "com.apple.AdLib" = {
        allowIdentifierForAdvertising = false;
        allowApplePersonalizedAdvertising = false;
      };
    };
  };

  # Caps Lock → Escape at the OS level (Rectangle/vim-friendly home-row Escape)
  system.keyboard = {
    enableKeyMapping = true;
    remapCapsLockToEscape = true;
  };
}
