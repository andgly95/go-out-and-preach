# STATUS

Last updated: 2026-05-23

## Current milestone

**M4.1 — Territory Variety: queued for next session.** Goal: expand
the 12-house Maple Street territory beyond a single archetype so
doors have real texture. Per the `goop-character` skill, scope is
Hostile Slammer (full implementation, no dialogue subagent needed)
+ Curious Seeker (structural only; M4.2 dialogue subagent fills
line text). Apostate is reserved for a dedicated M4.3 session per
the skill's special-case clause. The M4.1 initial prompt with
Phase 1 design questions is staged in the prior conversation,
ready to paste at the start of the next session.

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
scenes were added. The off-script "Why is that for you?" choice in
`polite_refuser_v1.dtl` E3d is gated on `DoubtMeter.value >= 25`
via Dialogic's native `[if] [else=disable]` inline modifier — the
choice stays visible but unclickable until the threshold is met. The
threshold-40 reveal plays a single one-shot internal-voice line
(`data/dialogues/internals/reveal_40.dtl`) the next time the player
enters a door-knock conversation after crossing 40. A debug-only
inspector (CanvasLayer + Panel, `OS.is_debug_build()`-gated, F9
toggle, Shift+↑/↓ nudges by ±10) is instantiated by `door_knock.gd`
in debug builds only. No production HUD readout per CLAUDE.md.

## Locked design decisions this session (M4)

- **Choice-selected hook = `Dialogic.Choices.choice_selected`**, not
  a new SignalBus signal and not a `[signal arg=...]` line per
  choice. Verified in Dialogic 2.0-alpha-19 at
  `addons/dialogic/Modules/Choice/subsystem_choices.gd:6`. The
  handler in `door_knock.gd` connects once at `_ready` and filters
  by `info["text"]`. Rationale: timeline content stays untouched;
  the doubt trigger is a pure system listener.
- **REFUSED state is NOT split.** Walk-away and polite-refusal both
  resolve to `House.State.REFUSED`. The two-trigger distinction
  (T2 walk-away +2 vs T3 polite refusal +1) is made at the firing
  site in `door_knock.gd`, not in the enum. Reasoning: M2/M3
  contract is preserved; doubt math doesn't leak into entity state.
- **N = 25 for the gated-choice threshold.** Provisional. High
  enough that a fresh character can't reach it on game 1; low
  enough that two or three Saturdays of drift unlock it without
  needing M5+ surfaces. Marked tunable at post-M4 playtest.
- **Threshold-70 full-visibility behavior is OUT of M4.** CLAUDE.md
  references it ("fully visible at 70") but the scope guard in the
  plan was explicit. M4 emits `SignalBus.doubt_threshold_crossed(70)`
  on the upward crossing; no listener consumes it yet.
- **Debug panel is opt-in even in debug builds.** F9 toggles
  visibility; default hidden. A debug build should still feel
  production-like unless the developer asks for the panel.
- **T1 filter via choice text is intentionally brittle.** Flagged
  as a tightening target — see "Post-M4 playtest priorities" below.

## Completed this session (M4)

- **`scripts/systems/doubt_meter.gd`** — new autoload. Clamped 0–100,
  threshold-crossing detection (40 + 70 upward only), reason-tagged
  event log (ring buffer, max 10). `apply(delta, reason)` is the
  only public mutator. T4 (Saturday-zero-RV) listener lives here —
  fires on `SignalBus.day_advanced` when the new phase is SUNDAY
  and the territory contains no `RETURN_VISIT_SCHEDULED` house.
- **`project.godot`** — `DoubtMeter` autoload registered between
  `ResourceManager` and `TerritoryManager`. `reveal_40` added to
  `directories/dtl_directory`.
- **`data/dialogues/polite_refuser_v1.dtl`** — single inline modifier
  appended to the E3d choice line: ` | [if DoubtMeter.value >= 25]
  [else=disable alt_text=""]`. No text change, no branch change. The
  expanded comment above the choice now documents the M4 wiring,
  including the text-match constant in `door_knock.gd`.
- **`data/dialogues/internals/reveal_40.dtl`** — new one-line
  timeline, no character joined. Marked
  `# AUTHENTICITY CHECK PENDING`; reviewed at post-M4 playtest.
