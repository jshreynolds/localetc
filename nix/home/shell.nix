# =============================================================================
# shell.nix — zsh: aliases, environment variables, PATH, startup snippets.
#
# home-manager generates ~/.zshrc from this file. #
#
# PATH layering (important):
#   1. nix paths come FIRST — wired in by nix-darwin's /etc/zshrc
#   2. home.sessionPath entries are APPENDED — including /opt/homebrew/bin,
#      so anything still living in brew loses to its nix replacement.
#   If brew ever mysteriously wins, check with `which -a <tool>`; the usual
#   suspect is macOS path_helper (/etc/zprofile) reordering login shells.
# =============================================================================
{ lib, ... }:
{
  programs.zsh = {
    enable = true;

    syntaxHighlighting.enable = true;

    shellAliases = {
      # -- navigation -------------------------------------------------------
      ".." = "cd ..";
      "..." = "cd ../..";
      "...." = "cd ../../..";

      # -- convenience --------------------------------------------------------
      editalias = "nvim ~/etc/nix/home/shell.nix"; # aliases live HERE now
      xml = "xmllint --format -";
      xcrmdd = "rm -v -rf $HOME/Library/Developer/Xcode/DerivedData/*";
      zelliful = "zellij attach --create beautiful";

      # -- nix ----------------------------------------------------------------
      drs = "sudo darwin-rebuild switch --flake ~/etc"; # apply this repo to the machine

      # -- git ----------------------------------------------------------------
      "ga." = "git add .";
      gcm = "git commit -m";
      gco = "git checkout";
      gd = "git diff";
      gdc = "git diff --cached";
      gpu = "git pull";
      gp = "git push";
      gst = "git status";
      # single quotes in the old alias file meant this evaluated at shell
      # startup (a bug); here it correctly evaluates when you run it
      gpsup = "git push -u origin $(git branch --show-current)";
      grs = "git restore -- ";
      grst = "git restore --staged ";

      # -- tools --------------------------------------------------------------
      uvtest = "uv run pytest";
      k = "kubectl";
    };

    # Startup snippets for ~/.zshrc. mkOrder controls placement: 500 ≈ "very
    # early" — the corporate profile must load before everything else, exactly
    # as it did at the top of the old zshrc. (Only mkOrder in this repo.)
    initContent = lib.mkMerge [
      (lib.mkOrder 500 ''
        # Sinch corporate profile — must stay first
        test -e "/Library/Application Support/Sinch/profile.zsh" && \
          source "/Library/Application Support/Sinch/profile.zsh"
      '')
      ''
        setopt extendedglob
        bindkey "^A" beginning-of-line
        bindkey "^E" end-of-line

        mkcd () {
          mkdir "$1"
          cd "$1"
        }

        # Secrets (git-ignored). API keys must NEVER go into nix config —
        # everything nix manages ends up world-readable in /nix/store.
        [ -f "$HOME/etc/secrets.zsh" ] && source "$HOME/etc/secrets.zsh"

        # brew, APPENDED manually — home.sessionPath entries end up in front
        # of the nix paths, and brew must lose to nix (see header comment)
        export PATH="$PATH:/opt/homebrew/bin"

        # gcloud (installed as a brew cask — see homebrew.nix for why)
        [ -f /opt/homebrew/share/google-cloud-sdk/path.zsh.inc ] && \
          source /opt/homebrew/share/google-cloud-sdk/path.zsh.inc
        [ -f /opt/homebrew/share/google-cloud-sdk/completion.zsh.inc ] && \
          source /opt/homebrew/share/google-cloud-sdk/completion.zsh.inc

        # conda init (anaconda not currently installed; uncomment if it returns)
        # export ANACONDA_HOME=/opt/homebrew/anaconda3
        # [ -x "$ANACONDA_HOME/bin/conda" ] && eval "$("$ANACONDA_HOME/bin/conda" shell.zsh hook)"
      ''
    ];
  };

  # Environment variables, set once per login session.
  # (EDITOR is set by programs.neovim.defaultEditor in programs.nix.
  #  STARSHIP_CONFIG is gone — starship's config now lives at the default
  #  ~/.config/starship.toml, managed in programs.nix.)
  home.sessionVariables = {
    MANWIDTH = "80";
    RSYNC_RSH = "/usr/bin/ssh";
    MCFLY_RESULTS = "50";

    # opt out of tracking/telemetry
    DOTNET_CLI_TELEMETRY_OPTOUT = "true";
    NEXT_TELEMETRY_DISABLED = "1";

    # java
    MAVEN_OPTS = "--enable-native-access=ALL-UNNAMED";

    # obsidian vaults & agentic knowledge base
    WORKSIDIAN = "$HOME/worksidian";
    OBSIDIAN = "$HOME/Documents/vault";
  };

  # Extra PATH entries — APPENDED after nix paths (see header comment).
  home.sessionPath = [
    "$HOME/bin"
    "$HOME/bin/scripts"
    "$HOME/etc/bin"
    "$HOME/.local/bin"                        # cursor agent CLI et al.
    "$HOME/.rd/bin"                           # rancher desktop (harmless if absent)
    "$HOME/.lmstudio/bin"                     # lm studio CLI (lms)
    "/Applications/Obsidian.app/Contents/MacOS"
    # NOTE: /opt/homebrew/bin is deliberately NOT here — sessionPath entries
    # land in front of the nix paths, and brew must come after nix. It's
    # appended in initContent above instead.
  ];
}
