# =============================================================================
# darwin/shell.nix — the macOS layer of the zsh config.
#
# home-manager merges this into the same ~/.zshrc that nix/home/shell.nix
# generates. Split out because every line below names a path or a command that
# only exists on a Mac.
#
# `work` arrives via extraSpecialArgs (see flake.nix): the corporate profile is
# sourced on work machines only, never on the personal one.
# =============================================================================
{ lib, work, ... }:
{
  programs.zsh = {
    shellAliases = {
      drs = "sudo darwin-rebuild switch --flake ~/etc"; # apply this repo to the machine
      xcrmdd = "rm -v -rf $HOME/Library/Developer/Xcode/DerivedData/*";
    };

    # Startup snippets for ~/.zshrc, positioned with mkOrder — NOT by the
    # `imports` list, because module merge order does not follow it (this block
    # landed ahead of the shared base when left at the default order):
    #   500   corporate profile — before everything else
    #   1000  the shared base in nix/home/shell.nix, and home-manager's own
    #         generated tool integrations (starship, mcfly, direnv)
    #   1050  this block — after all of the above, before zsh-syntax-highlighting
    initContent = lib.mkMerge [
      (lib.mkIf work (
        lib.mkOrder 500 ''
          # Sinch corporate profile — must stay first
          test -e "/Library/Application Support/Sinch/profile.zsh" && \
            source "/Library/Application Support/Sinch/profile.zsh"
        ''
      ))
      (lib.mkOrder 1050 ''
        # brew, APPENDED manually — home.sessionPath entries end up in front
        # of the nix paths, and brew must lose to nix (see shell.nix header)
        export PATH="$PATH:/opt/homebrew/bin"

        # gcloud (installed as a brew cask — see homebrew.nix for why)
        [ -f /opt/homebrew/share/google-cloud-sdk/path.zsh.inc ] && \
          source /opt/homebrew/share/google-cloud-sdk/path.zsh.inc
        [ -f /opt/homebrew/share/google-cloud-sdk/completion.zsh.inc ] && \
          source /opt/homebrew/share/google-cloud-sdk/completion.zsh.inc

        # conda init (anaconda not currently installed; uncomment if it returns)
        # export ANACONDA_HOME=/opt/homebrew/anaconda3
        # [ -x "$ANACONDA_HOME/bin/conda" ] && eval "$("$ANACONDA_HOME/bin/conda" shell.zsh hook)"
      '')
    ];
  };

  home.sessionVariables = {
    RSYNC_RSH = "/usr/bin/ssh"; # the system ssh, not a nix profile copy
    HOMEBREW_NO_ANALYTICS = "1";
  };

  # macOS app bundles that ship a CLI inside them — APPENDED after nix paths.
  #
  # mkAfter, not a bare list: module merge order is not the `imports` order, and
  # without it these landed AHEAD of the shared entries in nix/home/shell.nix.
  # $HOME/etc/bin holds your own scripts and must win over an app bundle.
  home.sessionPath = lib.mkAfter [
    # NOTE: no $HOME/.rd/bin. Rancher Desktop's copies of docker/nerdctl sat
    # ahead of the nix profile and shadowed the declared docker-client, so the
    # binary in use was an undeclared, unpinned artifact — while the engine
    # behind it was colima all along. Container tooling comes from
    # nix/home/packages.nix only.
    "$HOME/.lmstudio/bin" # lm studio CLI (lms)
    "/Applications/Muesli.app/Contents/MacOS"
    "/Applications/Obsidian.app/Contents/MacOS"
    # NOTE: /opt/homebrew/bin is deliberately NOT here — sessionPath entries
    # land in front of the nix paths, and brew must come after nix. It's
    # appended in initContent above instead.
  ];
}
