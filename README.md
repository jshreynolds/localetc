# etc — one declarative config for macOS and NixOS

My personal declarative system configuration. The design: for the most part you
clone this repo, apply it to the machine with one command, and Robert is your
father's brother.

Powered by [nix-darwin](https://github.com/nix-darwin/nix-darwin) on macOS and
[NixOS](https://nixos.org/) on Linux, sharing one
[home-manager](https://github.com/nix-community/home-manager) config so the
shell, tools and dotfiles are identical on both. macOS builds nix via
[Determinate Nix](https://determinate.systems/); NixOS ships its own.

```
~/etc/
├── flake.nix                  # main file: the two mkHost functions + the roster
├── flake.lock                 # exact pinned versions of everything (committed)
├── hosts/                     # ONE MACHINE = ONE FOLDER
│   ├── playbook/default.nix   #   its facts: username, work, its own casks
│   └── nixpad/                #   a NixOS box
│       ├── default.nix        #     same, plus `system` and `modules`
│       ├── hardware-configuration.nix # verbatim nixos-generate-config output
│       └── boot.nix           #     hand-written boot config for THIS machine
├── nix/                       # everything SHARED by all machines
│   ├── system/                # system-level (applies to the whole machine)
│   │   ├── darwin/            #   the Mac side
│   │   │   ├── core.nix       #     machine identity, nix/Determinate handshake
│   │   │   ├── homebrew.nix   #     GUI apps (casks) + App Store apps
│   │   │   └── macos-defaults.nix #  Finder/Dock/keyboard/etc settings
│   │   └── linux/             #   the NixOS side
│   │       ├── core.nix       #     machine identity, nix settings, ssh, docker
│   │       ├── apps.nix       #     GUI apps (the counterpart to homebrew.nix)
│   │       └── desktop.nix    #     GNOME session: display, audio, printing
│   └── home-manager/          # user-level (applies to $USER)
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

The rebuild command depends on the platform: **`drs`** on macOS
(`sudo darwin-rebuild switch --flake ~/etc`), **`nrs`** on NixOS
(`sudo nixos-rebuild switch --flake ~/etc`). The table and notes below write
**rebuild** for whichever your machine uses.

| I want to… | Command |
|---|---|
| Apply config changes to the machine | rebuild (`drs` on macOS / `nrs` on NixOS) |
| Add a CLI tool | add it to `nix/home-manager/packages.nix` (find names: `nix search nixpkgs <thing>`), `git add`, rebuild |
| Add a GUI app | macOS: a cask in `nix/system/darwin/homebrew.nix`. NixOS: a package in `nix/system/linux/apps.nix`. Then `git add`, rebuild |
| Add an alias / env var | edit `nix/home-manager/shell.nix`, rebuild, open a new terminal |
| Update everything | `cd ~/etc && nix flake update`, then rebuild (commit the new `flake.lock`) |
| Undo the last switch | macOS: `sudo darwin-rebuild --rollback` · NixOS: `sudo nixos-rebuild switch --rollback` |
| See switch history | macOS: `darwin-rebuild --list-generations` · NixOS: `nixos-rebuild list-generations` |
| Free disk space | `sudo nix-collect-garbage -d` (NixOS also GCs weekly on its own — `nix.gc` in `nix/system/linux/core.nix`) |
| Update a brew-managed cask (macOS only) | `brew upgrade --cask <name>` (all: `brew upgrade`) — switches never upgrade casks (`onActivation.upgrade = false`), and many apps self-update anyway |

**The golden rule:** nix only sees files git knows about. After creating a new
file, `git add` it or the build fails with a misleading "path does not exist". 
Edited files will be applied with warnings.

### Editing config files

Two flavors, declared in `nix/home-manager/dotfiles.nix`. `dotfiles/` mirrors the
target structure minus the leading dot (`dotfiles/claude/settings.json` →
`~/.claude/settings.json`).

- **Nix-managed** (starship, alacritty, ghostty, zellij, git, jj prefs): edit
  the file in `~/etc/dotfiles/` (or the `.nix` module), then rebuild to apply.
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

`~/.agents/skills` is the one skills directory (wired in `nix/home-manager/agents.nix`):

- **Repo skills** live in `ai/skills/<name>/` — each is live-linked into
  `~/.agents/skills`. Edits apply instantly; a NEW skill needs `git add` + rebuild.
- **External skills**: `~/etc/ai/skill-add <org/repo> [skill]` installs into
  `~/.agents/skills` and records the source in `ai/external-skills.list`.

Codex reads `~/.agents/skills` natively. Claude Code only reads
`~/.claude/skills` (flat, per-skill symlinks), so `ai/skill-sync` mirrors the
directory there — automatically on every rebuild and after every `skill-add`.

### Secrets

API keys live in `~/etc/secrets.zsh` (git-ignored, `chmod 600`), sourced by
zsh at startup. Never put a secret in any `.nix` file — everything nix touches
lands world-readable in `/nix/store`.

## Setting up a new machine

### macOS

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
     brews = [ ];                 #  lists in nix/system/darwin/homebrew.nix
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
    `nix/system/darwin/macos-defaults.nix`, and Safari preferences.

#### The Determinate Nix arrangement

macOS only. Determinate Nix owns the nix installation itself; nix-darwin is told
hands-off (`nix.enable = false` in `core.nix`). Practical consequences:

- nix settings (extra substituters, trusted users) go in
  `/etc/nix/nix.custom.conf` by hand — not in nix-darwin options.
- Upgrade nix itself: `sudo determinate-nixd upgrade`
- Garbage-collect: `sudo nix-collect-garbage`

NixOS has no equivalent: there, nix is just another service the config declares
— settings, daemon and GC all live in `nix/system/linux/core.nix`.

#### Homebrew's remaining job

macOS only. Homebrew handles what nixpkgs can't: GUI apps (casks), Mac App Store
apps (via `mas`), and a few formulae that aren't packaged in nixpkgs. The full
list lives in `nix/system/darwin/homebrew.nix` with `cleanup = "zap"` — anything
brew-installed that isn't declared there gets uninstalled on the next `drs`. So:
to try something quickly, `brew install foo` works, but declare it if you want
to keep it around.

NixOS has no brew: GUI apps are ordinary nixpkgs packages in
`nix/system/linux/apps.nix`.

### NixOS, from a wiped disk

No Determinate Nix, no Homebrew — on NixOS, nix *is* the OS. The goal is the
same: a booting minimal system, this repo, one `switch`. The steps below
recreate `nixpad` (a stock x86 UEFI box); an Apple-Silicon Mac like `nacos`
boots through Asahi and diverges at steps 1 and 4 — see **Apple Silicon
(nacos)** at the end of this section. For any other box, see the note in step 4.

1. **Install minimal NixOS from the ISO.** Boot the official installer (the
   graphical GNOME image is easiest). Pick *Erase disk → Encrypt* — this machine
   runs LUKS on root **and** swap — and create the `jshlyd` account. Hostname,
   extra packages and desktop chosen here are all irrelevant; the flake
   overrides them. Reboot into the bare system.

2. **ssh key → GitHub.** The repo is private, so the fresh box needs a key
   before it can clone:
   ```
   nix-shell -p git openssh
   ssh-keygen -t ed25519 -C nixpad
   cat ~/.ssh/id_ed25519.pub    # add at github.com/settings/keys
   ```

3. **Clone to `~/etc`** (the location is a hard assumption — see `repoDirName`
   in flake.nix):
   ```
   git clone git@github.com:jshreynolds/localetc.git ~/etc
   ```

4. **Re-generate this machine's hardware.** A fresh install makes *new* LUKS
   containers with *new* UUIDs, so the committed
   `hosts/nixpad/hardware-configuration.nix` and the swap-unlock UUID in
   `hosts/nixpad/boot.nix` describe the OLD disk and will not boot. Replace them:
   ```
   sudo nixos-generate-config --show-hardware-config \
     > ~/etc/hosts/nixpad/hardware-configuration.nix
   ```
   Then reconcile `boot.nix`'s swap-LUKS `.device` UUID with the new disk — the
   installer wrote the real one into `/etc/nixos/configuration.nix`, and `blkid`
   lists them — and run `nix fmt`.
   > **Different machine, not nixpad?** Also add its `hosts/<host>/` folder and a
   > `nixosConfigurations` line in `flake.nix`, exactly as the macOS steps show,
   > then point the commands below at `#<host>` instead of `#nixpad`. On an
   > Apple-Silicon Mac the disk, boot and firmware specifics differ — see
   > **Apple Silicon (nacos)** below.

5. **git add** the regenerated files — a flake ignores untracked files:
   ```
   git -C ~/etc add hosts/nixpad
   ```

6. **Build, then switch.** Flakes aren't enabled on a stock install yet, hence
   the flag. Build first to surface any broken package without activating:
   ```
   sudo nixos-rebuild build  --flake ~/etc#nixpad \
     --extra-experimental-features "nix-command flakes"
   sudo nixos-rebuild switch --flake ~/etc#nixpad \
     --extra-experimental-features "nix-command flakes"
   ```
   After this first switch the flag is unnecessary — `nix/system/linux/core.nix` turns
   flakes on — and the rebuild alias is `nrs`.

7. **Reboot** into the GNOME session, then the non-nix bits (git-ignored or
   deliberately machine-local, so they never come from the repo):
   - `~/etc/secrets.zsh` with API keys (`chmod 600`; copy from a password
     manager, not another machine's history).
   - git/jj identity: `~/.config/jj/conf.d/user.toml` (kept out of the repo on
     purpose — see `nix/home-manager/git.nix`).
   - Sign in to 1Password; it unlocks via the polkit policy `nix/system/linux/apps.nix`
     grants to your user.

#### Apple Silicon (nacos): the disk and boot bits that differ

`nacos` is an M1 MacBook Air, so it boots through Asahi's `m1n1 → U-Boot → UEFI`
chain rather than a stock UEFI, and no graphical NixOS installer runs on it. Two
steps above change; the rest — ssh key, clone, git add, build, switch, reboot —
are identical. Getting the encrypted disk and the boot config right by hand is
the fiddly part, so it is spelled out here.

**In place of step 1 (the base install):**

1. **From macOS, run the Asahi installer** (`curl https://alx.sh | sh`) and pick
   the *UEFI environment only* option — no distro, just the boot chain. It
   shrinks macOS, writes `m1n1` + U-Boot, creates the EFI System Partition (ESP)
   and carves out an empty Linux root partition. It also extracts this Mac's
   non-redistributable peripheral firmware to `vendorfw/` on the ESP — that is
   the origin of the `firmware.cpio` this repo vendors (see the firmware note
   below).

2. **Reboot, hold the power button** to reach the boot picker, choose the new
   *UEFI* volume, and from U-Boot boot a **NixOS aarch64 installer USB**. Use the
   Asahi-flavoured installer image (built with the Asahi kernel, from
   [`nixos-apple-silicon`](https://github.com/nix-community/nixos-apple-silicon))
   so the framebuffer and USB work. WiFi may not come up in the installer; a
   USB-C ethernet or phone-tethering adapter is the reliable fallback.

3. **Build the encrypted LUKS + LVM root by hand** in the installer shell (as
   root). This is exactly the layout `hosts/nacos/hardware-configuration.nix`
   describes: one LUKS container, an LVM volume group `vg` on top, a single
   `root` LV filling it. Find the large empty partition the Asahi installer made
   (`lsblk`; it is `nvme0n1p6` on nacos) and the ~500 MB vfat ESP (`nvme0n1p4`):
   ```
   cryptsetup luksFormat /dev/nvme0n1p6          # set the disk passphrase (LUKS2)
   cryptsetup luksOpen   /dev/nvme0n1p6 cryptroot

   pvcreate /dev/mapper/cryptroot
   vgcreate vg /dev/mapper/cryptroot             # VG named "vg"
   lvcreate -l 100%FREE -n root vg               # LV "root" -> /dev/mapper/vg-root

   mkfs.ext4 /dev/vg/root
   mount /dev/vg/root /mnt

   mkdir -p /mnt/boot
   mount /dev/nvme0n1p4 /mnt/boot                # the Asahi-made ESP: MOUNT it,
                                                 # never reformat — it holds m1n1
                                                 # and vendorfw/firmware.cpio
   ```

4. **Generate the config, then add the boot bits `nixos-generate-config` will
   not.**
   ```
   nixos-generate-config --root /mnt
   blkid /dev/nvme0n1p6        # note the crypto_LUKS UUID for the unlock below
   ```
   The generated `hardware-configuration.nix` finds the LVM root and the ESP, but
   the LUKS unlock, LVM-in-initrd, Asahi support and bootloader are all
   hand-written — the exact set now committed in `hosts/nacos/boot.nix`. Add them
   to `/mnt/etc/nixos/configuration.nix`:
   ```nix
   imports = [ ./hardware-configuration.nix ./apple-silicon-support ];

   hardware.asahi.enable = true;

   boot.loader.systemd-boot.enable = true;
   boot.loader.efi.canTouchEfiVariables = false;   # Apple Silicon: no writable EFI vars

   boot.initrd.luks.devices.cryptroot = {
     device = "/dev/disk/by-uuid/<crypto_LUKS UUID from blkid>";
     allowDiscards = true;
     bypassWorkqueues = true;
   };
   boot.initrd.services.lvm.enable = true;         # find vg-root in the unlocked container
   ```
   `./apple-silicon-support` here is a clone of `nixos-apple-silicon` dropped into
   `/mnt/etc/nixos/` for this one bootstrap install. In *this* repo the same
   module arrives as the `nixos-apple-silicon` flake input (see `flake.nix` and
   `hosts/nacos/boot.nix`), so you never vendor the module again.

5. **Install and reboot.**
   ```
   nixos-install
   reboot
   ```
   First boot runs `m1n1 → U-Boot → systemd-boot → Asahi kernel`, prompts for the
   LUKS passphrase, unlocks, brings up LVM, and lands on the bare system.

**In place of step 4 (hardware regen), plus the firmware copy.** Once you are on
the bare system and have cloned this repo (steps 2–3 of the main list), do the
usual regen into the host folder:
```
sudo nixos-generate-config --show-hardware-config \
  > ~/etc/hosts/nacos/hardware-configuration.nix
```
Reconcile `hosts/nacos/boot.nix`'s `cryptroot` `.device` UUID with the new disk
(`blkid` lists it). Then the Apple-Silicon-only step — **vendor the peripheral
firmware into the repo** so a *pure* flake build can find it (the module's
default path `/boot/vendorfw` is an absolute ESP path, which pure flake
evaluation is forbidden to read, so it resolves to `null` and the build asserts
out):
```
mkdir -p ~/etc/hosts/nacos/vendorfw
cp /boot/vendorfw/firmware.cpio ~/etc/hosts/nacos/vendorfw/
```
`hosts/nacos/boot.nix` already points `hardware.asahi.peripheralFirmwareDirectory`
at `./vendorfw`. `git add` it (≈31 MB, non-redistributable but not a secret;
this repo is private), run `nix fmt`, and rejoin steps 5–7 unchanged.

## Troubleshooting

- **"path ... does not exist" during build** → you forgot `git add`. Nix only
  sees tracked files. _(Both platforms.)_
- **A tool resolves to the wrong version** → `which -a <tool>`, then check what
  wins ahead of the nix profile (`/etc/profiles/per-user/...`):
  - macOS: usually `/opt/homebrew/bin`, which must come *after* nix — see the
    PATH note in `nix/home-manager/shell.nix`.
  - NixOS: no brew to blame; a stray copy is almost always in `~/.local/bin` or
    a language toolchain's own `bin`.
- **Something broke after an update** → roll back to the previous generation,
  then investigate at your leisure (that's one of the whole points):
  - macOS: `sudo darwin-rebuild --rollback`
  - NixOS: `sudo nixos-rebuild switch --rollback`, or pick an older generation
    from the systemd-boot menu at startup.
- **Home-manager refuses to overwrite a file** → something created a real file
  where it wants a symlink. Move it aside, or check for `*.hm-backup` leftovers
  from the automatic backup. _(Both platforms.)_
