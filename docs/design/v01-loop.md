# v0.1 Loop — "The Season"

> How a run of v0.1 plays, start to finish. Companion to `gdd.md` (§§ 4–5, 8, 12). Every number here is a tunable constant; the source is named next to each. Andrew: anything marked **(call)** was decided without you. Veto freely.

## Shape of a run

- **Eight weeks, two months.** (call) GDD § 12 asks for one month to "make a tester feel a specific something". Two months lets month 1 teach the loop and month 2 carry the consequences into an ending. `GameState.RUN_WEEKS`.
- **New Game:** you choose your first name, whether the congregation calls you Brother or Sister, and whether your parent in the Truth is your mother or father (cast.md § 3.1, GDD § 7).
- **Each week** runs Sunday → Saturday, one main activity per day (GDD § 4):

| Day | What's on | Energy |
|---|---|---|
| Sunday | Public Talk + Lighthouse Study at the Hall | −3 |
| Monday | Evening: family worship, personal study, say yes to Dana, or rest | −2 / −1 / −2 / +2 |
| Tuesday | Midweek meeting | −2 |
| Wednesday | Evening: personal study, visit your grandparent, or rest | −1 / −2 / +2 |
| Thursday | Optional field service (fewer people home on a weekday), personal study, or rest | −3 / −1 / +2 |
| Friday | Evening: game night (if invited), personal study, say yes to Dana, or rest | −2 / −1 / −2 / +2 |
| Saturday | Field service with the car group | −3 |

- **Month end** (after Saturday of weeks 4 and 8): you fill in your field service report, and an elder talks with you. What he says depends on your hours, your pioneer commitment, and your meeting attendance.
- **Run end** (week 8): the ending is resolved from your accumulated state and shown as a "five years later" snapshot (GDD § 8).
- **Save:** autosave at the start of each day; Continue resumes it. (call) GDD § 10 says week boundaries; daily is the same single slot, and quitting mid-week no longer loses days.

## Energy (0–10)

- **Sleep restores +3, not a full refill.** (call) A full refill every night made energy meaningless. Three a night makes a pioneer's week a real squeeze: meetings, two mornings of service, evenings, and extra hours don't all fit. A pioneer rests the evening before a service day, and that evening is taken from family worship or game night. `ResourceManager.SLEEP_RECOVERY`.
- Going to bed at 0 energy costs 2 conviction. Running on empty wears belief thin.
- Every button shows its cost. Anything you can't afford is disabled ("Too tired").

## Field service: time is the budget

- **A morning out is two hours**, eight 15-minute stops on the map. Hours are time in service, so a morning is worth 2.0 hours whatever happens at the doors. (call) Andrew's encounter doc assumes about 25 doors a session; each house on the map stands in for a stretch of the street.
- **Keep going another hour:** +4 stops for −2 energy. That's how pioneer hours get made.
- **Stop costs:** a new door takes 1 stop; a return visit 2 (guaranteed home, the conversation continues); a Bible study 4 (a full hour, guaranteed home).
- **Chance someone answers a new door:** 35% on Saturday, 25% on Thursday. (call) The encounter doc's 26.5% left most mornings with one or two conversations.
- **Return visits and studies persist** across weeks as appointments on the map. Refusals, tracts, and not-at-homes reset each week.
- **Polite refusers stop answering** after two return conversations. (call) They agreed to end the conversation, not to start one; the car's in the driveway and nobody comes. Curious seekers keep answering. `FieldService.POLITE_REFUSER_RETURN_PATIENCE`.

The decision on the map: known people or new doors? The appointments are guaranteed and cost more time. New doors are a gamble.

## Monthly commitment

On the first Sunday of each month the auxiliary pioneer application is on the table at the back of the Hall: **30 hours** (dialogue-context.md § 3).
- Apply: +3 elder standing now. Meet 30 hours: the Coordinator's affirmation (+elders, +conviction, doubt eases). Miss it: an "encouragement" conversation (−elders, doubt rises).
- Don't apply: no pressure, no praise. Month end is judged on attendance and whether you went out at all.

## Conviction and doubt

