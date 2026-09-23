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
- **Save:** autosave at the start of each week; Continue resumes it (GDD § 10).

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

## Endings (week 8)

Resolved in order; first match wins. Texts follow the BACKLOG tone notes and are drafts pending authenticity review.

1. **The Regular Pioneer** — met auxiliary pioneer both months, conviction ≥ 60, doubt < 40.
2. **The In-Fold Quiet Life** — doubt < 40, attended most meetings.
3. **Keeping Up Appearances** — doubt ≥ 55 but still attending and standing with elders ≥ 0 (GDD § 8 "Stay In Doubt").
4. **Walking Away** — doubt ≥ 70 and attendance fell off.
5. **The Quiet Fade** — everything else: attendance fell off without a decision (BACKLOG: "the most common real outcome").
