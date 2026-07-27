# =============================================================================
# dotfiles.nix — config files linked into the system.
#
# Convention: dotfiles/ mirrors the target structure minus the leading dot
# (dotfiles/claude/settings.json → ~/.claude/settings.json).
#
# Two flavors:
#
# 1. NIX-MANAGED: the file is copied into the read-only /nix/store and
#    symlinked into place. Edit the file in this repo, then `drs` to apply.
#    Right for configs only *you* write and the app only *reads*.
#
# 2. LIVE SYMLINKS (mkOutOfStoreSymlink): the symlink points straight back
#    into ~/etc, NOT the store. Edits apply instantly, and the app itself
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
{ config, lib, pkgs, ... }:
let
  etc = "${config.home.homeDirectory}/etc";
  live = config.lib.file.mkOutOfStoreSymlink;
in
{
  # ---- nix-managed (edit in repo → drs) -------------------------------------
  xdg.configFile."alacritty".source = ../../dotfiles/config/alacritty;
  xdg.configFile."ghostty".source = ../../dotfiles/config/ghostty;
  xdg.configFile."zellij".source = ../../dotfiles/config/zellij;
  xdg.configFile."cheat".source = ../../dotfiles/config/cheat;
  # (starship → programs.nix; git → git.nix)

  # ---- agent base instructions (one source, many names) ----------------------
  home.file.".claude/CLAUDE.md".source = live "${etc}/ai/AGENTS.md";
  home.file.".codex/AGENTS.md".source = live "${etc}/ai/AGENTS.md";
  home.file.".agents/AGENTS.md".source = live "${etc}/ai/AGENTS.md";
  # (XP.md merged into the `codemode` skill; skills are wired in skills.nix)

  # ---- live tool configs (apps write through these) --------------------------
  # Only the config FILE is linked — the surrounding directory stays real so
  # tool-written state (gh's hosts.yml auth token, zed's themes, opencode's
  # node_modules) never lands in this repo.
  xdg.configFile."gh/config.yml".source = live "${etc}/dotfiles/config/gh/config.yml";
  xdg.configFile."opencode/opencode.jsonc".source =
    live "${etc}/dotfiles/config/opencode/opencode.jsonc";
  xdg.configFile."zed/settings.json".source = live "${etc}/dotfiles/config/zed/settings.json";

  # Claude Code writes `model` back on every /model switch — a live link keeps
  # that working and lets git show the drift (rest of ~/.claude stays real).
  home.file.".claude/settings.json".source = live "${etc}/dotfiles/claude/settings.json";

  # Status-line script referenced by settings.json's statusLine.command. Live
  # link so the executable bit on the repo file carries through and edits apply
  # instantly (Claude only executes it, never writes it).
  home.file.".claude/statusline.sh".source = live "${etc}/dotfiles/claude/statusline.sh";

  # Kdenlive keeps custom keyboard shortcuts in the <ActionProperties> block of
  # its kxmlgui rc; the rest of that file (menu/toolbar tree, version=) churns on
  # every app upgrade, so we don't track it. Instead, splice only the tracked
  # shortcuts block into the live rc on each `drs`. Skips when Kdenlive is running
  # (it rewrites the whole rc on quit, discarding our edit). Atomic temp+mv.
  home.activation.kdenliveShortcuts =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      rc="$HOME/Library/Application Support/kxmlgui5/kdenlive/kdenliveui.rc"
      src="${etc}/dotfiles/kdenlive/kdenlive-shortcuts.xml"
      if [ ! -f "$rc" ]; then
        echo "kdenlive: no kdenliveui.rc yet — skip shortcut sync"
      elif ${pkgs.procps}/bin/pgrep -qi kdenlive >/dev/null 2>&1; then
        echo "kdenlive: running — skip shortcut sync (it rewrites the rc on quit)"
      else
        tmp="$(mktemp)"
        ${pkgs.gawk}/bin/awk -v blk="$src" '
          /<ActionProperties/ { skip=1 }
          skip { if (/<\/ActionProperties>/) skip=0; next }
          /<\/kpartgui>/ { while ((getline l < blk) > 0) print l; print; next }
          { print }
        ' "$rc" > "$tmp" && mv "$tmp" "$rc" \
          && echo "kdenlive: synced shortcuts into kdenliveui.rc"
      fi
    '';
}
