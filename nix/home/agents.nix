# =============================================================================
# agents.nix — agent skills + agent specs: one canonical home, every tool reads it.
#
# ~/.agents/skills is THE skills directory (the cross-tool "agents standard"):
#   - repo skills (ai/skills/<name>) are live-linked into it below. readDir
#     enumerates them at eval time, so there is no list to maintain — a new
#     skill is: create the directory, `git add`, rebuild. Edits to an existing
#     skill apply instantly (live links, no rebuild).
#   - external skills are installed next to them by ai/skill-add
#     (`npx skills add -g` targets ~/.agents/skills already).
#   - external skill REPOS (e.g. work's mgmt_agent_skills) are linked in by
#     ai/skill-sync at activation time, not here: a rebuild evaluates the flake
#     purely, so nix can't readDir outside this repo — and activation-time
#     linking means a missing repo just warns instead of failing the build.
#
# Who reads what (verified against docs + codex source, 2026-07):
#   - codex reads ~/.agents/skills natively — nothing to wire.
#   - claude code only reads ~/.claude/skills, flat, one symlink per skill
#     (a whole-dir symlink breaks: claude writes .system metadata through it).
#     ai/skill-sync mirrors ~/.agents/skills there — on every activation
#     (hook below) and after every skill-add.
#
# Claude Code subagents (ai/agents/<name>.md) are a separate, simpler case:
# each is a single markdown file (frontmatter + prompt), read directly from
# ~/.claude/agents/*.md — there's no cross-tool standard location to funnel
# through and no directory-metadata problem, so a direct live-link per file
# is enough. No mirroring step needed.
# =============================================================================
{
  config,
  lib,
  repo,
  work,
  ...
}:
let
  live = config.lib.file.mkOutOfStoreSymlink;
  repoSkills = lib.filterAttrs (_: type: type == "directory") (builtins.readDir ../../ai/skills);
  repoAgents = lib.filterAttrs (name: type: type == "regular" && lib.hasSuffix ".md" name) (
    builtins.readDir ../../ai/agents
  );
  # external skill repos, linked by skill-sync at activation (see header).
  # Work-only: a personal machine has no clone of it, and skill-sync would
  # just warn — but not asking for it at all is clearer than a warning.
  skillRepos = lib.optional work "${config.home.homeDirectory}/tech/engineering_mgmt/mgmt_agent_skills";
in
{
  # ~/.agents/skills/<name> → <repo>/ai/skills/<name>, one link per repo skill.
  # The directory itself stays REAL so skill-add can install alongside these.
  home.file = lib.mapAttrs' (
    name: _:
    lib.nameValuePair ".agents/skills/${name}" {
      source = live "${repo}/ai/skills/${name}";
    }
  ) repoSkills;

  # Link external skill repos into ~/.agents/skills, then mirror everything
  # into ~/.claude/skills, once the links above exist.
  home.activation.skillSync = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    run ${repo}/ai/skill-sync ${lib.escapeShellArgs skillRepos}
  '';
}
