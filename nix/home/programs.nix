# =============================================================================
# programs.nix — tools with first-class home-manager modules.
#
# Nix concept: `programs.X.enable = true` does three things at once —
# installs the package, writes its config file, and wires its shell
# integration into zsh (the `eval "$(X init zsh)"` dance, handled for you).
# =============================================================================
{ ... }:
{
  # prompt (config: dotfiles/config/starship.toml, loaded below so the TOML
  # file stays the source of truth)
  programs.starship = {
    enable = true;
    settings = builtins.fromTOML (builtins.readFile ../../dotfiles/config/starship.toml);
  };

  # smarter cd (z / zi)
  programs.zoxide.enable = true;

  # ctrl-r history search (MCFLY_RESULTS set in shell.nix)
  programs.mcfly.enable = true;

  # per-directory environments — foundation for per-project dev
  # environments (flake devshells)
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true; # caches devshells so entering a project dir is fast
  };

  # fuzzy finder (ctrl-t files, alt-c dirs)
  programs.fzf = {
    enable = true;
    # mcfly owns ctrl-r; disable fzf's competing binding
    historyWidget.command = "";
  };

  # cat with wings
  programs.bat.enable = true;

  programs.delta = {
    enable = true;
    enableGitIntegration = true; # sets core.pager = delta in git config
  };

  # tree explorer + `br` shell function
  programs.broot.enable = true;

  # modern ls. The module provides the aliases: ls, ll (-l), la (-a),
  # lla (-la), lt (--tree), llt (-l --tree). Styling lives in
  # ~/.config/lsd/config.yaml, generated from here.
  programs.lsd = {
    enable = true;
    settings = {
      date = "+%y-%m-%d %H:%M";
      truncate-owner.after = 3;
    };
  };

  # editor; defaultEditor sets $EDITOR=nvim
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    # skip the python/ruby remote-plugin providers (new upstream default;
    # only needed by python/ruby-based nvim plugins)
    withPython3 = false;
    withRuby = false;
  };
}