- **Conviction (visible, 0–100)** is what you're holding on with. Meetings, personal study, family worship, and fruitful service raise it. It drifts down 3 a week on its own (faith takes upkeep), and **every exposure also wears it down by half as much**, so the visible meter is the hidden one's shadow. (call)
- **Doubt (hidden, 0–100)** comes from exposure, meaning things you hear, see, and can't un-notice. Succeeding at a door no longer erases doubt. (The old rule made the gated content unreachable for anyone playing well.)
- **Conviction buffers exposure:** each exposure is scaled by `1.5 − conviction/100` (×0.5 at 100 conviction, ×1.5 at 0). (call) `DoubtMeter.expose()`.
- Exposure sources: the apostate, a householder's reasonable "no", the Householder of Note's questions, off-script honesty, skipped meetings, the inner voice once it has started (≥40), family and coworker beats, and the "look it up yourself" branch of personal study.
- Relief sources: a "successful meeting" (you did personal study during the week, so you had an answer at Sunday's Lighthouse Study), game night, your grandparent, confiding in the elders, and elder affirmation. Plain attendance sustains conviction but doesn't erase doubt.
- Targets, checked by `tools/ci/tests/test_balance.gd`: a dutiful player stays under 40 over eight weeks; a typical player crosses 25 in month 2 (the off-script choices open up just as the routine has become familiar); a player who leans in crosses 40 in month 2. Month 1 is the routine; month 2 is the cracks.

## Standing has consequences

- **Elders:** month-end conversation tone; at ≤ −10 a shepherding call at month end.
- **Congregation:** at ≥ 5 you're invited to Friday game night; seat picker shows who's saving you a seat.
- **Family:** your parent's scenes warm or cool; at ≤ −10 your parent "mentions it to Brother Phillips" (−5 elders).

## Habits: the skill tree

**(call)** The progression layer is a skill tree whose points are your days. There's no XP and nothing to spend. Each track fills with practice, so choosing tonight's activity *is* spending the point, and the energy budget means you can't grow everything. A points-bought tree would turn faith into a stat sheet, which is the satire register the game avoids. Growth from repetition fits GDD pillar 2 ("the player feels their character changing under them") and pillar 4 ("the grind itself is part of the meaning"). Data in `data/habits/*.tres`; logic in the `Habits` autoload.

| Track | Grows with | Forms by itself | The fork (keep one; the other closes) |
|---|---|---|---|
| Ministry | each morning in service | **The car group** (2): a morning costs 1 less energy | 5 mornings: **The second hour** (keeping going costs 1 less) / **A return-visit notebook** (return visits and studies take 15 minutes less) |
| Study | personal study, family worship | **Underlines the answers** (2): personal study costs 1 less | 5: **Ready answers** (exposure wears conviction half as much) / **Reads the whole chapter** (greyed-out choices open 10 doubt sooner) |
| Congregation | each meeting, game night | **Sunday morning** (4): the Sunday meeting costs 1 less | 9: **Comments every week** (+1 elders per prepared comment) / **The friends** (game night costs 1 less and eases doubt 1 more) |
| Home | family worship, visits to Grandma | **Monday nights** (2): family worship costs 1 less | 5: **Keeps the peace** (family losses are 1 smaller) / **Grandma's afternoons** (visits cost 1 less and ease doubt 1 more) |

- **Every fork is the same question:** what gets counted, or who's in front of you. Hours or the people on your route; the answer in the paragraph or the chapter it came from; the elders noticing your comment or the friends saving you a plate; peace at home or the grandmother who keeps a photo of Ruth. Both sides are sincere ways to be a publisher; neither is the doubt option.
- **Lately** is a fifth track that isn't shown at all until doubt first reaches 40. It takes no practice and offers no choice: its habits form by themselves, the morning after doubt crosses the line. **Sitting through it** (40): meetings cost 1 more energy. **Two versions of the week** (55): staying home from a meeting restores 1 energy. The routine that got easier gets heavier again, and the game never says why. This is GDD § 5.2's "faint, ambiguous indicator".
- **Timing.** First habits land in weeks 1–2 and teach the system; forks open in weeks 3–5, leaving a month to live with the choice. A habit that forms shows as a small card the next morning; a fork opens the whole tree and waits for your pick.
- **Effect** (balance sim, same seed): devout runs pioneer more easily (Regular Pioneer 58 of 60 runs, from 34), curious runs spiral a little faster (median doubt 68, from 62), typical and drifting are about unchanged. Lately appears in about three quarters of curious runs and one in ten typical ones.
- Effects are named modifiers (`Habit.modifiers`) that each system reads through `Habits.modifier(key)`; thresholds are each habit's `practice` / `min_doubt`. Greyed-out choices in timelines check `DoubtMeter.noticing` (doubt plus habits), while the inner voice and the reveal still read `DoubtMeter.value`.

## Endings (week 8)

Resolved in order; first match wins. Texts follow the BACKLOG tone notes and are drafts pending authenticity review.

1. **The Regular Pioneer** — met auxiliary pioneer both months, conviction ≥ 60, doubt < 40.
2. **The In-Fold Quiet Life** — doubt < 40, attended most meetings.
3. **Keeping Up Appearances** — doubt ≥ 55 but still attending and standing with elders ≥ 0 (GDD § 8 "Stay In Doubt").
4. **Walking Away** — doubt ≥ 70 and attendance fell off.
5. **The Quiet Fade** — everything else: attendance fell off without a decision (BACKLOG: "the most common real outcome").
