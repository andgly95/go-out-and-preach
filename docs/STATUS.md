# STATUS

Last updated: 2026-09-23. One page, overwritten each session. History lives in git and `docs/archive/`.

## What's playable

New Game → week view → Sunday/Tuesday meetings at the Hall (seat choice, social moment, 9 rotating talks) → Thursday/Saturday field service on Maple Street (12 houses, 11 householder conversations, apostate at #7) → after-service report → next day. Hidden doubt meter gates off-script choices (25–40) and inner-voice lines (40).

Not yet: save/load, family scenes, endings, month structure. Conviction, standings, energy, and hours are displayed but nothing reads them.

## Current focus

Making v0.1 fun: a full run from New Game to an ending, played without debug keys. Diagnosis from the September review:
- The meters have no consequences, and energy refills every day.
- There's no decision on the map: knocking every door is always optimal.
- Doubt falls when you succeed, so a normal player never reaches the gated content. (Simulated: a player who takes the "good" option reaches 25 in 0% of months.)
- Return visits you schedule aren't honoured, and there's no Householder of Note.
- Monday, Wednesday and Friday only offer "Go to bed".

Plan, in order: (1) week/month loop with an energy budget and consequences, plus save and an ending; (2) return visits as real appointments and one Householder of Note; (3) doubt driven by exposure, tuned by simulation; (4) weekday scenes from cast.md beats; (5) endings from BACKLOG.

## Tooling (new)

- `bash tools/check.sh` imports, boots every scene, and runs `tools/ci/tests/`. CI runs it on every push.
- `bash tools/screenshot.sh` renders real frames under Xvfb.
- A Claude Code web hook installs Godot 4.6.1 each session.

## Decisions to review

- Dialogic autoload reverted from a `uid://` reference to a `res://` path, so fresh clones import cleanly.

## Open questions for Andrew

- None blocking yet.

## Next step

Build the week/month loop (plan step 1).
