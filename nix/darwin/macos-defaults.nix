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
# Ported from the old install/enabled/91-macos-user.sh + 92-macos-additional.sh
# (kept in git history). Some changes only show after logout or a
# `killall Dock` / `killall Finder`.
#
# Manual one-time steps on a new machine (were interactive in the old script):
#   - System Settings → Privacy & Security: grant your terminal Full Disk
#     Access if you want to script Mail/Safari prefs
#   - Keyboard shortcuts / Mission Control preferences
# =============================================================================
{ home, ... }:
{
  system.defaults = {
    # -- global: keyboard, text, panels, scrollbars ----------------------------
    NSGlobalDomain = {
      KeyRepeat = 2;                     # fastest key repeat
      InitialKeyRepeat = 20;             # short delay before repeat kicks in
      ApplePressAndHoldEnabled = false;  # hold a key = repeat it, not accent menu
      AppleKeyboardUIMode = 3;           # full keyboard access (tab through all controls)
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
      location = "${home}/Desktop";
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
      NewWindowTarget = "Desktop";   # new windows open at ~/Desktop
      ShowExternalHardDrivesOnDesktop = true;
      ShowHardDrivesOnDesktop = true;
      ShowMountedServersOnDesktop = true;
      ShowRemovableMediaOnDesktop = true;
    };

    # -- dock --------------------------------------------------------------------
    dock = {
      autohide = true;
      autohide-delay = 0.0;
      autohide-time-modifier = 0.0;
      expose-animation-duration = 0.1;
      launchanim = false;
      mineffect = "scale";
      minimize-to-application = true;
      mouse-over-hilite-stack = true;
      enable-spring-load-actions-on-all-items = true;
      show-process-indicators = true;
      showhidden = true;      # hidden apps get translucent icons
      show-recents = false;
      static-only = true;     # only show RUNNING apps in the dock
      persistent-apps = [ ];  # no pinned apps
      mru-spaces = false;     # don't rearrange Spaces by recent use
    };

    # -- activity monitor -----------------------------------------------------------
    ActivityMonitor = {
      OpenMainWindow = true;
      ShowCategory = 100;     # all processes (old script wrote 0; 100 is the valid "all")
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

      # debug menus
      "com.apple.addressbook".ABShowDebugMenu = true;
      "com.apple.iCal".IncludeDebugMenu = true;
      "com.apple.DiskUtility" = {
        DUDebugMenuEnabled = true;
        advanced-image-options = true;
      };

      # TextEdit: plain text, UTF-8
      "com.apple.TextEdit" = {
        RichText = 0;
        PlainTextEncoding = 4;
        PlainTextEncodingForWrite = 4;
      };

      # App Store & software updates: check daily, auto-install security bits
      "com.apple.appstore" = {
        WebKitDeveloperExtras = true;
        ShowDebugMenu = true;
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

      # Messages: no smart quotes, no spellcheck
      "com.apple.messageshelper.MessageController".SOInputLineSettings = {
        automaticQuoteSubstitutionEnabled = false;
        continuousSpellCheckingEnabled = false;
      };

      # advertising: no personalized ads
      "com.apple.AdLib" = {
        allowIdentifierForAdvertising = false;
        allowApplePersonalizedAdvertising = false;
      };

      # Chrome: native print dialog, expanded
      "com.google.Chrome" = {
        DisablePrintPreview = true;
        PMPrintingExpandedStateForPrint2 = true;
      };

      # Dash: sync settings via ~/Documents/dash
      "com.kapeli.dashdoc" = {
        syncFolderPath = "~/Documents/dash";
        showInDoc = false;
      };
    };
  };
}
