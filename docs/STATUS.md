# STATUS

Last updated: 2026-09-23. One page, overwritten each session. History lives in git and `docs/archive/`.

## What's playable

A full run: New Game (name, Brother/Sister, Mom/Dad) → eight weeks → two month-end reports with an elder → one of five endings. See `docs/design/v01-loop.md` for the whole loop.

- **Day planner.** Each day shows its options with energy costs: meetings (attend or stay home), Thursday/Saturday service, evening activities (family worship, personal study, visiting Grandma, game night once the congregation warms to you, saying yes to Dana, rest). Sleep restores 3 energy, not a full refill.
- **Field service is a time budget.** Two hours per morning, plus "keep going" for energy. Return visits and studies persist as appointments that are always home; polite refusers stop answering after two. The map dims houses there's no time left for.
- **Month end.** Auxiliary pioneer sign-up on the first Sunday of each month (30 hours). A report slip, then one of four elder conversations (affirmation, "encouragement", shepherding with an optional confession, a steady month).
- **Doubt is exposure.** Success no longer erases it; conviction buffers it and wears down with it. Personal study prepares you for Sunday, and that "successful meeting" is what eases doubt.
- **Autosave** at the start of each week; Continue works.

- **Story beats** (`data/beats/`): thirteen short scenes across the eight weeks. Coffee with your parent, late-night texts from your brother Micah, Dana's invitation and later her 10pm call and her lunchtime question, Sister Marin in the lobby, the parked car with your service partner, family dinner, the lamp left on, the boxes in the hallway. They come from cast.md's "common beats", and several branch on what you've been doing.
- **Activity scenes:** family worship, personal study, Grandma, game night, and Dana each have a sequence of authored scenes, then a quieter repeat. Personal study's "look the verse up yourself" branch (doubt ≥ 25) echoes in Daniel's study.
- **Daniel** (house #9, the Householder of Note): four study sessions that progress (sources, the half-quoted verse, "do they get to keep their friends?", his decision), then he ends it or keeps going for your sake.

Not yet: seat picker still doesn't show who's sitting where; the Lighthouse Study "comment" moment is mechanical only; no endings reference Daniel, Micah, or Dana yet.

## Balance (tools/ci/tests/test_balance.gd, 60 runs per style)

| Style | Doubt at wk 8 (median) | Endings |
|---|---|---|
| devout (pioneer, never misses) | ~20 | Regular Pioneer / In-Fold |
| typical | ~24 (top tenth 36+) | mostly In-Fold, some Fade |
| curious (honest choices, says yes to Dana) | ~62 | Keeping Up Appearances, Fade, a few In-Fold |
| drifting | ~57 | Quiet Fade, Walking Away |

The sim doesn't apply choice-level extras, so real engaged play runs a little higher. `tools/check.sh` also plays two whole runs through the real UI (`tools/ci/autoplay.gd`) and fails on any script error or stuck screen.

## Decisions to review (Andrew: veto any)

All are one constant or data file each. Full reasoning in `docs/design/v01-loop.md`.
- Run length: 8 weeks. Sleep: +3 energy. Morning of service: 2 hours; +1 hour costs 2 energy.
- New-door answer rate 35% on Saturday and 25% on Thursday (was 26.5%).
- Polite refusers stop answering return visits after 2 conversations.
- Exposure wears conviction down by half its size; conviction drifts −3 a week.
- Names: the coworker is **Dana**; the grandparent is **Grandma**; the sibling is **Micah**, a younger brother; the Sister Who Talks is **Sister Marin** (dialogue-context.md's own example name); the service partner is **Eli** (or **Naomi** if you play a sister); house #9's neighbor is **Daniel** (cast.md § 5.2's Householder of Note). Placeholders in dialogue: "the Castillo boy", "Jess", "Ruth" in Grandma's album. All names are one constant each in `game_state.gd`, or a line in a timeline.
- Beats I placed that go a step beyond cast.md's list: Micah moving into his own apartment (week 7), and Grandma's photo of Ruth "who left". Both are flagged in their files. Dialogue lines in the month-end talks, the five endings, the study session, and the activities are drafts, marked `# TODO: authenticity check`.
- The Dialogic autoload uses a `res://` path, so fresh clones import cleanly.

## Open questions for Andrew

- Is **Daniel** the right v0.1 Householder of Note (cast.md § 8 Q3)? He's built at #9 because that house's returning branch already leaned that way.
- Sibling: older or younger, and a name (cast.md § 3.2 leaves both open). Currently younger brother Micah.
- Every new line is a draft marked `# TODO: authenticity check`. The ones I'm least sure of are Dana's "It's not church, it's the Hall" correction, the study-session cadence, and whether a publisher would call the study aid "the lesson book".

## Next step

Play it. Then: show who's in each seat at the Hall; an on-screen comment moment at the Sunday Lighthouse Study for players who prepared; endings that remember Daniel, Micah, and Dana.
