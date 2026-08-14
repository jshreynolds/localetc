# Kdenlive Copilot FAQ

Running log of real questions asked in copilot sessions, and the answers
found — checked before the manual cache or the web (see SKILL.md "FAQ
log"). Not hand-polished documentation; keep entries as terse as a chat
answer.

## Dragging a clip onto another clip in the timeline

**Q:** How do I drag a clip over another to overwrite it? It doesn't do
that by default.

**A:** Correct — Kdenlive doesn't support drag-to-overwrite on the same
track by default. Same-track clips can't overlap; dragging one near
another snaps it flush instead of overwriting. To overwrite, use the
deliberate 3-point **Overwrite** command instead of a drag: mark the
source clip's in/out (`I`/`O`) in the clip monitor, position the timeline
cursor where the overwrite should start, select/activate the target track
(`Up`/`Down` then `Shift+T`), then press `B` (or Menu ‣ Sequence ‣
Insertion ‣ Overwrite Clip Zone in Timeline). Dragging still works for
moving a clip to empty space or a different track — overlapping different
tracks is fine (used for compositions/transitions), just not same-track
overwrite-by-drop.

_Answered: 2026-08-09_

## Loading a timeline clip into the Clip Monitor with matching in/out

**Q:** How do I load a clip that's in the timeline into the clip monitor
with the correct in and out points set (Premiere's "Match Frame")?

**A:** No built-in single action for this — confirmed by searching the
full manual (Current Clip menu, Sequence menu, Clip/Project Monitor
right-click menus, shortcut reference). Closest workflow: select the
timeline clip, press `Shift+Z` (Adjust Timeline Zone to Selection) to set
the *timeline* zone to that clip's exact boundaries, then Timeline ‣
Current Clip ‣ **Clip in Project Bin** to jump to the master clip, which
loads into the Clip Monitor — but with the clip's own stored/full zone,
not the trimmed in/out of that specific timeline instance. You'd have to
set `I`/`O` manually to match. This is a known gap vs. Premiere, not a
missing-shortcut situation — worth a feature request upstream if it comes
up often.

_Answered: 2026-08-09_

## No audio output, but meters bounce

**Q:** Kdenlive plays, the audio meters bounce, the Mac is unmuted and
other apps play sound — but nothing comes out of Kdenlive.

**A:** Kdenlive/MLT binds the output audio device at app start and does
not follow macOS device changes. If the system output device changed
(headphones plugged/unplugged, BT connect, display audio, aggregate
device switch) after Kdenlive launched, it keeps rendering to the old
device — meters bounce because the SDL consumer is fed fine, the samples
just go nowhere audible. **Fix: restart Kdenlive** after any output-device
change. If it recurs, pin an explicit device in Settings ‣ Configure
Kdenlive ‣ Playback (Audio Backend / Driver / Device) instead of leaving
it on default/auto.

_Answered: 2026-08-10_

## Toggle timeline snapping

**Q:** How do I disable/enable snapping on the timeline?

**A:** `Alt+M` (Option+M on Mac) — Sequence menu ‣ Snap; magnet icon in the
timeline toolbar is the mouse path. Snaps to clip edges, markers, and
guides across tracks. Related: `Alt+Left`/`Alt+Right` = go to
previous/next snap point. NOT `S` — that was a bad guess in the
cheat-sheet (Premiere's key); corrected against
`user_interface/menu/sequence_menu.md`.

_Answered: 2026-08-10_
