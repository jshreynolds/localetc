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
# declared per machine in flake.nix (mkHost's casks/brews/masApps) and arrive
# here as hostCasks/hostBrews/hostMasApps to be merged in.
# =============================================================================
{ hostCasks ? [ ], hostBrews ? [ ], hostMasApps ? { }, ... }:
{
  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = false; # don't `brew update` on every switch — do it deliberately
      upgrade = false;    # don't upgrade casks on every switch either
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
    # nixpkgs — see nix/home/packages.nix):
    brews = [
      "mas"                # Mac App Store CLI — required by masApps below
      "xcode-build-server" # not packaged in nixpkgs
      "dagger"             # not packaged in nixpkgs
      "aiven-client"       # not packaged in nixpkgs
      "zshdb"              # not packaged in nixpkgs (bashdb is; zshdb isn't)
    ] ++ hostBrews;

    casks = [
      # -- daily drivers --------------------------------------------------
      "1password"
      "alacritty"
      "ghostty"
      "obsidian"
      "rectangle"
      "slack"
      "zoom"
      # -- browsers -------------------------------------------------------
      "brave-browser"
      "firefox"
      "google-chrome"
      "microsoft-edge"
      "orion"
      # -- editors & IDEs ---------------------------------------------------
      "visual-studio-code"
      "zed"
      # -- AI ---------------------------------------------------------------
      "chatgpt"
      "claude"
      "claude-code@latest"
      "codex"
      "comfy"
      "copilot-cli"
      "granola"
      "kitlangton-hex"
      "lm-studio"
      "ollama-app"
      # -- dev tools ----------------------------------------------------------
      "dash"
      "gcloud-cli" # cask (not nixpkgs): `gcloud components` self-updates, which the read-only nix store can't allow
      "insomnia"
      "openlens"
      # -- misc --------------------------------------------------------------
      "microsoft-excel"
      "miro"
      "sf-symbols"
    ] ++ hostCasks;

    # Mac App Store apps. Requires being signed in to the App Store, and can
    # only install apps this Apple ID has "purchased" before. If mas acts up
    # after a macOS update, treat failures here as non-fatal.
    masApps = {
      "GoodNotes" = 1444383602;
      "GrandPerspective" = 1111570163;
    } // hostMasApps;
  };
}
