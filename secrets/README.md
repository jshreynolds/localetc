# secrets — how encryption works here

Everything in this directory except `pubkeys/` and this file is **ciphertext**
and safe to push. This explains what decrypts it, when that happens, and what
breaks when it doesn't.

The worked example throughout is `storage-box.env` — the Hetzner Storage Box
credentials consumed by `nix/home-manager/storage-box.nix`. Nothing about the
scheme is specific to it; any number of secrets work the same way.

Related: [`pubkeys/README.md`](pubkeys/README.md) for the per-machine public
keys, and [`enroll-machine`](enroll-machine), which performs §5. Implementation
lives in `nix/home-manager/gpg-keys.nix` (key hygiene) and the `sops-nix` input
in `flake.nix`.

---

## 1. The cast

| piece | what it is | where |
|---|---|---|
| **GPG key** | one per machine. Primary `ed25519` (certify+sign), subkey `cv25519` (encrypt). Neither expires — a machine is retired by dropping it from `.sops.yaml` | `~/.gnupg`, never in this repo |
| **`.sops.yaml`** | which fingerprints each secret is encrypted to | repo root |
| **`secrets/*`** | the secrets, encrypted per value | this directory, committed |
| **`secrets/pubkeys/*.asc`** | public halves, so each machine can encrypt to the others | this directory, committed |
| **sops** | the CLI that encrypts/decrypts. Calls `gpg` | on PATH everywhere |
| **sops-nix** | the home-manager module that decrypts at the right moments | flake input |
| **gpg-agent** | holds your passphrase in memory, spawns pinentry | auto-started on demand |
| **pinentry** | the thing that actually asks for your passphrase | see §7 |

Only the **cv25519 subkey** is used for secrets. The primary just certifies it.

---

## 2. Where plaintext lives

Never on disk in this repo, and never in the nix store.

```
secrets/<name>                   ciphertext, committed to git
        │
        │  sops-nix decrypts at activation / login
        ▼
$XDG_RUNTIME_DIR/secrets.d/<N>/<name>          (linux: /run/user/1000/…, tmpfs)
getconf DARWIN_USER_TEMP_DIR /secrets.d/<N>/…  (macOS: /var/folders/…)
        │
        │  symlink, if the module asked for one via `path`
        ▼
<wherever the consumer reads it>   e.g. ~/.config/storage-box/env, mode 0600
```

On Linux that runtime directory is **tmpfs**: it lives in RAM and is destroyed
on reboot. Plaintext secrets never touch the SSD. The consequence is that they
must be re-decrypted on *every* boot — which is the whole reason §7 matters.

Encryption is **per value**, not per file. In a dotenv secret the key names
(`RCLONE_CONFIG_BOX_HOST=`) stay readable in git; only the values are
`ENC[AES256_GCM,…]`. Don't put a secret in a key name. The same holds for the
keys of a YAML or JSON secret.

---

## 3. Adding a secret

1. Create it, encrypted from the start — `sops` writes ciphertext on save, so
   the plaintext never exists as a file:
   ```
   sops secrets/<name>.env
   ```
   The extension picks the format sops parses (`.env`, `.yaml`, `.json`).
   `.sops.yaml`'s `path_regex` decides which keys it is encrypted to; the
   current rule covers `secrets/*.env`, so a different extension needs a rule.

2. Declare it in the home-manager module that consumes it:
   ```nix
   sops.secrets."<name>.env" = {
     sopsFile = ../../secrets/<name>.env;
     format = "dotenv";
     path = "${config.xdg.configHome}/<consumer>/env";   # optional symlink
     mode = "0600";
   };
   ```
   A machine that isn't a recipient cannot render this, and a failed
   `sops-nix.service` fails the whole activation — which would block every
   rebuild on that machine. `storage-box.nix` guards against that with
   `isSopsRecipient`, gating the secret (and its timers) on the machine having
   a public key in `pubkeys/`. Copy that pattern for anything that must not
   break rebuilds on a half-enrolled machine.

   On linux the secret then appears about 30s after login, when the sops-nix
   timer fires (§7). Anything that must not depend on that timing says so:
   ```nix
   Unit.Requires = [ "sops-nix.service" ];   # run it, and fail with it
   Unit.After = [ "sops-nix.service" ];      # and wait for it
   ```
   `storage-box.nix` does, which is also what re-runs the decryption if the
   timer's attempt failed.

3. `git add` both files, rebuild.

Some secrets also need per-service setup that has nothing to do with sops — for
the Storage Box, an ssh key uploaded to the box and its host key trusted, once
per machine (the commands are in the header comment of `storage-box.nix`).

