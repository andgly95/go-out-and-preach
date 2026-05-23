# STATUS

Last updated: 2026-05-23

## Next session (queued)

**M4-LF1 — Territory Map Visual Polish.** Andrew pivoted the next-
session priority from M4.3 Apostate to a look-and-feel pass on the
territory map. Reference mockup (ChatGPT-generated, 2026-05-23):
`docs/design/mockups/territory_map_v1.png`. AI asset generation
prompts staged at `docs/design/mockups/asset_prompts.md` for Andrew
to run between now and next session. Decisions locked at end of
M4.1+M4.2 session: (1) AI-gen art to match the mockup; (2) full
mockup in one session assuming assets are ready; (3) M4.3 Apostate
becomes the session after this one.

Scope for M4-LF1 (next session will Phase-0/Phase-1 it properly):
- Three-column layout: info card / map / house detail panel
- Top banner with branding + 6-resource HUD (Conviction, Elders,
  Congregation, Family, Energy, Hours This Month)
- Painted territory background + 12 painted house tiles + parked-
  car decoration (assets from AI gen pre-session)
- Color-coded outcome badges, numbered medallions, decorative
  ornament dividers, scripture quote in info card, "End Field
  Service" button bottom-right
- New systems exposed by the design:
  - Hover/selection state for houses (preview detail before click)
  - Pre-visit detail panel content ("No prior contact." default)
  - "Today's progress" aggregator (counts of TRACT_LEFT /
    RETURN_VISIT / BIBLE_STUDY for current territory)
  - End Field Service button → TimeManager day advance to SUN

## Current milestone

**M4.2 — Curious Seeker dialogue subagent pass: complete (same
session as M4.1).** The dialogue subagent picked the grieving-
friend canonical opening from cast.md § 6.2 and wrote 12 speaking
lines plus the four reworded E3 choice strings. Branch topology,
portrait beats, signal args, and `[end_timeline]` calls all
preserved exactly as M4.1 laid them down. The off-script choice
was reworded from M4.1 placeholder "Answer the question genuinely"
to **"I don't know. Honestly."** — `door_knock.gd::OFFSCRIPT_CHOICE_TEXTS`
updated in the same session to match. Three `# UNSURE` flags
embedded for Andrew's playtest review (see "Post-M4.2 playtest
priorities" below).

