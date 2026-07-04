# =============================================================================
# git.nix — git and jujutsu, fully nix-managed.
#
# programs.git writes ~/.config/git/config (git's XDG location); the old
# hand-written dotfiles/gitconfig is retired. Note: NO global user identity is
# set here, on purpose — identity stays per-repo, as before.
# =============================================================================
{ ... }:
{
  programs.git = {
    enable = true;
    lfs.enable = true; # replaces the git-lfs brew formula + `git lfs install`

    # delta (fancy diff pager) is intentionally NOT enabled — it wasn't
    # configured before either. To try it:  delta.enable = true;

    # global ignore patterns → ~/.config/git/ignore
    ignores = [ "**/.claude/settings.local.json" ];

    # `settings` maps 1:1 onto git config sections → ~/.config/git/config
    settings = {
      alias = {
        # curl a .gitignore template, e.g.:  git ignore python,macos
        ignore = "!gi() { curl -sL https://www.toptal.com/developers/gitignore/api/$@ ;}; gi";
        # difftastic views: log with patches / latest commit / diff
        dl = "-c diff.external=difft log -p --ext-diff";
        ds = "-c diff.external=difft show --ext-diff";
        dft = "-c diff.external=difft diff";
      };
      init.defaultBranch = "main";
      gcrypt.gpg-args = "--trust-model always";
    };
  };

  programs.jujutsu = {
    enable = true;
    # jj's config, straight from the old dotfiles/config/jj/config.toml
    settings = {
      user = {
        name = "Joshua Reynolds";
        email = "jreynolds@electrichand.com";
      };
      ui.default-command = "log";
    };
  };
}
