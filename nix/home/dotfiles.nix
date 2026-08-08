# =============================================================================
# dotfiles.nix — config files linked into the system.
#
# Convention: dotfiles/ mirrors the target structure minus the leading dot
# (dotfiles/claude/settings.json → ~/.claude/settings.json).
#
# Two flavors:
#
# 1. NIX-MANAGED: the file is copied into the read-only /nix/store and
#    symlinked into place. Edit the file in this repo, then rebuild to apply.
#    Right for configs only *you* write and the app only *reads*.
#
# 2. LIVE SYMLINKS (mkOutOfStoreSymlink): the symlink points straight back
#    into the checkout, NOT the store. Edits apply instantly, and the app itself
#    can write through the link. The cost: nix can't guarantee the content —
#    git shows the drift instead.
#
# Tool runtime homes (~/.claude, ~/.codex, ~/.config/opencode, ~/.agents) are
# REAL directories owned by their tools — session state, caches, and history
# never live in this repo. Nix only places the few config pointers below
# inside them.
#
# ai/AGENTS.md is the single source of base instructions for ALL agents;
# each tool's expected filename is just another pointer to it.
# =============================================================================
{ config, repo, ... }:
let
  live = config.lib.file.mkOutOfStoreSymlink;
in
{
  # ---- nix-managed (edit in repo → rebuild) ---------------------------------
  xdg.configFile."alacritty".source = ../../dotfiles/config/alacritty;
  xdg.configFile."ghostty".source = ../../dotfiles/config/ghostty;
  xdg.configFile."zellij".source = ../../dotfiles/config/zellij;
  xdg.configFile."cheat".source = ../../dotfiles/config/cheat;
  # (starship → programs.nix; git → git.nix)

  # ---- agent base instructions (one source, many names) ----------------------
  home.file.".claude/CLAUDE.md".source = live "${repo}/ai/AGENTS.md";
  home.file.".codex/AGENTS.md".source = live "${repo}/ai/AGENTS.md";
  home.file.".agents/AGENTS.md".source = live "${repo}/ai/AGENTS.md";
  # (XP.md merged into the `codemode` skill; skills are wired in skills.nix)

  # ---- live tool configs (apps write through these) --------------------------
  # Only the config FILE is linked — the surrounding directory stays real so
  # tool-written state (gh's hosts.yml auth token, zed's themes, opencode's
  # node_modules) never lands in this repo.
  xdg.configFile."gh/config.yml".source = live "${repo}/dotfiles/config/gh/config.yml";
  xdg.configFile."opencode/opencode.jsonc".source =
    live "${repo}/dotfiles/config/opencode/opencode.jsonc";
  xdg.configFile."zed/settings.json".source = live "${repo}/dotfiles/config/zed/settings.json";

  # Claude writes through this (e.g. `/model` saving a default), so it needs
  # the live flavor, not a read-only store copy.
  home.file.".claude/settings.json".source = live "${repo}/dotfiles/claude/settings.json";

  # Status-line script referenced by settings.json's statusLine.command. Live
  # link so the executable bit on the repo file carries through and edits apply
  # instantly (Claude only executes it, never writes it).
  home.file.".claude/statusline.sh".source = live "${repo}/dotfiles/claude/statusline.sh";
}
