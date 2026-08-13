# =============================================================================
# homebrew.nix — GUI apps (casks) and App Store apps, declared in nix.
#
# nix-darwin does NOT install Homebrew — it *drives* the existing install at
# /opt/homebrew by generating a Brewfile and running `brew bundle` on every
# `darwin-rebuild switch`. So: the app *list* is declarative and lives here,
# while brew remains the installer (GUI apps from nixpkgs are unreliable on
# macOS; casks are the pragmatic standard).
#
# This file holds the SHARED lists every machine gets. Host-specific apps are
# declared per machine in hosts/<hostname>/default.nix (casks/brews/masApps)
# and arrive here as hostCasks/hostBrews/hostMasApps to be merged in.
#
# The NixOS side of the same job is nix/system/linux/apps.nix — same role (the shared
# GUI app list, plus per-host extras), different mechanism (plain nixpkgs, no
# brew). It records which casks below have no Linux equivalent, and why.
# =============================================================================
{
  hostCasks ? [ ],
  hostBrews ? [ ],
  hostMasApps ? { },
  ...
}:
{
  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = false; # don't `brew update` on every switch — do it deliberately
      upgrade = false; # don't upgrade casks on every switch either
      # What to do with brew packages NOT listed in this file:
      #   "none"      = leave them alone
      #   "uninstall" = remove them
      #   "zap"       = remove them AND purge their config/caches
      # "zap" means brew can never drift from this file: `brew install foo`
      # works for a quick experiment, but declare it here or the next drs
      # removes it. Dependencies of declared items are kept automatically.
      cleanup = "zap";
    };

    # CLI formulae that intentionally STAY in brew (everything else comes from
    # nixpkgs — see nix/home-manager/packages.nix):
    brews = [
      "mas" # Mac App Store CLI — required by masApps below; darwin-only in nixpkgs
      "container" # Apple container runtime; darwin-only in nixpkgs, and a system
      # VM runtime rather than a user tool — brew is the right installer
      # Not in nixpkgs at all (checked against the pinned rev):
      "xcode-build-server"
      "dagger"
      "aiven-client"
      "zshdb"
    ]
    ++ hostBrews;

    casks = [
      # -- daily drivers --------------------------------------------------
      "1password"
      "alacritty"
      "obsidian"
      "rectangle"
      "slack"
      "zoom"
      # -- browsers -------------------------------------------------------
      "brave-browser"
      "chromium"
      "firefox"
      "google-chrome"
      "microsoft-edge"
      # -- editors & IDEs ---------------------------------------------------
      "zed"
      # -- AI ---------------------------------------------------------------
      # Only the GUI apps are here. The AI *CLIs* (claude-code, codex,
      # copilot-cli) come from nixpkgs via nix/home-manager/packages.nix now — one
      # declaration for every machine instead of a cask here and a package in
      # nix/system/linux/apps.nix.
      "chatgpt"
      "claude"
      "comfy"
      "lm-studio"
      "ollama-app"
      # -- dev tools ----------------------------------------------------------
      "gcloud-cli" # cask (not nixpkgs): `gcloud components` self-updates, which the read-only nix store can't allow
      "openlens"
      # -- misc --------------------------------------------------------------
      "adobe-creative-cloud"
      "discord"
      "dropbox"
      "kdenlive"
      "miro"
      "muesli"
    ]
    ++ hostCasks;

    # Mac App Store apps. Requires being signed in to the App Store, and can
    # only install apps this Apple ID has "purchased" before. If mas acts up
    # after a macOS update, treat failures here as non-fatal.
    masApps = {
      "GoodNotes" = 1444383602;
      "GrandPerspective" = 1111570163;
      "focus bug" = 6746090405;
      "Xcode" = 497799835;
    }
    // hostMasApps;
  };
}
