# =============================================================================
# git.nix — git and jujutsu, fully nix-managed.
#
# programs.git writes ~/.config/git/config (git's XDG location); Note: NO global user identity is
# set here, on purpose — identity stays per-repo, as before.
# =============================================================================
{ ... }:
{
  programs.git = {
    enable = true;
    lfs.enable = true;

    # `settings` maps 1:1 onto git config sections → ~/.config/git/config
    settings = {
      alias = {
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
    # Preferences only — user identity deliberately does NOT live in this
    # repo (same policy as git above). Set it machine-locally in
    # ~/.config/jj/conf.d/user.toml, which jj loads alongside this config.
    settings = {
      ui.default-command = "log";
    };
  };
}
