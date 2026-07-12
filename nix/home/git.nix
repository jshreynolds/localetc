# =============================================================================
# git.nix — git and jujutsu, fully nix-managed.
#
# programs.git writes ~/.config/git/config (git's XDG location). NO global
# user identity is set here, on purpose — identity stays per-repo.
# =============================================================================
{ pkgs, ... }:
{
  # gpg-agent for gcrypt: pinentry path is pinned to the nix store and
  # regenerated on every `drs`, so it never goes stale (was hardcoded to a
  # dead /opt/homebrew path after the brew→nix migration).
  home.file.".gnupg/gpg-agent.conf".text = ''
    default-cache-ttl 600
    max-cache-ttl 7200
    pinentry-program ${pkgs.pinentry_mac}/bin/pinentry-mac
  '';

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