- **`scripts/ui/door_knock.gd`** — five new firing sites:
  - T1 (off-script taken) via `Dialogic.Choices.choice_selected`
  - T2 (walk-away) inside `_on_walk_away_pressed`
  - T3 / D1 / D2 (outcome-driven) inside `_on_dialogic_signal`,
    keyed by the same arg strings that already route to House.State
  - Reveal-40 chain: `consume_reveal_40` → play reveal first → chain
    to householder timeline via the existing `_on_timeline_ended`
  - Debug panel instantiation, `OS.is_debug_build()`-gated
  T4 (Saturday-zero-RV) is in `doubt_meter.gd` itself, listening on
  `SignalBus.day_advanced`.
- **`scenes/dev/doubt_debug.tscn` + `scripts/ui/dev/doubt_debug.gd`**
  — debug inspector. CanvasLayer (layer=100) with current value and
  last-10 event log. F9 toggles. Shift+↑ adds 10, Shift+↓ subtracts
  10. Reasons in the log distinguish gameplay events from debug
  nudges (`debug_add`, `debug_subtract` vs `outcome_refused`,
  `walked_away`, etc.).

## M3 silent decisions audited and addressed

Surfaced before M4 planning. Six inert for M4; two material.

| Decision (where) | M4 handling |
|---|---|
| `timeline_ended` safety net defaults to REFUSED (`door_knock.gd:76-85`) | Preserved. The reveal-then-householder chain reuses the same handler with an explicit `_reveal_pending` check before the REFUSED safety net. |
| `_dialogue_id` derived from timeline file basename (`door_knock.gd`) | Inert; M4 timelines have unique basenames. |
| `DialogicResourceUtil.update_directory()` called per door-knock load | Preserved. M4 adds `reveal_40` to the project-settings directory map too, so both code paths resolve. |
| `POLITE_REFUSER_*` constants baked into `TerritoryManager` | Inert for M4. Migrates to data tables when a second archetype arrives. |
| Publisher lines anonymous in the timeline | Inert. Worth noting if M5+ embodies the publisher in a meeting scene. |
| **No SignalBus signal for choice selection** | **Resolved.** `door_knock.gd` listens directly to `Dialogic.Choices.choice_selected`; no SignalBus signal added. |
| **REFUSED state collapses polite-refusal and walk-away** | **Resolved at the firing site.** Two triggers (T2, T3) fire from distinct handlers in `door_knock.gd`; `House.State` unchanged. |
| No debug UI surface anywhere | M4 introduces the first one, `OS.is_debug_build()`-gated. |

## M2 silent decisions audited and addressed (retained from prior session)

| Decision | M3 handling |
|---|---|
| `outcome_label()` strings hardcoded in `territory_manager.gd` | Dialogue runner emits `House.State` enum values directly via `[signal]`; no new label strings. |
| `NOT_VISITED` has no label string; mid-conversation exit was undefined | **Locked: ESC/Leave → REFUSED.** `NOT_VISITED` stays a starting state only. |
| `"Householder of %s"` label hardcoded | Retired. Replaced with a small dim "House #N" badge top-right. Dialogic's name label takes over inside conversations. |
| `WEEKS_PER_MONTH = 4`, `HOURS_PER_KNOCK = 0.25` | Untouched. Flag for gate-playtest balance feedback. |

## M4 trigger / decrement table

| # | Event | Δ | Where it fires | Reason key |
|---|---|---|---|---|
| T1 | Off-script "Why is that for you?" chosen | +3 | `door_knock.gd::_on_choice_selected` | `offscript_why_taken` |
| T2 | Walk-away (ESC / Leave button) mid-conversation | +2 | `door_knock.gd::_on_walk_away_pressed` | `walked_away` |
| T3 | Polite refusal outcome | +1 | `door_knock.gd::_on_dialogic_signal` (arg=REFUSED) | `outcome_refused` |
| T4 | Saturday completed with zero return visits | +2 | `doubt_meter.gd::_on_day_advanced` on SUNDAY entry | `saturday_zero_rv` |
| D1 | Tract-left outcome | -1 | `door_knock.gd::_on_dialogic_signal` (arg=TRACT_LEFT) | `outcome_tract_left` |
| D2 | Return-visit-scheduled outcome | -2 | `door_knock.gd::_on_dialogic_signal` (arg=RETURN_VISIT_SCHEDULED) | `outcome_return_visit_scheduled` |

Average ~8-door Saturday (1 RV, 1 tract, 5 refused, 1 walkaway, 0
off-script): -2 + -1 + 5(+1) + 2 + 0 = **+4 net drift per session.**
Off-script choices accelerate it (+3 each). Both intentional.

## Gate verification — Andrew's checklist

