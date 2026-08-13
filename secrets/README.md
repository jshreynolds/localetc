# secrets — how encryption works here

Everything in this directory except the `pubkeys/` folder is **ciphertext** and
safe to push. This file explains what decrypts it, when that happens, and what
breaks when it doesn't.

Related: [`pubkeys/README.md`](pubkeys/README.md) for adding machines and
extending expiries. Implementation lives in `nix/home-manager/gpg-keys.nix` (key
hygiene), `nix/home-manager/storage-box.nix` (the one secret we currently have), and
the `sops-nix` input in `flake.nix`.

---

## 1. The cast

| piece | what it is | where |
|---|---|---|
| **GPG key** | one per machine. Primary `ed25519` (certify+sign, expires in 2y), subkey `cv25519` (encrypt, no expiry) | `~/.gnupg`, never in this repo |
| **`.sops.yaml`** | which fingerprints each secret is encrypted to | repo root |
| **`secrets/*.env`** | the secrets, encrypted per value | this directory, committed |
| **`secrets/pubkeys/*.asc`** | public halves, so each machine can encrypt to the others | this directory, committed |
| **sops** | the CLI that encrypts/decrypts. Calls `gpg` | on PATH everywhere |
| **sops-nix** | the home-manager module that decrypts at the right moments | flake input |
| **gpg-agent** | holds your passphrase in memory, spawns pinentry | auto-started on demand |
| **pinentry** | the thing that actually asks for your passphrase | see §5 |

Only the **cv25519 subkey** is used for secrets. The primary just certifies it.

---

## 2. Where plaintext lives

Never on disk in this repo, and never in the nix store.

```
secrets/storage-box.env          ciphertext, committed to git
        │
        │  sops-nix decrypts at activation / login
        ▼
$XDG_RUNTIME_DIR/secrets.d/<N>/storage-box.env      (linux: /run/user/1000/…, tmpfs)
getconf DARWIN_USER_TEMP_DIR /secrets.d/<N>/…       (macOS: /var/folders/…)
        │
        │  symlink
        ▼
~/.config/storage-box/env        mode 0600 — what storage-box-sync reads
```

On Linux that runtime directory is **tmpfs**: it lives in RAM and is destroyed
on reboot. Plaintext secrets never touch the SSD. The consequence is that they
must be re-decrypted on *every* boot — which is the whole reason §5 matters.

Encryption is **per value**, not per file. In `storage-box.env` the key names
(`RCLONE_CONFIG_BOX_HOST=`) are readable in git; only the values are
`ENC[AES256_GCM,…]`. Don't put a secret in a key name.

---

## 3. Sequence: editing a secret

You do this by hand, whenever a value changes.

1. `sops secrets/storage-box.env` — sops reads `.sops.yaml`, sees which
   fingerprints this path must be encrypted to.
2. sops calls `gpg` to **decrypt** the file into a temp buffer.
   → **passphrase needed** (unless the agent has it cached).
3. Your `$EDITOR` opens on the plaintext.
4. On save, sops **re-encrypts** to every fingerprint in `.sops.yaml`.
   → *no* passphrase needed; encryption only uses public keys.
5. `git commit` the ciphertext.

If you add a machine, editing isn't enough — run `sops updatekeys secrets/*.env`
to re-encrypt existing files to the new recipient list.

---

## 4. Sequence: build, boot, and steady state

### `nrs` / `drs` (rebuild)

1. home-manager activation runs.
2. `nix/home-manager/gpg-keys.nix` imports `secrets/pubkeys/*.asc` — public keys only,
   no passphrase, idempotent.
3. sops-nix's activation hook restarts the decryption unit:
   - **Linux**: `systemctl --user restart sops-nix`
   - **macOS**: `launchctl bootout` then `bootstrap` of the sops-nix agent
4. That unit decrypts every declared secret into the runtime dir.
   → **passphrase needed.** You are sitting at a terminal running `nrs`, so a
   prompt here is fine.

### Boot / login

1. Runtime dir is empty — every secret is gone by design.
2. `sops-nix.service` starts. Because `sops.gnupg.home` is set, it is
   `WantedBy = graphical-session-pre.target`, i.e. it runs as the graphical
   session comes up rather than at plain login.
3. It decrypts. → **passphrase needed**, and nobody is typing at a terminal.
   This is the fragile moment. See §5 and §6.

### Steady state

Neither timer touches gpg:

