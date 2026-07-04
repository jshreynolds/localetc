# etc — declarative macOS

This repo IS the machine. One `flake.nix` plus a handful of small nix modules
declare everything: CLI tools, GUI apps, shell config, dotfiles, and macOS
settings. Apply the repo to the machine with one command; roll back with one
command. Powered by [nix-darwin](https://github.com/nix-darwin/nix-darwin) +
[home-manager](https://github.com/nix-community/home-manager) on top of
[Determinate Nix](https://determinate.systems/).

```
~/etc/
├── flake.nix                  # front door: inputs + one mkHost line per machine
├── flake.lock                 # exact pinned versions of everything (committed)
├── nix/
│   ├── darwin/                # system-level (applies to the whole Mac)
│   │   ├── core.nix           #   machine identity, nix/Determinate handshake
│   │   ├── homebrew.nix       #   GUI apps (casks) + App Store apps, declared
│   │   └── macos-defaults.nix #   Finder/Dock/keyboard/etc settings
│   └── home/                  # user-level (applies to $USER)
│       ├── default.nix        #   entry point, imports the rest
│       ├── packages.nix       #   every CLI tool & language runtime
│       ├── shell.nix          #   zsh: aliases, env vars, PATH
│       ├── git.nix            #   git + jujutsu
│       ├── programs.nix       #   tools with managed config (starship, fzf, ...)
│       └── dotfiles.nix       #   config files: nix-managed vs live-editable
├── dotfiles/                  # raw config files, referenced from the nix modules
├── ai/                        # agent instructions (AGENTS.md) + handcrafted skills
├── bin/                       # personal scripts (on PATH)
└── secrets.zsh                # API keys — git-ignored, sourced by zsh
```

Every `.nix` file opens with a comment explaining the nix concept it uses.
Read them in the order listed above and you've had the tour.

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
| Free disk space | `sudo determinate-nixd gc` |

**The golden rule:** nix only sees files git knows about. After creating a new
file, `git add` it or the build fails with a misleading "path does not exist".

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
6. **Declare the machine** in `flake.nix` — one block, then commit:
   ```nix
   "its-hostname" = mkHost {
     hostname = "its-hostname";   # scutil --get LocalHostName
     username = "its-username";   # whoami
     casks = [ ];                 # apps only this machine gets (optional,
     masApps = { };               #  merged onto the shared homebrew.nix lists)
   };
   ```
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
- Garbage-collect: `sudo determinate-nixd gc`

## Homebrew's remaining job

Homebrew handles only what nixpkgs can't: GUI apps (casks), Mac App Store
apps (via `mas`), and five formulae that aren't packaged in nixpkgs. The full
list lives in `nix/darwin/homebrew.nix` with `cleanup = "zap"` — anything
brew-installed that isn't declared there gets uninstalled on the next `drs`.
So: to try something quickly, `brew install foo` works, but declare it or
lose it.

## Troubleshooting

- **"path ... does not exist" during build** → you forgot `git add`.
- **A tool resolves to the wrong version** → `which -a <tool>`; nix paths
  (`/etc/profiles/per-user/...`) must come before `/opt/homebrew/bin`.
- **Something broke after an update** → `sudo darwin-rebuild --rollback`,
  then investigate at leisure. Generations are the safety net.
- **Home-manager refuses to overwrite a file** → something created a real
  file where it wants a symlink. Move it aside, or check for `*.hm-backup`
  leftovers from the automatic backup.