**Playtest completed 2026-05-23. All structural items confirmed.
M3 gate criterion held. M4 quality bar held.** Checkboxes are not
retroactively filled — the playthrough happened in the Godot
editor and Andrew reported the pass directly. Checklist retained
below for session-history continuity and future re-verification
after content changes.

**M3 structural (retained from prior session — still required):**

- [ ] Editor opens with no Dialogic plugin errors in the Output
      panel. (Warnings about `default_background.tscn` and
      `default_portrait.tscn` UIDs falling back to text paths are
      benign Dialogic-internal warnings.)
- [ ] `Dialogic` and `DoubtMeter` both appear in
      `Project → Project Settings → Autoload`. Order:
      `SignalBus → TimeManager → ResourceManager → DoubtMeter →
      TerritoryManager → Dialogic → PlayerState`.
- [ ] Fresh game → SATURDAY → enter a door → all four E2 choices
      visible. "Why is that for you?" appears **disabled** (greyed
      out) since DoubtMeter.value starts at 0 < 25.
- [ ] Each non-gated terminal node returns to the map with the
      correct outcome (REFUSED / TRACT LEFT / RETURN VISIT).
- [ ] Walk away (ESC or Leave button) mid-conversation → REFUSED.
- [ ] HUD Hours value increments by exactly 0.25 per resolution.

**M4 behavior:**

- [ ] In a debug build, F9 opens the doubt inspector. Current value
      reads 0; event log reads "(no events)".
- [ ] Knock a few doors with varied outcomes. Confirm:
      - Polite REFUSED outcome → `+1 outcome_refused` in the log.
      - TRACT_LEFT outcome → `-1 outcome_tract_left`.
      - RETURN_VISIT_SCHEDULED outcome → `-2 outcome_return_visit_scheduled`.
      - Walk-away → `+2 walked_away`.
      - Picking "Why is that for you?" (once enabled) → `+3 offscript_why_taken`.
- [ ] Value clamps at 0 and 100; events that would push past the
      clamp produce no log entry.
- [ ] Shift+↑ in the debug panel adds 10 (`+10 debug_add`); Shift+↓
      subtracts 10. Push the value past 25, return to a door,
      confirm "Why is that for you?" is now **enabled**.
- [ ] Push the value past 40 via Shift+↑, exit and re-enter a door.
      The reveal-40 line plays once, no portrait, then the householder
      timeline starts normally.
- [ ] Re-enter another door. The reveal does NOT play again.
- [ ] Push the value past 70. No special behavior at this milestone
      (correct — M4 scope limit).
- [ ] Walking away during the reveal-40 line resolves the house as
      REFUSED, does NOT chain into the householder timeline, and
      logs `+2 walked_away`.
- [ ] Finish a Saturday (advance the day with no RETURN_VISIT in
      the territory) → on the SUN transition, log shows
      `+2 saturday_zero_rv`. Repeat with one RV in the territory →
      no entry on the next SUN transition.
- [ ] In a non-debug build (or with `OS.is_debug_build()` returning
      false), the debug panel does not instantiate at all and F9 is
      a no-op.

**M3 gate criterion (still required — collapses into the same
session):**

- [ ] A playthrough of one Saturday's field service (4–8 doors)
      makes you feel something specific. Not a verdict, not a
      catharsis — a specific resonance with the texture of the
      activity. If yes: proceed to M5. If no: stop, redesign the
      door-knock minigame before M5, per CLAUDE.md gate clause.

**M4 quality bar:**

- [ ] Doubt feels invisible until it doesn't. The reveal-40 line
      lands ambiguously enough that a tester isn't sure if they
      imagined it.

## Post-M4 playtest priorities

**Playtest 2026-05-23 did not surface specific concerns on any of
these.** Carried forward as available tuning levers — touch only if
a future session reveals an issue. Listed explicitly so they don't
drift into "open design questions" purgatory:

- **N = 25 calibration.** Does the off-script unlock feel earned
  by the time the player reaches it? Too early = the breach loses
  weight. Too late = the player never feels the agency expand.
  Adjust in `polite_refuser_v1.dtl` E3d.
- **Reveal-40 text.** "A second on the porch you don't remember
  being there before." is a draft. Run it through
  `dialogue-context.md` § 2-8 review. Replace if it reads as
  outsider fiction or telegraphs the mechanic.
- **Debug panel ergonomics.** F9 toggle + Shift+↑/↓ is a
  developer-affordance guess. If the panel actively gets in the
  way during playtest, simplify; if a feature is missing, note it.
