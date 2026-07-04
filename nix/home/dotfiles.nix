# =============================================================================
# dotfiles.nix — config files, in two deliberate flavors:
#
# 1. NIX-MANAGED: the file is copied into the read-only /nix/store and
#    symlinked into place. Edit the file in this repo, then `drs` to apply.
#    Right for configs only *you* write and the app only *reads*.
#
# 2. LIVE SYMLINKS (mkOutOfStoreSymlink): the symlink points straight back
#    into ~/etc, NOT the store. Edits apply instantly, and — crucially — the
#    app itself can write to the file. Required for self-modifying configs
#    (Claude Code rewrites settings.json; gh writes hosts.yml). The cost:
#    nix can't guarantee their content — git shows the drift instead.
# =============================================================================
{ config, ... }:
let
  # Absolute repo path AS A STRING. A nix path literal (../../dotfiles/claude)
  # would be copied into the read-only store — exactly what live configs must avoid.
  etc = "${config.home.homeDirectory}/etc";
  ai = "${config.home.homeDirectory}/ai"; # external AI/skills area (not in this repo)
  live = config.lib.file.mkOutOfStoreSymlink;
in
{
  # ---- nix-managed (edit in repo → drs) -------------------------------------
  xdg.configFile."alacritty".source = ../../dotfiles/config/alacritty;
  xdg.configFile."ghostty".source = ../../dotfiles/config/ghostty;
  xdg.configFile."zellij".source = ../../dotfiles/config/zellij;
  xdg.configFile."cheat".source = ../../dotfiles/config/cheat;
  # (starship → programs.nix; git + jj → git.nix)

  # ---- live symlinks (apps rewrite these themselves) -------------------------
  home.file.".claude".source = live "${etc}/dotfiles/claude"; # Claude Code rewrites settings.json
  # ~/.agents is a REAL directory owned by external skills tooling —
  # ~/.agents/skills holds installed skills (handcrafted ones symlink to
  # ~/ai/skills). The guideline files live in ~/ai too; nix just guarantees
  # the pointers exist (CLAUDE.md imports ~/.agents/AGENTS.md):
  home.file.".agents/AGENTS.md".source = live "${ai}/AGENTS.md";
  home.file.".agents/XP.md".source = live "${ai}/XP.md";
  home.file.".codex".source = live "${etc}/dotfiles/codex";
  home.file.".cursorrules".source = live "${etc}/dotfiles/cursorrules";
  home.file.".docker".source = live "${etc}/dotfiles/docker";
  xdg.configFile."gh".source = live "${etc}/dotfiles/config/gh"; # gh writes hosts.yml
  xdg.configFile."opencode".source = live "${etc}/dotfiles/config/opencode";
}
