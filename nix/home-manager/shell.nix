# =============================================================================
# shell.nix — zsh: aliases, environment variables, PATH, startup snippets.
#
# home-manager generates ~/.zshrc from this file (plus the platform's own
# nix/home-manager/{darwin,linux} additions, which are merged in on top).
#
# Everything here is platform-neutral. The macOS-specific layer — brew's PATH,
# gcloud, /Applications paths, the `drs` alias — is nix/home-manager/darwin/shell.nix.
#
# PATH layering (important):
#   1. nix paths come FIRST — wired in by the /etc/zshrc that nix-darwin (or
#      NixOS) generates
#   2. home.sessionPath entries are APPENDED
#   On macOS /opt/homebrew/bin is appended even later, by hand, so anything
#   still living in brew loses to its nix replacement — see darwin/shell.nix.
#   If brew ever mysteriously wins, check with `which -a <tool>`; the usual
#   suspect is macOS path_helper (/etc/zprofile) reordering login shells.
# =============================================================================
{ repo, ... }:
{
  programs.zsh = {
    enable = true;

    syntaxHighlighting.enable = true;

    shellAliases = {
      # -- navigation -------------------------------------------------------
      ".." = "cd ..";
      "..." = "cd ../..";

      # -- convenience --------------------------------------------------------
      editalias = "nvim ${repo}/nix/home-manager/shell.nix"; # aliases live HERE now
      xml = "xmllint --format -";
      zelliful = "zellij attach --create beautiful";

      # -- nix ----------------------------------------------------------------
      # The rebuild alias is platform-specific: `drs` on macOS
      # (darwin-rebuild), `nrs` on NixOS (nixos-rebuild). See the platform
      # shell modules.

      # -- git ----------------------------------------------------------------
      "ga." = "git add .";
      gcm = "git commit -m";
      gco = "git checkout";
      gd = "git diff";
      gdc = "git diff --cached";
      gpu = "git pull";
      gp = "git push";
      gst = "git status";
      # evaluates the branch name when you RUN it, not at shell startup
      gpsup = "git push -u origin $(git branch --show-current)";
      grs = "git restore -- ";
      grst = "git restore --staged ";

      # -- tools --------------------------------------------------------------
      k = "kubectl";
    };

    # Default order (1000) — the base layer, alongside home-manager's own
    # generated tool integrations. The platform modules position themselves
    # around it with explicit mkOrder; see nix/home-manager/darwin/shell.nix.
    initContent = ''
      setopt extendedglob
      bindkey "^A" beginning-of-line
      bindkey "^E" end-of-line

      # Secrets (git-ignored). API keys must NEVER go into nix config —
      # everything nix manages ends up world-readable in /nix/store.
      [ -f "${repo}/secrets.zsh" ] && source "${repo}/secrets.zsh"
    '';
  };

  # Environment variables, set once per login session.
  # (EDITOR is set by programs.neovim.defaultEditor in programs.nix;
  #  starship's config lives at ~/.config/starship.toml via programs.nix.)
  home.sessionVariables = {
    MANWIDTH = "80";
    MCFLY_RESULTS = "50";

    # opt out of tracking/telemetry
    DOTNET_CLI_TELEMETRY_OPTOUT = "true";
    NEXT_TELEMETRY_DISABLED = "1";

    # java
    MAVEN_OPTS = "--enable-native-access=ALL-UNNAMED";

    # NOTE: no vault path env vars here. The Obsidian skills run from the
    # vault root (cwd) and complain if it isn't one — see ai/skills/*.
  };

  # Extra PATH entries — APPENDED after nix paths (see header comment).
  home.sessionPath = [
    "${repo}/bin"
    "$HOME/.local/bin" # cursor agent CLI et al.
  ];
}