- **T1 brittleness — tightening target.** `OFFSCRIPT_CHOICE_TEXT`
  in `door_knock.gd` is a literal string match against the line
  in `polite_refuser_v1.dtl` E3d. If the line is reworded, the
  trigger silently stops firing. Acceptable for M4 (line is
  M3-validated) but eventually replace with a Dialogic choice tag,
  metadata field, or `[signal]` shim so the trigger doesn't depend
  on prose. Investigate once a second timeline or archetype lands.

## Roadmap after M4

- **M4.1 — Territory Variety** (next session). Hostile Slammer
  (full) + Curious Seeker (structural only). New distribution
  across the 12 houses. Apostate slot held with placeholder.
  Phase 1 design questions: BIBLE_STUDY_STARTED enum extension
  vs. collapse, Hostile Slammer doubt delta calibration,
  distribution policy, Hostile Slammer scene integration.
- **M4.2 — Curious Seeker dialogue subagent pass.** Replaces
  `# DRAFT PENDING` placeholders in the M4.1 timeline. Standalone
  content session per the goop-character skill's Phase 3 handoff.
- **M4.3 — The Apostate.** Dedicated session per the skill's
  special-case clause. New +doubt-on-REFUSED code path,
  three-flavor authoring (Hostile / Wounded / Gentle),
  calibration-sensitive deltas. Likely the highest-stakes
  authenticity session in the project so far.
- **M4.4+** (optional, post-v0.1 polish) — Lonely Elderly,
  Disillusioned Catholic, Hostile Christian as remaining
  archetype variety. Not required for v0.1 (GDD § 12 mandates
  three archetypes; Polite Refuser + Curious Seeker + Apostate
  satisfies that).
- **M5 — Meeting Scenes** (per GDD § 13). `meeting_hall.tscn`
  with seating, speaker portrait, audience. Two meeting types:
  Sunday Public Talk and Tuesday Midweek. Light dialogue scene
  with social positioning choices. Conviction / Standing effects.
  Doubt hooks at meetings surface "Witnessing elder hypocrisy"
  and "A failed prayer in a moment of need" per GDD § 5.2. M4
  left the meter in place; M5 wires content surfaces into it.

## Open / deferred for next session

- **M4.1 — Territory Variety.** Add Hostile Slammer (full
  implementation) and Curious Seeker (structural only) to the
  12-house Maple Street territory. Update distribution. The
  initial prompt with Phase 1 design questions is in the prior
  conversation; the `goop-character` skill drives phase
  structure once invoked.
- **`UNSURE:` flag on line 39** of `polite_refuser_v1.dtl` — "You
  have a good one" register check. Same status as prior session.
- **`dialogue-style-guide.md`** — still a stub. Populate after
  playtest confirms which voice choices held up. Now also wants a
  note on internal-voice cadence based on the reveal-40 line.
- **Dialogic editor and the explicit autoload path.** Same caveat
  as M3: opening in the editor may rewrite to UID form. Now
  applies to `DoubtMeter` as well — should stay an explicit
  `res://` path until the upstream fix lands.
- **`tools/bootstrap_polite_refuser_dch.gd`** — kept committed.
- **M1 silent decisions** still unresolved by user direction.

## Known gaps / deferred

- **Threshold-70 full visibility** — later milestone. M4 emits the
  crossing signal but nothing listens.
- **Save/load** — M7. DoubtMeter state is in-memory only.
  Territory state and Dialogic timeline position too.
- **Settings menu** — M7.
- **Real portraits and backgrounds** — placeholder ColorRects
  through M3. Art pass post-gate.
- **Other archetypes** (Hostile Slammer, Curious Seeker, Apostate,
  etc.) — later content milestones. Apostate is the archetype
  where doubt triggers want extra texture per dialogue-context.md
  § 6, so M4's outcome-keyed firing will likely grow per-archetype
  multipliers when that lands.
- **NOT_HOME outcome** — Polite Refuser conversation can't produce
  this. NOT_HOME stays a territory-level mechanic.
- **Meeting / family doubt triggers** — M5 / M6.
- **Doubt decrement events beyond the door** (elder affirmation,
  confession scenes) — M5+, when the surfaces exist.
- **Multi-week territory state** — T4 currently scans for any
  `RETURN_VISIT_SCHEDULED` house in the current territory. With no
  M7 save/load and no week-level reset, this is a one-Saturday
  approximation. Refine when multi-week state lands.

## Open design questions

GDD § 15 question 5 ("how explicit is doubt UI at threshold 70")
remains live — M4 deliberately deferred. Question 6 (fourth-wall
break) is still aspirational. Nothing newly opened by M4 itself.
