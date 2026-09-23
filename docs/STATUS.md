# STATUS

Last updated: 2026-09-23. One page, overwritten each session. History lives in git and `docs/archive/`.

## What's playable

A full run: New Game (name, Brother/Sister, Mom/Dad) → eight weeks → two month-end reports with an elder → one of five endings. See `docs/design/v01-loop.md` for the whole loop.

- **Day planner.** Each day shows its options with energy costs: meetings (attend or stay home), Thursday/Saturday service, evening activities (family worship, personal study, visiting Grandma, game night once the congregation warms to you, saying yes to Dana, rest). Sleep restores 3 energy, not a full refill.
- **Field service is a time budget.** Two hours per morning, plus "keep going" for energy. Return visits and studies persist as appointments that are always home; polite refusers stop answering after two. The map dims houses there's no time left for.
- **Month end.** Auxiliary pioneer sign-up on the first Sunday of each month (30 hours). A report slip, then one of four elder conversations (affirmation, "encouragement", shepherding with an optional confession, a steady month).
- **Doubt is exposure.** Success no longer erases it; conviction buffers it and wears down with it. Personal study prepares you for Sunday, and that "successful meeting" is what eases doubt.
- **Autosave** at the start of each day; Continue works.
- **Habits, a skill tree whose points are your days.** Four tracks (Ministry, Study, Congregation, Home) fill as you do the thing. Each forms one habit by itself (the car group, Sunday morning…), then opens a fork: keep one, and the other closes for the run. The choice is always what gets counted or who's in front of you. *Lately*, a fifth track, doesn't exist until doubt first reaches 40; it fills by itself and makes meetings heavier. The card on the left of the day screen shows the tree at a glance, and the full tree opens over it. See `docs/design/v01-loop.md` § Habits.

- **Story beats** (`data/beats/`): thirteen short scenes across the eight weeks. Coffee with your parent, late-night texts from your brother Micah, Dana's invitation and later her 10pm call and her lunchtime question, Sister Marin in the lobby, the parked car with your service partner, family dinner, the lamp left on, the boxes in the hallway. They come from cast.md's "common beats", and several branch on what you've been doing.
- **Activity scenes:** family worship, personal study, Grandma, game night, and Dana each have a sequence of authored scenes, then a quieter repeat. Personal study's "look the verse up yourself" branch (doubt ≥ 25) echoes in Daniel's study.
- **Daniel** (house #9, the Householder of Note): four study sessions that progress (sources, the half-quoted verse, "do they get to keep their friends?", his decision), then he ends it or keeps going for your sake.

- **Feel:** meters show a fading "+2" / "−1" when they change, even across scene changes. The seat picker names who you'd sit beside. After the Lighthouse Study comes the paragraph question: raise your hand with the answer you prepared, get called on anyway when you didn't, or (if you looked the verse up and doubt has passed 40) mention the rest of the verse.
- **Opening and endings:** a short opening scene establishes who you are (cast.md § 2). Month 2's pioneer prompt remembers month 1. Endings carry lines for Daniel, Micah, Dana, Grandma, and the elders, depending on what happened.

## Balance (tools/ci/tests/test_balance.gd, 60 runs per style)

| Style | Doubt at wk 8 (median) | Endings |
|---|---|---|
| devout (pioneer, never misses; keeps what's counted) | ~16 | Regular Pioneer (nearly all) |
| typical (random forks) | ~24 (top tenth 43+) | mostly In-Fold, some Fade |
| curious (honest choices, says yes to Dana; keeps the people side) | ~68 | Keeping Up Appearances, Fade, some In-Fold |
| drifting | ~55 | Quiet Fade, Walking Away |

The sim doesn't apply choice-level extras, so real engaged play runs a little higher. `tools/check.sh` also plays two whole runs through the real UI (`tools/ci/autoplay.gd`) and fails on any script error or stuck screen.

## Decisions made (revisit any time)

Andrew delegated design decisions (CLAUDE.md § How We Work). These are settled; each is one constant or data line. Reasoning in `docs/design/v01-loop.md`.
- Run length 8 weeks. Sleep +3 energy. A morning of service is 2 hours; +1 hour costs 2 energy. New doors answer 35% on Saturday and 25% on Thursday.
- Polite refusers stop answering return visits after 2 conversations. Exposure wears conviction down by half its size; conviction drifts −3 a week.
- Autosave daily (GDD § 10 said weekly). The Dialogic autoload uses a `res://` path.
- **Daniel** (house #9) is the v0.1 Householder of Note (cast.md § 8 Q3).
- Cast names: sibling **Micah**, a younger brother; coworker **Dana**; grandparent **Grandma**; the Sister Who Talks **Sister Marin**; service partner **Eli** (or **Naomi** for a sister). Background names: the Castillo boy, Jess, Ruth.
- Beats beyond cast.md's list: Micah moves into his own apartment (week 7); Grandma keeps a photo of Ruth, who left.
- Wording: Dana gets gently corrected on "church" (dialogue-context.md § 5 says members do this); the study aid is "the study book".
- **Habits instead of a points-bought skill tree** (v01-loop.md § Habits): practice is the only currency; each fork weighs what gets counted against who's in front of you; *Lately* forms from doubt (40, 55) and stays hidden until then. Every number is one field in `data/habits/*.tres`. The habit lines are drafts: "when to say you'll pray about it" and "Sunday runs itself" most need your ear (`# TODO: authenticity check`).

## Art

14 background slots and house #1 are wired and waiting; each falls back to current art until its file exists. `docs/design/asset-brief.md` lists every file, spec, and prompt; `bash tools/art_status.sh --missing` shows what's left. Non-Claude agents (Codex) follow `AGENTS.md`.

## What would still help from Andrew

Nothing blocks. New lines are drafts from the design docs, marked `# TODO: authenticity check`. If something in a playthrough rings false — a phrase no publisher would use, a beat that wouldn't happen that way — note it, and it gets fixed.

## Next step

**Play it**, a full run from New Game with no debug keys (about an hour), then tell me where it went flat, and whether the forks felt like choices. Candidates after that: habits that speak (the elder's month-end talk and the ending remembering what you kept); deeper door conversations (most are a single choice); a Householder of Note beat in the ending itself; audio (the GDD's sparse field-recording texture).