**M4.1 — Territory Variety: complete (headless boot clean; gate
playtest pending Andrew).** Maple Street's 12 houses now hold three
archetypes: 6 Polite Refuser, 3 Hostile Slammer, 2 Curious Seeker,
and 1 reserved-Apostate slot (House #7) using Polite Refuser as
placeholder until M4.3. Hostile Slammer is fully implemented as a
~1.5s no-Dialogic scene (cast.md § 6.1 line pool, single transient
label, no portrait, REFUSED outcome with per-archetype doubt
override = +0). Curious Seeker structural timeline shipped in M4.1
with placeholder lines; **M4.2 filled the line text in the same
session** (see above) since the project ran both back-to-back.

## Previous milestone

**M4 — Doubt Mechanic: complete and playtest-passed (2026-05-23).**
Integrated M3+M4 Saturday-of-doors playthrough held both quality
bars: the M3 gate criterion (the loop feels like a specific
something) and the M4 quality bar (doubt feels invisible until it
doesn't; reveal-40 lands ambiguously enough that a tester isn't
sure if they imagined it). Post-M4 priorities (N=25 calibration,
reveal-40 text, debug panel ergonomics, T1 brittleness) did not
surface specific issues during playtest; carried forward as
available tuning levers, not blockers.

The hidden 0–100 doubt meter is wired. Four trigger events and two
decrement events fire from existing M1–M3 surfaces; no new gameplay
scenes were added in M4. The off-script "Why is that for you?"
choice in `polite_refuser_v1.dtl` E3d is gated on
`DoubtMeter.value >= 25` via Dialogic's native `[if] [else=disable]`
inline modifier. The threshold-40 reveal plays a single one-shot
internal-voice line (`data/dialogues/internals/reveal_40.dtl`) the
next time the player enters a door-knock conversation after
crossing 40. A debug-only inspector (CanvasLayer + Panel,
`OS.is_debug_build()`-gated, F9 toggle, Shift+↑/↓ nudges by ±10) is
instantiated by `door_knock.gd` in debug builds only. No production
HUD readout per CLAUDE.md.

## Locked design decisions this session (M4.1)

Six material decisions surfaced in Phase 1 of the goop-character
skill. Recommendations were accepted on all six.

- **Q1: `House.State.BIBLE_STUDY_STARTED` extends the enum.** Doubt
  delta D3 = **-3** (one stronger than RETURN_VISIT_SCHEDULED's -2;
  reflects months of recurring contact). Curious Seeker forces this
  decision because cast.md § 6.2 and GDD § 6 both distinguish
  "Study Started" from "Return Visit." `outcome_label` returns
  `tr("STUDY STARTED")`.
- **Q2: Hostile Slammer REFUSED doubt magnitude = +0.** Authentic
  reading: the 5-second slam bypasses the social-internalization
  loop that makes Polite Refuser REFUSED sting (+1). Slams are
  easier emotionally because there is no relational residue.
  Implemented as a per-archetype override via
  `Householder.doubt_delta_overrides = { "REFUSED": 0 }`.
- **Q3: Territory distribution is fixed across the project.**
  Hardcoded `DISTRIBUTION` array in `territory_manager.gd`. Same
  houses always have the same archetypes. Reasons: pre-playtest
  stability, author intent (House #7 = Apostate slot for M4.3),
  no save system yet to lock a per-game shuffle. Layout below.
- **Q4: Hostile Slammer scene = inline branch in
  `_start_dialogue_for_pending_house`.** ~40 LOC in `door_knock.gd`.
  Resolves through `_resolve_with_outcome(REFUSED)` — same exit
  path as Dialogic. LeaveButton hidden during the scene; ESC
  suppressed via `_slammer_active` flag. Total scene duration ~1.5s.
- **Q5: Householder construction migrated to `.tres` files.** Three
  resources in `data/householders/`. Same loaded `Householder`
  instance is shared across all houses of an archetype
  (Householders are stateless templates; per-instance state lives
  on `House`). New `doubt_delta_overrides: Dictionary` field added
  to the Householder schema. Pre-stages M4.3 Apostate as a
  content-only addition (no further schema work needed).
- **Q6: Reveal-40 plays first, then the slam.** Extended
  `_on_timeline_ended` to dispatch on `_slammer_after_reveal` after
  reveal_40 finishes. Contrast (ambient inward beat → abrupt
  outward rejection) is on-tone, not disjointed.

**Distribution layout** (4×3 grid, left→right, top→bottom):

```
Row 0:  [1]PR  [2]HS  [3]PR  [4]CS
Row 1:  [5]PR  [6]HS  [7]Apo* [8]PR
Row 2:  [9]CS  [10]PR [11]HS [12]PR
```
\* House #7 plays Polite Refuser until M4.3 lands the Apostate.

## Completed this session (M4.1)

- **`data/householders/polite_refuser.tres`**, **`hostile_slammer.tres`**,
  **`curious_seeker.tres`** — new Householder resources. Stateless
  archetype templates; shared across houses of the same archetype.
  `dialogic_character` is null in all three (confirmed dead code
  at runtime; Dialogic resolves characters via `dch_directory` in
  `project.godot`, not via this field).
- **`data/dialogues/curious_seeker_v1.dtl`** — structural timeline.
  4 publisher choices (magazine offer → TRACT_LEFT, invite to
  study → BIBLE_STUDY_STARTED, return visit → RETURN_VISIT_SCHEDULED,
  off-script genuine answer → REFUSED). Off-script gated on
  `DoubtMeter.value >= 25` via the same inline modifier pattern
  as `polite_refuser_v1.dtl` E3d. All speaking lines as
  `# DRAFT PENDING — dialogue subagent run` placeholders with
  ellipsis stubs (`...`) so the timeline parses. File-top comment
  block documents the branch topology, outcome routing, and a
  coordination note for M4.2 (the off-script choice text must
  match `door_knock.gd::OFFSCRIPT_CHOICE_TEXTS`).
- **`data/dialogues/characters/curious_seeker.dch`** — Dialogic
  character resource. 5 portrait expressions: `neutral`,
  `interested_lean_in`, `genuine_question`, `considering`,
  `warm_thank_you`. All scenes point to the new placeholder
  portrait. Character color softer green-grey vs Polite Refuser's
  beige. Display name = "Householder" (generic, matches PR).
- **`assets/sprites/portraits/curious_seeker/placeholder_portrait.{gd,tscn}`**
  — placeholder mirrors the Polite Refuser pattern: a 240×360
  ColorRect that re-tints per expression name so portrait swaps
  are visually verifiable without art.
- **`scripts/entities/house.gd`** — `BIBLE_STUDY_STARTED` added to
  `State` enum.
- **`scripts/entities/householder.gd`** — `@export var
  doubt_delta_overrides: Dictionary = {}` field added.
- **`scripts/systems/territory_manager.gd`** — full rewrite of
  `_build_default_territory`. New `HOUSEHOLDER_PATHS` dict
  (archetype → .tres path) and `DISTRIBUTION` array (12 entries,
  one per house). `_load_householder_cache` loads each unique
  .tres once with fallback to `polite_refuser` if anything fails
  to load. `outcome_label` gains a `STUDY STARTED` branch. The M3
  `POLITE_REFUSER_*` constants are retired.
- **`scripts/ui/door_knock.gd`** — major extension:
  - `SIGNAL_OUTCOME_MAP` gains `BIBLE_STUDY_STARTED`.
  - `OUTCOME_DOUBT_DELTAS` gains `BIBLE_STUDY_STARTED: -3` (D3).
  - `OFFSCRIPT_CHOICE_TEXT` (single string) → `OFFSCRIPT_CHOICE_TEXTS`
    (Dictionary-as-set). Both PR's "Why is that for you?" and CS's
    placeholder "Answer the question genuinely" fire T1. Still
    text-keyed and therefore still brittle — STATUS carries the
    tightening target.
  - New `_resolve_doubt_delta(outcome_key)` helper: per-archetype
    override > global table. Slammer's REFUSED resolves to +0 here.
  - New `_run_hostile_slammer_scene()`: 0.4s pre / ~0.6s line /
    0.4s post timing, transient Label overlay, random pick from
    `HOSTILE_SLAMMER_LINES` (4 entries including one silent slam),
    no portrait. Resolves through `_resolve_with_outcome(REFUSED)`.
  - New `_slammer_after_reveal` flag chained through
    `_on_timeline_ended` so the reveal-40 → slammer sequence works.
  - `_unhandled_input` and `_on_walk_away_pressed` both gate on
    `_slammer_active` so ESC and the Leave button are suppressed
    during the 1.5s scene (no T2 — nothing to walk away from).
- **`project.godot`** — `dch_directory` and `dtl_directory` both
  gain a `curious_seeker` entry.

## M4 silent decisions audited and addressed

Per the goop-character skill's Phase 0. Five inert for M4.1,
five material — all resolved.

| Decision | Where | M4.1 handling |
|---|---|---|
| Flat dialogue dir (no per-archetype subfolder) | `data/dialogues/` | Inert. `curious_seeker_v1.dtl` sits alongside `polite_refuser_v1.dtl`. |
| `DialogicResourceUtil.update_directory()` per door-knock | `door_knock.gd:_start_dialogue_for_pending_house` | Inert. New `.dch`/`.dtl` entries auto-resolve. |
| `_dialogue_id` derived from timeline basename | `door_knock.gd` | Inert. Empty for Slammer; existing `is_empty()` guard suppresses dialogue_started/ended. |
| `_on_timeline_ended` safety net → REFUSED | `door_knock.gd` | Inert. Reused by Curious Seeker; Slammer never invokes. |
| `current_territory` built fresh per session | `territory_manager.gd` | Inert. M7 brings save/load. |
| **Householders constructed in-code** | `territory_manager.gd` | **Resolved (Q5).** Now `.tres` files; per-archetype overrides have a home. |
| **`OUTCOME_DOUBT_DELTAS` flat outcome→int** | `door_knock.gd` | **Resolved (Q2 + Q5).** Per-archetype override via Householder.doubt_delta_overrides; global table is the default. |
| **`SIGNAL_OUTCOME_MAP` only the M3 three outcomes** | `door_knock.gd` | **Resolved (Q1).** Gained `BIBLE_STUDY_STARTED`. |
| **Empty `dialogue_timeline` falls to push_warning + REFUSED** | `door_knock.gd` | **Resolved (Q4).** Slammer archetype takes the no-Dialogic branch explicitly; warning path only fires on genuine author error now. |
| **Reveal-40 chains via Dialogic.timeline_ended only** | `door_knock.gd` | **Resolved (Q6).** Chain dispatches on `_slammer_after_reveal`. |

## Doubt trigger / decrement table

| # | Event | Δ | Where it fires | Reason key |
|---|---|---|---|---|
| T1 | Off-script choice taken (PR or CS) | +3 | `door_knock.gd::_on_choice_selected` | `offscript_why_taken` |
| T2 | Walk-away (ESC / Leave button) mid-conversation | +2 | `door_knock.gd::_on_walk_away_pressed` | `walked_away` |
| T3 | Polite refusal outcome (PR/CS) | +1 | `door_knock.gd::_on_dialogic_signal` (arg=REFUSED) | `outcome_refused` |
| T3-HS | Hostile Slammer outcome | +0 (override) | `door_knock.gd::_run_hostile_slammer_scene` | `outcome_refused` (suppressed — delta=0) |
| T4 | Saturday completed with zero return visits / studies | +2 | `doubt_meter.gd::_on_day_advanced` on SUNDAY entry | `saturday_zero_rv` |
| D1 | Tract-left outcome | -1 | `door_knock.gd::_on_dialogic_signal` (arg=TRACT_LEFT) | `outcome_tract_left` |
| D2 | Return-visit-scheduled outcome | -2 | `door_knock.gd::_on_dialogic_signal` (arg=RETURN_VISIT_SCHEDULED) | `outcome_return_visit_scheduled` |
| **D3** | **Bible study started (CS BIBLE_STUDY_STARTED)** | **-3** | `door_knock.gd::_on_dialogic_signal` (arg=BIBLE_STUDY_STARTED) | `outcome_bible_study_started` |

Per-archetype overrides via `Householder.doubt_delta_overrides`
(outcome-string → int). Empty dict = use global. T4 still scans
`current_territory.houses` for `RETURN_VISIT_SCHEDULED` only — this
should probably extend to `BIBLE_STUDY_STARTED` too (a study is at
least as protective as a return visit), but it's a small playtest
calibration question, not an M4.1 hold-up. Flagged in priorities.

## Gate verification — Andrew's checklist (M4.1)

**Headless boot: clean. No autoload errors, no .tres parse errors.**
Andrew runs the editor playtest to confirm structural behavior.

**M3 + M4 behavior preserved (regression check):**

- [ ] House #1 (PR): identical to M3 — REFUSED → +1, TRACT_LEFT
      → -1, RV → -2, walk-away → +2, "Why is that for you?" gated
      at doubt 25 then fires +3 when picked.
- [ ] HUD Hours value increments by exactly 0.25 per knock for all
      archetypes.

**M4.1 new behavior:**

- [ ] Territory map shows 12 houses with the Q3 layout. Outcome
      badges read NOT_VISITED initially.
- [ ] House #2 (HS): scene resolves in ~1.5s, outcome REFUSED,
      doubt panel shows NO entry for this knock (+0 override =
      `apply()` early-returns). Pool randomization: 4 consecutive
      knocks at HS doors yield variety (3 lines + 1 silent slam,
      ~75% line / ~25% silent).
- [ ] House #2 (HS): Leave button hidden during the scene; ESC
      pressed during the scene is silently ignored.
- [ ] House #4 (CS): timeline starts, 4 E3 choices visible, off-
      script ("Answer the question genuinely") disabled at doubt 0.
- [ ] House #4 (CS) BIBLE_STUDY_STARTED branch: territory marker
      reads "STUDY STARTED", doubt panel shows
      `-3 outcome_bible_study_started`.
- [ ] House #4 (CS) TRACT_LEFT, RV, REFUSED branches: all reach
      their terminal `[signal arg=...]`, outcomes route correctly
      with the global PR-equivalent magnitudes.
- [ ] Push doubt to 40 via Shift+↑, then knock House #2 (HS):
      reveal_40 line plays, then slam, then REFUSED resolution.
      Both events log correctly. The reveal flag self-clears so
      the NEXT door doesn't re-play it.
- [ ] Push doubt to 25, return to House #4 (CS): off-script choice
      is enabled. Pick it; T1 fires (+3); outcome REFUSED (+1);
      doubt log shows both entries.
- [ ] Walk-away (ESC) during a Curious Seeker conversation: T2
      fires (+2), house resolves REFUSED.
- [ ] All 12 houses can be visited in one session, hours total
      = 3.0, doubt log reads coherently.

**M4.1 quality bar (carry from M4):**

- [ ] The texture difference between knocking a PR door, a slammer
      door, and a seeker door is felt — not narrated. A slammer
      after three polite refusers should land as a small jolt.
      A curious seeker after slams should feel like an unexpected
      door opening. If the variety is invisible, the distribution
      or timing needs tuning, not the mechanic.

## Post-M4.2 playtest priorities

Surfaced by the M4.2 dialogue subagent for Andrew to verify against
lived experience. Each is an `# UNSURE` comment in
`curious_seeker_v1.dtl`; flagged here for visibility, not for fix.

- **"come up" in E1 response** — assumes a stoop/porch with steps.
  May want a flatter alternative ("come in closer", or just "I can
  hear you") depending on how the house background art reads.
- **"let me grab my number for you"** in the BIBLE_STUDY_STARTED
  branch — judgment call vs the more orthodox "would Tuesday or
  Thursday work?" (dialogue-context.md § 5). The subagent went
  with the number-handoff because the CS is the one breaking out
  of routine here; Andrew may prefer the time-slot variant.
- **"pamphlet" rather than "magazine"** in the off-script
  REFUSED branch close — civilian usage but the precise org term
  is "magazine." Subagent kept civilian framing because the
  householder is outside the org.

Also flagged by the subagent as a meta-observation:

- **The off-script closing line names the texture difference**
  ("not just giving me a pamphlet") — edges toward
  dialogue-context.md § 8's "trust the player to notice" red line.
  Kept because the householder is naming her own gratitude, not
  narrating the game's thesis, and the contrast is in *her* mouth.
  Worth re-reading during playtest with that red line in mind.

## Post-M4.1 playtest priorities

Carried forward from M4 plus M4.1 additions. Touch only if a
session reveals an issue.

- **N = 25 calibration** (carried from M4).
- **Reveal-40 text** (carried from M4) — still
  `AUTHENTICITY CHECK PENDING` in `reveal_40.dtl`.
- **Debug panel ergonomics** (carried from M4).
- **T1 brittleness — partially mitigated, still a tightening target.**
  `OFFSCRIPT_CHOICE_TEXTS` is now a multi-entry registry instead
  of a single string. Adding a third archetype's off-script choice
  is a one-line addition. But the mechanism is still text-keyed:
  if a dialogue subagent reworks an off-script line, T1 silently
  stops firing for that line. Eventually replace with a Dialogic
  choice tag, metadata field, or [signal] shim. Re-investigate
  during M4.2 (CS dialogue pass; the placeholder "Answer the
  question genuinely" likely changes).
- **`Householder.dialogic_character` field is dead code.** Set in
  the .tres (always null in M4.1) and the schema, but no consumer
  reads it. Dialogic resolves characters via `dch_directory` in
  project.godot. Candidate for removal in a future cleanup pass;
  left in M4.1 to avoid an unrelated schema migration.
- **Hostile Slammer line pool weighting.** Currently uniform
  random across `["No.", "Not interested.", "Please don't come
  back.", ""]`. The empty (silent slam) at 25% may feel too
  frequent or too rare; profanity is excluded from the pool
  pending playtest. Tunable in `door_knock.gd::HOSTILE_SLAMMER_LINES`.
- **Curious Seeker off-script choice doesn't yet share text with
  Polite Refuser's.** The placeholder "Answer the question
  genuinely" is in `OFFSCRIPT_CHOICE_TEXTS` so T1 fires correctly,
  but M4.2 may reword. Coordination note in `curious_seeker_v1.dtl`
  comment block.
- **T4 doesn't count BIBLE_STUDY_STARTED as a non-zero-RV
  Saturday.** Strict reading: a study should count too (months of
  contact > one-off return visit). If a Saturday with a study and
  no RV still fires T4 (+2), that's slightly wrong. One-line fix
  in `doubt_meter.gd::_territory_had_return_visit_this_week`.
  Held for playtest decision (Andrew may want stricter T4).

## Roadmap after M4.2

- **M4-LF1 — Territory Map Visual Polish (NEXT).** See "Next
  session (queued)" section above. Reference: `docs/design/mockups/
  territory_map_v1.png` + `docs/design/mockups/asset_prompts.md`.
- **M4.3 — The Apostate** (session after M4-LF1). Dedicated session
  per the skill's special-case clause. New +doubt-on-REFUSED code path is the
  next mechanic addition. With M4.1's `doubt_delta_overrides`
  field already in place, Apostate-specific deltas live in
  `data/householders/apostate.tres` (or three variants:
  `apostate_hostile.tres`, `apostate_wounded.tres`,
  `apostate_gentle.tres` per cast.md § 6.6). The +doubt-on-
  positive-outcome semantic does need a small mechanism beyond
  the overlay — likely a per-archetype "positive outcomes also
  cost N" flag, or full custom deltas including positive ones
  (`{"REFUSED": 4, "TRACT_LEFT": 3, ...}`). Surface in M4.3
  Phase 1.
- **M4.4 — Within-archetype variety + remaining archetypes.**
  User-deferred from M4.1 (asked "why not multiple PR characters?";
  answered "scope was archetype variety, not within-archetype").
  Scope: (A) 3 cosmetic Polite Refuser .dch variants + .tres
  distributed across the 6 PR slots, (B) line-pool randomization
  for E2 brush-off line in polite_refuser_v1.dtl, (C) Lonely
  Elderly, Disillusioned Catholic, Hostile Christian as remaining
  archetype variety. Optional for v0.1 (GDD § 12 only requires
  three archetypes).
- **M5 — Meeting Scenes** (per GDD § 13). `meeting_hall.tscn`
  with seating, speaker portrait, audience.

## Open / deferred for next session

- **M4-LF1 — Territory Map Visual Polish.** Highest priority next
  session. Reference mockup at `docs/design/mockups/territory_map_v1.png`,
  asset gen prompts at `docs/design/mockups/asset_prompts.md`. Andrew
  runs AI image generation between sessions; the polish session drops
  the assets into `assets/sprites/territory/` and wires the new
  layout + systems into `territory_map.tscn`. Phase-0 audit at the
  start of next session should cover: silent decisions in the current
  `territory_map.tscn`, the M4 HUD's hidden assumptions, and whether
  the new "Today's progress" aggregator wants per-territory or per-
  session scope.
- **M4.3 — The Apostate (session after M4-LF1).** Three variants per
  cast.md § 6.6 (Hostile / Wounded / Gentle). Doubt deltas
  calibration-sensitive — surface in Phase 1.
- **Three `# UNSURE` flags from M4.2** in `curious_seeker_v1.dtl`
  (see "Post-M4.2 playtest priorities" above) — Andrew verifies
  during the gate playtest.
- **`UNSURE:` flag on line 39** of `polite_refuser_v1.dtl` (carried
  from M3) — "You have a good one" register check.
- **`dialogue-style-guide.md`** — still a stub (carried from M3+M4).
  Populate after Andrew's M4.1+M4.2 playtest confirms which voice
  choices held up.
- **Dialogic editor and the explicit autoload path** (carried from
  M3+M4) — opening in the editor may rewrite the Dialogic autoload
  to UID form. Keep as explicit `res://` path until upstream fix.
- **`tools/bootstrap_polite_refuser_dch.gd`** — kept committed. Now
  worth duplicating to `bootstrap_curious_seeker_dch.gd` if the
  hand-written `curious_seeker.dch` needs to be regenerated for any
  reason (e.g., Dialogic format change). Held — the hand-written
  version works.
- **M1 silent decisions** still unresolved by user direction (carried
  forward).

## Known gaps / deferred

- **Threshold-70 full visibility** — later milestone.
- **Save/load** — M7.
- **Settings menu** — M7.
- **Real portraits and backgrounds** — placeholder ColorRects through
  M4.1. Art pass post-gate.
- **Apostate** — M4.3 dedicated session.
- **Lonely Elderly, Disillusioned Catholic, Hostile Christian** —
  M4.4+ (optional for v0.1; GDD § 12 only requires three archetypes
  and Polite Refuser + Curious Seeker + Apostate satisfies that).
- **Householder of Note** — separate named-NPC arc, not an M4 task.
- **NOT_HOME outcome** — no archetype produces this. NOT_HOME stays
  a territory-level mechanic.
- **Meeting / family doubt triggers** — M5 / M6.
- **Doubt decrement events beyond the door** (elder affirmation,
  confession scenes) — M5+.
- **Multi-week territory state** — T4 currently scans for any
  `RETURN_VISIT_SCHEDULED` house in the current territory; one-
  Saturday approximation until M7 save/load lands.

## Open design questions

GDD § 15 question 5 ("how explicit is doubt UI at threshold 70")
remains live. Question 6 (fourth-wall break) is still aspirational.
M4.1 surfaced no new open questions — every Phase 1 question
resolved this session.
