# etc — declarative macOS

My personal declarative system configruation.  Desing should be that for the most part you clone this repo, apple to the machine with one command,
and Robert is your father's brother.
Powered by [nix-darwin](https://github.com/nix-darwin/nix-darwin) +
[home-manager](https://github.com/nix-community/home-manager) on top of
[Determinate Nix](https://determinate.systems/).

```
~/etc/
├── flake.nix                  # main file: the two mkHost functions + the roster
├── flake.lock                 # exact pinned versions of everything (committed)
├── hosts/                     # ONE MACHINE = ONE FOLDER
│   ├── playbook/default.nix   #   its facts: username, work, its own casks
│   └── nixos/                 #   a NixOS box
│       ├── default.nix        #     same, plus `system` and `modules`
│       └── hardware.nix       #     disks/bootloader for THIS machine only
├── nix/                       # everything SHARED by all machines
│   ├── darwin/                # system-level (applies to the whole Mac)
│   │   ├── core.nix           #   machine identity, nix/Determinate handshake
│   │   ├── homebrew.nix       #   GUI apps (casks) + App Store apps
│   │   └── macos-defaults.nix #   Finder/Dock/keyboard/etc settings
│   ├── nixos/                 # system-level (applies to the whole NixOS box)
│   │   ├── core.nix           #   machine identity, nix settings, ssh, docker
│   │   └── apps.nix           #   GUI apps (the counterpart to homebrew.nix)
│   └── home/                  # user-level (applies to $USER)
│       ├── default.nix        #   entry point, imports the rest
│       ├── packages.nix       #   every CLI tool & language runtime
│       ├── shell.nix          #   zsh: aliases, env vars, PATH
│       ├── git.nix            #   git + jujutsu
│       ├── programs.nix       #   tools with "home" managed config (starship, fzf, ...)
│       └── dotfiles.nix       #   config files: nix-managed vs live-editable
├── dotfiles/                  # raw config files, referenced from the nix modules.
├── ai/                        # agent instructions (AGENTS.md) + handcrafted skills
├── bin/                       # personal scripts (on PATH)
└── secrets.zsh                # API keys — git-ignored, sourced by zsh
```

Every `.nix` file opens with a comment explaining the nix concept it uses.

## Daily operations

| I want to… | Command |
|---|---|
| Apply config changes to the machine | `drs` (alias for `sudo darwin-rebuild switch --flake ~/etc`) |
| Add a CLI tool | add it to `nix/home/packages.nix` (find names: `nix search nixpkgs <thing>`), `git add`, `drs` |
| Add a GUI app | add the cask to `nix/darwin/homebrew.nix`, `git add`, `drs` |
| Update a brew-managed cask | `brew upgrade --cask <name>` (all: `brew upgrade`) — switches never upgrade casks (`onActivation.upgrade = false`), and many apps self-update anyway |
| Add an alias / env var | edit `nix/home/shell.nix`, `drs`, open a new terminal |
| Update everything | `cd ~/etc && nix flake update && drs` (commit the new `flake.lock`) |
| Undo the last switch | `sudo darwin-rebuild --rollback` |
| See switch history | `darwin-rebuild --list-generations` |
| Free disk space | `sudo ` |

**The golden rule:** nix only sees files git knows about. After creating a new
file, `git add` it or the build fails with a misleading "path does not exist". 
Edited files will be applied with warnings.

### Editing config files

Two flavors, declared in `nix/home/dotfiles.nix`. `dotfiles/` mirrors the
target structure minus the leading dot (`dotfiles/claude/settings.json` →
`~/.claude/settings.json`).

- **Nix-managed** (starship, alacritty, ghostty, zellij, git, jj prefs): edit
  the file in `~/etc/dotfiles/` (or the `.nix` module), then `drs` to apply.
  The live copy is a read-only symlink into the nix store.
- **Live** (claude settings, gh config, opencode.jsonc, zed settings, and
  `ai/AGENTS.md` — the base instructions every agent tool gets): symlinked
  straight back into `~/etc` — edits (by you or by the app itself) apply
  instantly and show up as git diffs here.

Tool runtime homes (`~/.claude`, `~/.codex`, `~/.config/opencode`, …) are
real directories owned by their tools; only the config files above are
linked into them. Identity (git/jj user + email) is machine-local, never
in this repo.

### Agent skills

`~/.agents/skills` is the one skills directory (wired in `nix/home/skills.nix`):

- **Repo skills** live in `ai/skills/<name>/` — each is live-linked into
  `~/.agents/skills`. Edits apply instantly; a NEW skill needs `git add` + `drs`.
- **External skills**: `~/etc/ai/skill-add <org/repo> [skill]` installs into
  `~/.agents/skills` and records the source in `ai/external-skills.list`.

Codex reads `~/.agents/skills` natively. Claude Code only reads
`~/.claude/skills` (flat, per-skill symlinks), so `ai/skill-sync` mirrors the
directory there — automatically on every `drs` and after every `skill-add`.

### Secrets

API keys live in `~/etc/secrets.zsh` (git-ignored, `chmod 600`), sourced by
zsh at startup. Never put a secret in any `.nix` file — everything nix touches
lands world-readable in `/nix/store`.

## Setting up a new machine

1. **macOS basics**: sign in to iCloud/App Store; `xcode-select --install`.
2. **Install Determinate Nix**:
   ```
   curl -fsSL https://install.determinate.systems/nix | sh -s -- install --determinate
   ```
3. **ssh keys**: create/copy a key; add it to GitHub (this repo).
4. **Clone this repo** (location is a hard assumption):
   ```
   git clone git@github.com:jshreynolds/localetc.git ~/etc
   ```
5. **Install Homebrew** (nix-darwin drives it but doesn't install it):
   ```
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```
6. **Declare the machine** — one folder, one line, then commit.

   `hosts/its-hostname/default.nix` (plain data, no `{ pkgs, ... }:` header):
   ```nix
   {
     hostname = "its-hostname";   # scutil --get LocalHostName
     username = "its-username";   # whoami
     work = true;                 # optional; false on a personal machine
     casks = [ ];                 # optional, merged onto the shared
     brews = [ ];                 #  lists in nix/darwin/homebrew.nix
     masApps = { };
     modules = [ ];               # optional: .nix files in THIS folder
   }
   ```
   Then one line in `flake.nix`, under `darwinConfigurations`:
   ```nix
   "its-hostname" = mkDarwinHost (import ./hosts/its-hostname);
   ```
   The attribute name must equal `hostname` — that is what `darwin-rebuild`
   matches on. `git add hosts/its-hostname` or the build won't see it.

   A NixOS box is the same, with `mkNixosHost` under `nixosConfigurations`:
   it takes `system` (`x86_64-linux` / `aarch64-linux`) and `apps` instead of
   `casks`, and always needs its own `hardware.nix` in `modules`.
7. **Create `~/etc/secrets.zsh`** with the API keys (copy from a password
   manager, not from another machine's shell history).
8. **First switch** (quotes matter — zsh eats the `#`):
   ```
   sudo nix run 'nix-darwin/master#darwin-rebuild' -- switch --flake ~/etc
   ```
   - If it refuses over an existing `/etc/zshrc` (or `zshenv`/`bashrc`):
     `sudo mv /etc/zshrc /etc/zshrc.before-nix-darwin` and re-run.
9. **Open a new terminal.** Prompt, aliases, and tools should all be there.
   From now on it's `drs`.
10. Optional manual passes (not scriptable): the checklist at the top of
    `nix/darwin/macos-defaults.nix`, and Safari preferences.

## The Determinate Nix arrangement

Determinate Nix owns the nix installation itself; nix-darwin is told hands-off
(`nix.enable = false` in `core.nix`). Practical consequences:

- nix settings (extra substituters, trusted users) go in
  `/etc/nix/nix.custom.conf` by hand — not in nix-darwin options.
- Upgrade nix itself: `sudo determinate-nixd upgrade`
- Garbage-collect: `sudo nix-collect-garbage`

## Homebrew's remaining job

Homebrew handles only what nixpkgs can't: GUI apps (casks), Mac App Store
apps (via `mas`), and five formulae that aren't packaged in nixpkgs. The full
list lives in `nix/darwin/homebrew.nix` with `cleanup = "zap"` — anything
brew-installed that isn't declared there gets uninstalled on the next `drs`.
So: to try something quickly, `brew install foo` works, but declare it if you
want to keep it around.

## Troubleshooting

- **"path ... does not exist" during build** → you forgot `git add`.
- **A tool resolves to the wrong version** → `which -a <tool>`; nix paths
  (`/etc/profiles/per-user/...`) must come before `/opt/homebrew/bin`.
- **Something broke after an update** → `sudo darwin-rebuild --rollback`,
  then investigate at your liesure.  That's one of the whole points.
- **Home-manager refuses to overwrite a file** → something created a real
  file where it wants a symlink. Move it aside, or check for `*.hm-backup`
  leftovers from the automatic backup.
