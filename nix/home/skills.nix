# =============================================================================
# skills.nix — agent skills: one canonical home, every tool reads it.
#
# ~/.agents/skills is THE skills directory (the cross-tool "agents standard"):
#   - repo skills (ai/skills/<name>) are live-linked into it below. readDir
#     enumerates them at eval time, so there is no list to maintain — a new
#     skill is: create the directory, `git add`, `drs`. Edits to an existing
#     skill apply instantly (live links, no rebuild).
#   - external skills are installed next to them by ai/skill-add
#     (`npx skills add -g` targets ~/.agents/skills already).
#
# Who reads what (verified against docs + codex source, 2026-07):
#   - codex reads ~/.agents/skills natively — nothing to wire.
#   - claude code only reads ~/.claude/skills, flat, one symlink per skill
#     (a whole-dir symlink breaks: claude writes .system metadata through it).
#     ai/skill-sync mirrors ~/.agents/skills there — on every activation
#     (hook below) and after every skill-add.
# =============================================================================
{ config, lib, ... }:
let
  etc = "${config.home.homeDirectory}/etc";
  live = config.lib.file.mkOutOfStoreSymlink;
  repoSkills = lib.filterAttrs (_: type: type == "directory") (builtins.readDir ../../ai/skills);
in
{
  # ~/.agents/skills/<name> → ~/etc/ai/skills/<name>, one link per repo skill.
  # The directory itself stays REAL so skill-add can install alongside these.
  home.file = lib.mapAttrs' (
    name: _:
    lib.nameValuePair ".agents/skills/${name}" {
      source = live "${etc}/ai/skills/${name}";
    }
  ) repoSkills;

  # Mirror into ~/.claude/skills once the links above exist.
  home.activation.skillSync = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    run ${etc}/ai/skill-sync
  '';
}