---

## 4. Editing a secret

You do this by hand, whenever a value changes.

1. `sops secrets/<name>.env` — sops reads `.sops.yaml`, sees which fingerprints
   this path must be encrypted to.
2. sops calls `gpg` to **decrypt** the file into a temp buffer.
   → **passphrase needed** (unless the agent has it cached).
3. Your `$EDITOR` opens on the plaintext.
4. On save, sops **re-encrypts** to every fingerprint in `.sops.yaml`.
   → *no* passphrase needed; encryption only uses public keys.
5. `git commit` the ciphertext, then rebuild: sops-nix decrypts the copy of the
   file in the nix store, so editing alone changes nothing on the machine.

---

## 5. A new machine

A machine can read secrets only if it has its own GPG key and the ciphertext
was encrypted to it. Four steps: make the key, publish its public half, list
its fingerprint in `.sops.yaml`, re-encrypt everything to the new list.

The last step needs a key that can *already* decrypt, which a new machine by
definition lacks. So it takes two runs of the same script:

```
./secrets/enroll-machine          # on the new machine: key, pubkey, .sops.yaml
git push
# then, on a machine that is already a recipient:
git pull && ./secrets/enroll-machine    # re-encrypts, commits
git push
# back on the new machine:
git pull && nrs                   # or drs — renders the secrets
```

