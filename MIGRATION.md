# Migration to nix-darwin + home-manager

Tracking checklist for moving this machine from bash-script bootstrap
(`install/` + `env/` + symlinks) to a declarative nix setup.
The plan: change one layer at a time, verify, then remove the old layer.

Daily command once migrated: `drs` (= `sudo darwin-rebuild switch --flake ~/etc`).

## Phase 0 — write the nix config (no behavior change) ✅

- [x] `flake.nix` + `nix/darwin/*` + `nix/home/*`
- [x] Move `env/enabled/89-ai-model-mgr` → `tools/ai-manager/shell-functions.zsh`
- [x] Move secrets out of `~/.config/mise/config.toml` → git-ignored `~/etc/secrets.zsh`
  - [ ] Rotate `GRANOLA_API_KEY` and `HF_TOKEN` (they sat in plaintext in a non-repo file)
- [x] `nix build ~/etc#darwinConfigurations.mac-nl-josrey-2.system` passes

## Phase 1 — first `darwin-rebuild switch` (additive only) ✅

- [x] First switch (via `sudo ~/etc/result/sw/bin/darwin-rebuild switch --flake ~/etc`)
- [x] Aliases (`gst`, `ll`), `mkcd`, `$EDITOR=nvim` in a fresh zsh
- [x] `which -a git jq node go python3 java` → nix paths (`/etc/profiles/per-user/...`) before `/opt/homebrew`
- [x] Sinch corporate profile line first in generated `~/.zshrc`
- [x] Live symlinks intact: `~/.claude` → repo; `~/.config/gh` → repo
- [x] `*.hm-backup` files reconciled (skills/ and .skill-lock.json moved into `dotfiles/agents/`)
- [ ] Eyeball a real terminal: starship prompt renders, mcfly on ctrl-r

## Phase 2 — soak (a few days of normal work)

- [ ] Anything broken? Fix in nix, or consciously move the tool to `homebrew.brews`
- [ ] Note: brew's old formulae are still installed — harmless, they're shadowed by nix in PATH

## Phase 3 — uninstall the migrated brew formulae

Keep-list (stays in brew, declared in `nix/darwin/homebrew.nix`):
`mas`, `xcode-build-server`, `dagger`, `aiven-client`, `zshdb`.

- [ ] `brew list --formula` → `brew uninstall` everything not on the keep-list
- [ ] `brew autoremove`
- [ ] Re-verify shell + toolchain in a new terminal

## Phase 4 — retire mise

- [ ] `which node go python3 java terraform` all resolve to nix
- [ ] `brew uninstall mise` (if phase 3 didn't already)
- [ ] `rm -rf ~/.config/mise ~/.local/share/mise` (secrets were moved in phase 0)
- [ ] Per-project versions from now on: flake devshell + direnv (`programs.direnv` is enabled)

## Phase 5 — lock homebrew down

- [ ] Flip `cleanup = "none"` → `"zap"` in `nix/darwin/homebrew.nix`
- [ ] `drs` and READ the activation output — brew will now remove anything not declared

## Phase 6 — delete the old machinery + polish

- [ ] `git rm -r install/ env/ setenv install.sh dotfiles/zshrc dotfiles/gitconfig`
- [ ] Port remaining macOS defaults group-by-group into `nix/darwin/macos-defaults.nix`
      (source: git history of `install/enabled/91-macos-user.sh`; verify each group
      with `defaults read <domain>`; Safari intentionally excluded — see that file)
- [ ] Optional: move nerd-font casks to `fonts.packages` in nix
- [ ] Rewrite `README.md` for the nix workflow
- [ ] Delete this file
