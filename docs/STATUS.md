# STATUS

Last updated: 2026-09-23. One page, overwritten each session. History lives in git and `docs/archive/`.

## What's playable

A full run: New Game (name, Brother/Sister, Mom/Dad) → eight weeks → two month-end reports with an elder → one of five endings. See `docs/design/v01-loop.md` for the whole loop.

- **Day planner.** Each day shows its options with energy costs: meetings (attend or stay home), Thursday/Saturday service, evening activities (family worship, personal study, visiting Grandma, game night once the congregation warms to you, saying yes to Dana, rest). Sleep restores 3 energy, not a full refill.
- **Field service is a time budget.** Two hours per morning, plus "keep going" for energy. Return visits and studies persist as appointments that are always home; polite refusers stop answering after two. The map dims houses there's no time left for.
- **Month end.** Auxiliary pioneer sign-up on the first Sunday of each month (30 hours). A report slip, then one of four elder conversations (affirmation, "encouragement", shepherding with an optional confession, a steady month).
- **Doubt is exposure.** Success no longer erases it; conviction buffers it and wears down with it. Personal study prepares you for Sunday, and that "successful meeting" is what eases doubt.
- **Autosave** at the start of each week; Continue works.

Not yet: most evening activities show a one-line result, not a scene. There's no Householder of Note arc (Daniel at #9 is named, nothing more). No sibling, coworker, or Sister Who Talks beats. No "comment at the Lighthouse Study" moment on screen (it's mechanical only).

## Balance (tools/ci/tests/test_balance.gd, 60 runs per style)

| Style | Doubt at wk 8 (median) | Endings |
|---|---|---|
| devout (pioneer, never misses) | ~4 | Regular Pioneer / In-Fold |
| typical | ~15 | mostly In-Fold |
| curious (honest choices, Dana) | ~35 | mixed: In-Fold, Keeping Up Appearances, Fade |
| drifting | ~49 | Quiet Fade |

The typical and curious runs are still below the design targets. That's expected: the weekday story beats (sibling, parent, coworker, Daniel) are the everyday exposures and don't exist yet. The balance test carries interim targets until they do.

## Decisions to review (Andrew: veto any)

All are one constant or data file each. Full reasoning in `docs/design/v01-loop.md`.
- Run length: 8 weeks. Sleep: +3 energy. Morning of service: 2 hours; +1 hour costs 2 energy.
- New-door answer rate 35% on Saturday and 25% on Thursday (was 26.5%).
- Polite refusers stop answering return visits after 2 conversations.
- Exposure wears conviction down by half its size; conviction drifts −3 a week.
- Names: the coworker is **Dana**; the grandparent is **Grandma**; house #9's inquisitive neighbor is **Daniel** (cast.md § 5.2's Householder of Note). Dialogue lines in the month-end talks, the five endings, the study session, and the activities are drafts, marked `# TODO: authenticity check`.
- The Dialogic autoload uses a `res://` path, so fresh clones import cleanly.

## Open questions for Andrew

- Which Householder of Note ships in v0.1? cast.md § 8 Q3 leaves it open. I'm building **Daniel** at #9 next because house #9's returning branch already leans that way ("Looked some stuff up, even").
- Sibling: older or younger, and a name (cast.md § 3.2 leaves both open).

## Next step

Story beats that run through the eight weeks. These are cast.md's "common beats" for the parent, sibling, coworker, Sister Who Talks, grandparent, and service partner, scheduled as short scenes on the day screen. Then Daniel's arc. Then re-tune the balance test to its design targets.