Every step is idempotent and skips what is already done, so "run it on both
machines" is the whole procedure. `--hostname`, `--name` and `--email` override
the defaults (`hostname -s`, and the repo's git identity); `--expire` gives the
primary an expiry, which it otherwise does not have; `--no-commit` leaves the
changes staged for inspection.

By hand it is:

```
gpg --quick-generate-key "Name (hostname) <email>" ed25519 cert,sign never
gpg --quick-add-key <FPR> cv25519 encr never
gpg --export --armor <FPR> > secrets/pubkeys/<hostname>.asc
# add <FPR> to .sops.yaml, then on an existing recipient machine:
sops updatekeys secrets/*.env
```

The *first* machine ever is the one case the script can't help with: with no
fingerprint in `.sops.yaml` yet there is nothing to append to, so write the
`pgp:` block by hand after generating the key.

Back up the new key's revocation certificate
(`~/.gnupg/openpgp-revocs.d/<FPR>.rev`) to a password manager.

---

## 6. Sequence: build, boot, and steady state

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
2. Nothing decrypts *at* login. sops-nix ships its unit `WantedBy =
   graphical-session-pre.target`; `gpg-keys.nix` forces that list empty, so the
   unit exists and waits.
3. 30s later `sops-nix.timer` fires it, and every declared secret is rendered.
   → **no passphrase typed**: the login keyring is open by then, and pinentry
   reads the stored passphrase back out of it silently (§7).
4. `RemainAfterExit` holds the unit active, so everything that `Requires` it
   afterwards reuses that one decryption instead of repeating it.

### Steady state

Nothing on a timer touches gpg:

| unit | schedule | needs passphrase? |
|---|---|---|
| `sops-nix` | 30s after login | **no** — pinentry answers from the login keyring |
| `storage-box-sync` | 2 min after login, then hourly | **no** — reads what sops-nix already rendered |
| `storage-box-sync-failed` | on failure of the above | notify-send, so a broken sync is visible |
| `gpg-expiry-check` | daily | **no** — only lists public key metadata |

This is the important asymmetry: **decryption happens rarely** (activation, and
once per boot), while the things that *use* secrets run constantly and never
need your key. A sync at 3am doesn't wake up a passphrase prompt.

---

## 7. pinentry: who asks for the passphrase

`sops` → `gpg` → `gpg-agent` → **pinentry**. The agent picks the pinentry
binary named in `~/.gnupg/gpg-agent.conf`, which `nix/home-manager/git.nix` generates:

| platform | program | can prompt from a background service? |
|---|---|---|
| macOS | `pinentry-mac` | **yes** — native dialog, and it can store the passphrase in the macOS Keychain, making later boots fully unattended |
| Linux | `pinentry-gnome3` | **yes, if** the GNOME session's gcr prompter is up on the D-Bus session bus |
| Linux (old config) | `pinentry-curses` | **no** — needs a controlling terminal; in a systemd unit there is none |

We moved Linux from curses to gnome3 precisely because of §6's boot step. A
tty-only pinentry cannot prompt from `sops-nix.service`, so secrets would
simply never appear after a reboot.

**Caching.** `gpg-agent.conf` sets `default-cache-ttl 600` (10 min idle) and
`max-cache-ttl 7200` (2h absolute). Within those windows you won't be asked
again. Across a reboot the cache is always gone.

**Why nothing prompts at boot.** `pinentry-gnome3` has two ways to answer: read
the passphrase out of the login keyring over libsecret, silently, or draw a
dialog through GNOME's gcr prompter. The silent path needs gnome-keyring's
secret service, which PAM unlocks at login but which is not there yet while the
session is still assembling. Run sops-nix at `graphical-session-pre.target` and
both paths fail — the lookup has nothing to talk to, and the dialog gcr does
draw is torn down unanswered in the same second:

```
gcr-prompter: received PerformPrompt call from callback …/Prompt/p1
gcr-prompter: stopping prompting for operation …/Prompt/p1
gcr-prompter: couldn't find the callback for prompting operation
```

Ordering it at `graphical-session.target` instead is **not** enough; that was
tried, and the dialog still died. So it is not ordered against the session at
all. `gpg-keys.nix` forces its `WantedBy` empty and gives it a timer instead:

```nix
Timer.OnStartupSec = "30s";
```

`OnStartupSec`, not `OnBootSec` — in a user manager the latter counts from
system boot, so by the time you log in it has usually elapsed and the timer
fires immediately, back into the session start it was meant to avoid. Counting
from the user manager's own start means counting from login, which is when PAM
unlocks the keyring the passphrase lives in.

Recovering by hand is still `systemctl --user restart sops-nix` from a
terminal.

---

## 8. What goes wrong

| symptom | cause | fix |
|---|---|---|
| a consumer says its env file isn't there (e.g. `storage-box: sops has not rendered …`) | the secret was never decrypted | `systemctl --user status sops-nix`, then restart it |
| sops-nix unit failed, log says no secret key | this machine's fingerprint isn't in `.sops.yaml` | `./secrets/enroll-machine`, then again on a recipient machine (§5) |
| `gpg: Inappropriate ioctl for device` | a tty-only pinentry with no tty | `export GPG_TTY=$(tty)`, or use the GUI pinentry |
| every gpg waits ~40s, then `keydb_search_first failed: Connection timed out`, log says `waiting for lock (held by <pid>)` | a **live** keyboxd holds `public-keys.d/pubring.db.lock` — classically one stranded by the boot-time home-manager activation, which sits in `system.slice` where `gpgconf --kill` from your session never reaches it | `kill <pid>` from the message. `gpg-keys.nix` skips the pubkey import at boot so this should not recur |
| gpg hangs and the holding pid is **dead** | stale lock file in `~/.gnupg/public-keys.d/`, e.g. after a crash or a **hostname change** — the lock records the old host so gpg won't break it | `gpgconf --kill all`, then delete the `.#lk*` and `*.lock` whose pids are gone |
| the desktop freezes for ~40s right after login, mouse included | something in the session start path is blocked on gpg — the row above, hit from a unit GNOME waits for | as above; check `systemd-analyze blame --user` for the unit that took the 40s |
| `skipped: Unusable public key` when encrypting | the recipient's key carries an expiry and it has passed | `gpg --quick-set-expire <FPR> never`, re-export to `pubkeys/` |
| passphrase asked again ~2h later | `max-cache-ttl 7200` | expected; raise it in `git.nix` if it grates |
| secrets gone after reboot, before login completes | tmpfs, by design | they come back when `sops-nix.service` runs |
| decrypt works on one machine, fails on another | only that machine's fingerprint is a recipient | enroll the other one (§5) |

---

## 9. Threat model

**Protected:** the repo can be pushed to a public remote. Ciphertext is
AES-256-GCM with keys wrapped to each machine's cv25519 subkey. Plaintext never
enters git, the nix store (world-readable), or the disk on Linux.

**Not protected:** anyone with your unlocked session can read the rendered
plaintext — it's a plain 0600 file owned by you. The private key at rest is
guarded by your passphrase plus LUKS. Key *names* in dotenv, YAML and JSON
secrets are visible. And sops leaves metadata in the clear: which fingerprints
can decrypt, and when it was last modified.

**Losing keys.** Secrets are encrypted to *every* machine's key, so losing one
machine costs an `enroll-machine` run, not access. Losing all of them means the
ciphertext is unrecoverable — back up at least one secret key and its
revocation certificate (`~/.gnupg/openpgp-revocs.d/<FPR>.rev`) to 1Password.
Worth remembering that most of what's stored here is also *re-issuable*: a
Storage Box credential can simply be regenerated.