| unit | schedule | needs passphrase? |
|---|---|---|
| `storage-box-sync` | 5 min after boot, then hourly | **no** — reads the already-decrypted file |
| `gpg-expiry-check` | daily | **no** — only lists public key metadata |

This is the important asymmetry: **decryption happens rarely** (activation and
boot), while the things that *use* secrets run constantly and never need your
key. A sync at 3am doesn't wake up a passphrase prompt.

---

## 5. pinentry: who asks for the passphrase

`sops` → `gpg` → `gpg-agent` → **pinentry**. The agent picks the pinentry
binary named in `~/.gnupg/gpg-agent.conf`, which `nix/home-manager/git.nix` generates:

| platform | program | can prompt from a background service? |
|---|---|---|
| macOS | `pinentry-mac` | **yes** — native dialog, and it can store the passphrase in the macOS Keychain, making later boots fully unattended |
| Linux | `pinentry-gnome3` | **yes, if** the GNOME session's gcr prompter is up on the D-Bus session bus |
| Linux (old config) | `pinentry-curses` | **no** — needs a controlling terminal; in a systemd unit there is none |

We moved Linux from curses to gnome3 precisely because of §4's boot step. A
tty-only pinentry cannot prompt from `sops-nix.service`, so secrets would
simply never appear after a reboot.

**Caching.** `gpg-agent.conf` sets `default-cache-ttl 600` (10 min idle) and
`max-cache-ttl 7200` (2h absolute). Within those windows you won't be asked
again. Across a reboot the cache is always gone.

**Open risk, not yet verified on this hardware:** `sops-nix.service` is ordered
at `graphical-session-pre.target`, which is *before* GNOME Shell is fully up,
and `pinentry-gnome3` needs Shell's gcr prompter to draw its dialog. It may
prompt fine, or it may fail on the first boot after a rebuild. Test it with a
real reboot and:

```
systemctl --user status sops-nix
journalctl --user -u sops-nix -b
```

If it fails there, the fix is to order it later, in `nix/home-manager/gpg-keys.nix`:

```nix
systemd.user.services.sops-nix.Install.WantedBy = lib.mkForce [ "graphical-session.target" ];
```

Recovering a failed boot decrypt without a reboot is just
`systemctl --user restart sops-nix` from a terminal — the prompt then has
somewhere to go.

---

## 6. What goes wrong

| symptom | cause | fix |
|---|---|---|
| `storage-box: sops has not rendered …` | the secret was never decrypted | `systemctl --user status sops-nix`, then restart it |
| sops-nix unit failed, log says no secret key | this machine's fingerprint isn't in `.sops.yaml` | add it, `sops updatekeys secrets/*.env`, rebuild |
| `gpg: Inappropriate ioctl for device` | a tty-only pinentry with no tty | `export GPG_TTY=$(tty)`, or use the GUI pinentry |
| gpg hangs forever, `waiting for lock (held by …)` | stale lock file in `~/.gnupg/public-keys.d/`, often after a **hostname change** — the lock records the old host so gpg won't break it | `gpgconf --kill all`, then delete `.#lk*` and `*.lock` there |
| `skipped: Unusable public key` when encrypting | the recipient's key has expired | `gpg --quick-set-expire <FPR> 2y`, re-export to `pubkeys/` |
| passphrase asked again ~2h later | `max-cache-ttl 7200` | expected; raise it in `git.nix` if it grates |
| secrets gone after reboot, before login completes | tmpfs, by design | they come back when `sops-nix.service` runs |
| decrypt works on nacos, fails elsewhere | only nacos's fingerprint is currently a recipient | give that machine a key, add it, `updatekeys` |

---

## 7. Threat model

**Protected:** the repo can be pushed to a public remote. Ciphertext is
AES-256-GCM with keys wrapped to each machine's cv25519 subkey. Plaintext never
enters git, the nix store (world-readable), or the disk on Linux.

**Not protected:** anyone with your unlocked session can read
`~/.config/storage-box/env` — it's a plain 0600 file owned by you. The private
key at rest is guarded by your passphrase plus LUKS. Key *names* in dotenv
files are visible. And sops leaves metadata in the clear: which fingerprints
can decrypt, and when it was last modified.

**Losing keys.** Secrets are encrypted to *every* machine's key, so losing one
machine costs a `sops updatekeys`, not access. Losing all of them means the
ciphertext is unrecoverable — back up at least one secret key and its
revocation certificate (`~/.gnupg/openpgp-revocs.d/<FPR>.rev`) to 1Password.
Worth remembering that everything stored here is also *re-issuable*: a Storage
Box credential can simply be regenerated.
