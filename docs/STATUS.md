# STATUS

Last updated: 2026-05-24 (M5.0–M5.2 ship; M5.3 dialogue queue scoped)

## Next session (queued)

**M5.3 — 9-speech dialogue subagent pool.** Replace the three
`[DRAFT PENDING]` placeholder .dtl files with the full v1 speech
pool: 3 Public Talk speeches (Coordinator), 3 Lighthouse Study
speeches (Strict Elder), 3 Midweek Training speeches (Coordinator).
Plus the 9 hand-authored inner-voice lines that fire on
`DoubtMeter.value >= 40` (one per .dtl). Per the goop-character
one-voice-per-session rule, this is ~6–9 subagent sessions
(Coordinator gets 6 speeches across 2 talk types; one session per
speech keeps voice fresh, or batch by talk type for tighter
coherence). Voice-ground in cast.md § 4.1 (Coordinator) and § 4.2
(Strict Elder); CLAUDE.md legal guardrails (no lifted real-
publication text, Society-of-the-Truth vocabulary throughout).

After M5.3 lands, three .dtl pools become 3-entry each, and
`MeetingManager.pick_speech_for()` last-played exclusion starts
producing observable variety — confirm consecutive Sundays don't
repeat verbatim. Also rewrite the 6 placeholder social-moment
prompt strings in `MeetingManager.SOCIAL_MOMENT_OPTIONS` per the
neighbor identities (Service Partner, Sister Who Talks, Strict
Elder's wife, Lonely Elderly, Parent in the Truth, sit-alone) —
v1 ships authored-by-Claude placeholder copy that should be
sharpened in M5.3 alongside the elder speeches.

**M4.4 — Hostile + Gentle Apostate variants.** Still deferred
below M5.3 per user direction (carry forward).

## M5 — Hall of Witness meeting scenes: M5.0–M5.2 complete (headless boot clean; gate playtest pending Andrew)

GDD § 13 canonical milestone shipped through scaffold + wiring.
Sunday and Tuesday now route through the new meeting flow when the
player clicks ATTEND THE MEETING on the week_view day card; SKIP
THE MEETING fires inline penalties and phase-advances without
entering the meeting scene. Per-talk effects (Conviction, Standing-
Elders) fire on each talk's completion; meeting-level Energy fires
once at meeting close. Inner-voice gating is scaffolded in the .dtl
files at the M4 reveal-40 threshold; placeholder text in italics
sits inside `if DoubtMeter.value >= 40:` blocks awaiting M5.3
content authoring.

**Phase 1 + Phase 1.5 decisions** locked across two prior
conversations (see prior STATUS sections) plus seven material
decisions resolved this session (Phase 1 design block):
- **D** — Speaker is a new Resource subclass, separate from
  Householder (talk-pool fields differ from door-knock fields).
- **A** — Two-talk Sunday sequencing uses per-talk resolve in the
  same scene: PT plays → effects fire → 0.5s beat → LS plays →
  effects fire → meeting Energy fires → exit.
- **B** — Inner-voice gate uses direct-read
  `if DoubtMeter.value >= 40:` inline in .dtl (matches off-script
  E3d gating pattern at threshold 25, not the one-shot
  consume_reveal_40 flag).
- **C** — Conviction + Standing-Elders fire per-talk on resolve;
  Energy fires once on meeting complete-or-skip (per-meeting
  semantics for "being at the Hall").
- **E** — Skip-meeting penalty fires inline on click in
  `week_view.gd::_on_skip_pressed`, not on day rollover.
- **F** — Last-played state is `MeetingManager._last_played_per_type:
  Dictionary[StringName, StringName]`. Session-only; M7 save/load
  will pick up serialization later.
- **G** — `MeetingManager` autoload owns pending-meeting + last-
  played state; `PlayerState` stays empty (autoload reserved for
  future player identity work).

**Files created (10):**
- `scripts/entities/speaker.gd` — `Resource` subclass with id,
  display_name, character_name, voice_profile_ref, dialogic_character.
- `scripts/systems/meeting_manager.gd` — new autoload. Owns the
  pending-meeting state, the speech-pool picker (with last-played
  exclusion), per-talk + per-meeting effect firing, skip resolution,
  6-seat layout + per-neighbor social-moment options.
- `scenes/meeting_hall.tscn` + `scripts/ui/meeting_hall.gd` — phase
  state machine (SEAT_PICKER → SOCIAL_MOMENT → TALK → RESOLVE).
  Dialogic integration mirrors `door_knock.gd` (force-rescan .dch/
  .dtl on `_ready`, debug panel via `_maybe_instantiate_debug_panel`,
  per-talk signal_event + timeline_ended handlers). No back/walk-
  away button — player commits at the week_view Attend click.
- `data/speakers/elder_coordinator.tres` and `elder_strict.tres` —
  Speaker resources for the two M5 elders.
- `data/dialogues/characters/elder_coordinator.dch` and `elder_strict.dch`
  — Dialogic Characters with distinct color fields (Coordinator
  warm gold `Color(0.84, 0.7, 0.42, 1)`; Strict Elder cool slate-
  grey `Color(0.5, 0.55, 0.62, 1)`) driving the shared
  placeholder portrait tint per the M4.6 mechanism.
- `data/dialogues/meetings/placeholder_pt_v1.dtl`,
  `placeholder_ls_v1.dtl`, `placeholder_mw_v1.dtl` — 3-page click-
  through monologue scaffolds with `[DRAFT PENDING]` line text and
  one `if DoubtMeter.value >= 40:` inner-voice italic block each.
  Each terminates with `[signal arg="TALK_COMPLETED"]` +
  `[end_timeline]`.

**Files modified (4):**
- `scripts/systems/signal_bus.gd` — 3 new signals: `meeting_attended`,
  `meeting_skipped`, `talk_completed(meeting_type, speech_slug)`.
- `scripts/ui/week_view.gd` — `MEETING_DAY_PHASES` const,
  `_meeting_button` + `_skip_button` `@onready` vars, two new
  `_on_meeting_pressed` / `_on_skip_pressed` handlers, visibility
  toggling in `_refresh()`.
- `scenes/week_view.tscn` — added MeetingButton (primary gold) and
  SkipButton (secondary muted) between ServiceButton and
  AdvanceButton, reusing the existing StyleBoxFlat sub-resources.
- `project.godot` — `MeetingManager` autoload (after TerritoryManager,
  before Dialogic to preserve load order); `dch_directory` gains
  `elder_coordinator` + `elder_strict`; `dtl_directory` gains the
  3 placeholder meeting speech entries.

**Files unchanged by intent (asserted):**
- `scripts/systems/doubt_meter.gd` — skip doubt firing goes through
  `DoubtMeter.apply(SKIP_DOUBT_DELTA, &"meeting_skipped")` reusing
  the existing apply pattern. No schema or trigger changes.
- `scripts/systems/time_manager.gd` — meeting completion advances
  via `TimeManager.advance_phase()` (existing API). No schema
  changes.
- `scripts/systems/resource_manager.gd` — meeting effects fire via
  existing `add_conviction` / `add_standing_elders` / `add_energy`
  with their clamping + signal emission. No schema changes.
- `scripts/systems/territory_manager.gd` — orthogonal to meetings;
  no edits.
- `assets/sprites/portraits/_shared_placeholder/placeholder_portrait.gd`
  — `EXPRESSION_BRIGHTNESS` covers `neutral` (the only expression
  the M5.0 .dtl files use). If M5.3 subagents add new expressions
  to elder .dch files, extend EXPRESSION_BRIGHTNESS at that point.
- `scenes/door_knock.tscn`, `scripts/ui/door_knock.gd` — no
  changes; M4.6 PR/CS/HS/Apostate flow unchanged.

**Architectural pattern reuse (deliberate parallels):**
- `MeetingManager` shape mirrors `TerritoryManager`: pending-state
  setter/getter, `_load_speaker_cache` defensive load with fallback
  to a minimal in-code Speaker if .tres missing, slug-keyed
  dictionaries for distribution + effects.
- `meeting_hall.gd::_ready` Dialogic wiring mirrors `door_knock.gd:
  83-91`: force-rescan .dch/.dtl directories, connect signal_event
  + timeline_ended, instantiate debug panel via the same
  `_maybe_instantiate_debug_panel` helper.
- `meeting_hall.gd::_on_dialogic_signal` mirrors `door_knock.gd::
  _on_dialogic_signal` outcome-string dispatch.
- `week_view.gd` Attend/Skip wiring mirrors the existing Service
  button pattern (`SERVICE_DAY_PHASES` + visibility toggle in
  `_refresh()`).
- Shared top banner instanced per `territory_map.tscn` / `week_view.tscn`
  precedent (M4-LF2).

**Headless boot: clean.** All four scenes boot at exit 0 with only
the standard `--quit-after` cleanup warnings (ObjectDB leaked / 26
resources in use). Required a one-time `godot --headless --import`
to register the new `Speaker` class_name in the global script class
cache; future cold launches inherit the registration.

**Bugfix during M5.2:** `meeting_hall.gd::_ready` early-exit paths
(no-pending-meeting, no-talks-for-meeting) initially called
`_return_to_week_view()` synchronously, triggering "Parent node is
busy adding/removing children" because `change_scene_to_file` is
illegal inside `_ready`. Fixed by `call_deferred("_return_to_week_view")`
in both early-exit branches. The normal flow (`_resolve_meeting →
_return_to_week_view`) is unaffected — that path runs well after
`_ready` from a Dialogic signal handler.

**Phase 3 gate playtest (Andrew) — 11-item checklist:**
- [ ] **Sunday — Attend.** Fresh game opens on Week 1 Sunday.
      ATTEND THE MEETING button visible (primary gold). SKIP THE
      MEETING button visible (secondary muted). Click ATTEND →
      meeting_hall scene loads with top banner + deep-sepia
      background + center phase card "Choose your seat".
- [ ] **Seat picker.** 6 seat buttons render in a 2×3 grid (Front
      Left, Front Right, Middle Left, Middle Right, Back Left,
      Back Right). Click Front Left → phase card transitions to "A
      moment before the talk" with Service Partner-themed prompt.
- [ ] **Social moment.** Two choice buttons render. Pick "Smile back,
      say hello." → Standing-Congregation in top banner ticks +1.
      Phase advances to Public Talk.
- [ ] **Public Talk.** Phase card hides; Dialogic text pane appears.
      Speaker name shows "Brother Phillips" (Coordinator). 3 pages
      of `[DRAFT PENDING — M5.3 Public Talk page N]` placeholder
      text click through. On final page → [signal] fires:
      Conviction +2, Standing-Elders +1 (visible in banner). Phase
      card returns with "A short pause" copy for ~0.5s.
- [ ] **Lighthouse Study.** Phase card hides; Dialogic restarts with
      `elder_strict` speaker. Speaker name "Brother Whitcomb"
      (Strict Elder), cool slate-grey portrait tint. 3 pages
      placeholder text. Final page fires: Conviction +1, Standing-
      Elders +1. Banner reflects updated totals.
- [ ] **Meeting completes.** Energy -1 fires (banner shows 9/10
      energy). TimeManager phase-advances SUN → MON. Scene swaps
      to week_view showing Monday content. No errors in console.
- [ ] **Tuesday — Attend.** Advance to Tuesday. ATTEND visible.
      Click ATTEND → meeting_hall loads. Seat → social moment →
      Midweek talk (Coordinator). Effects: Conviction +2, Standing-
      Elders +2, then Energy -1. Phase advances TUE → WED.
- [ ] **Skip — Sunday.** Reset / new game. Sunday → click SKIP THE
      MEETING. Standing-Elders ticks -2 in banner. Doubt event log
      (debug panel via F9) shows `+1 meeting_skipped`. Phase
      advances SUN → MON. No scene change to meeting_hall.
- [ ] **Inner-voice gate.** Use debug panel (F9 → Shift+↑ ×4 to push
      doubt to 40). Attend Sunday meeting again. The italic
      `[DRAFT PENDING]` inner-voice placeholder line appears
      between the PT pages at the hand-authored beat. Without doubt
      ≥40 (start a fresh run, attend immediately), the line does
      not render. Note: v1 ships placeholder italic text gated by
      direct-read in .dtl; M5.3 authors the real content. The non-
      advancing + auto-fade behavior from Phase 1.5 Q8 lock is
      deferred — v1 ships click-through italic via Dialogic's
      normal text-event flow. See "Known v1 limitations" below.
- [ ] **Last-played exclusion (structural only in v1).** With single-
      entry pools, observable variety can't be tested. Confirm
      structurally: after one PT play, `MeetingManager
      ._last_played_per_type` contains `{public_talk:
      placeholder_pt_v1}` — verify via debug print or by attending
      a second Sunday and confirming no parse error. M5.3 with
      3-speech pools validates this end-to-end.
- [ ] **No regression.** Saturday field service still works end-to-
      end. territory_map renders, door_knock plays through all 12
      houses (PR / HS / CS / Apostate). M4.6 PR house arc_state
      still transitions to "returning" on second knock. Top banner
      stays in sync across territory_map, week_view, meeting_hall.

**Known v1 limitations (explicitly out of scope; flagged for M5.3 / M5.4):**
- **Speech pool size = 1 per type.** Last-played exclusion is wired
  but unobservable until M5.3 expands the pool to 3 entries each.
- **Inner-voice rendering: click-through Dialogic, not auto-fade.**
  Phase 1.5 Q8 locked "italic, non-advancing, fades after ~2s"; v1
  renders the gated line as a regular Dialogic text event with `[i]`
  italic tags (advances on click). Implementing the overlay-with-
  fade approach requires a custom signal handler + overlay Label
  with tween that this v1 scaffold doesn't ship. Acceptable per the
  plan; M5.4+ candidate for fidelity.
- **Energy per-day refill.** `ResourceManager._on_day_advanced`
  refills energy to max on every phase change. The meeting -1 only
  persists during the meeting-day phase. Acceptable per existing
  energy semantics; playtest may surface that the cost should
  somehow carry forward.
- **Speaker portraits = placeholder tints.** Distinct colors via the
  shared placeholder script; real art deferred.
- **6-seat layout fixed.** Per Phase 1 default. Visiting-speaker
  pattern (GDD canon for PT variety) and additional elder profiles
  (cast.md § 1.x expansion) are M5.4+ candidates.
- **Sunday two-meeting framing.** `&"sunday_meeting"` slug bundles
  PT + LS for the week_view button; meeting_hall.gd dispatches
  internally. If playtest wants separate Sunday buttons (skip just
  PT, attend just LS), revisit the slug taxonomy.
- **No back-out from meeting_hall.** Once the player clicks ATTEND
  they must complete the meeting. By design (mirrors Phase 1.5 Q7's
  "skip is a decision at week_view, not a mid-flow exit"); flag if
  playtest needs an emergency-exit.
- **Social-moment placeholder copy.** v1 ships authored-by-Claude
  placeholder strings in `MeetingManager.SOCIAL_MOMENT_OPTIONS`.
  Rewrite alongside M5.3 elder speeches for cadence consistency.

**Open unknowns surfaced for future milestones:**
- **No coordination between meeting Energy cost and meeting-day
  schedule entries in `week_view.gd::DAY_CONTENT`.** Sunday's
  schedule still lists Morning/Midday/Evening Hall activities as
  flat text; the M5 ATTEND button is the only mechanic-bearing
  surface. Reconciling the two (e.g., grey out the schedule rows
  if the player skipped) is a polish add.
- **No save/load (M7 carry).** Pending-meeting + last-played state
  reset on every fresh boot. The `_last_played_per_type` dict needs
  serialization when M7 lands.
- **MeetingManager has no `pending_arc_state()`-equivalent for the
  player's standing thresholds.** If M5.4+ adds "Coordinator pulls
  you aside in the lobby" mechanic gated on Standing-Elders ≥ N or
  doubt ≥ N, that needs a new accessor + .dtl integration.

**Phase 1 architecture decisions locked (2026-05-24 conversation):**
- **Q1.scope** — Structural first (M5.0–M5.2: scaffold + 1 placeholder
  speech per type), content second (M5.3: dialogue subagent pool
  authoring). Mirrors M4.6's split-gate phasing.
- **Q1.pretalk** — Seat picker + social-positioning moment (both).
  Seat picks once per meeting and persists across both Sunday talks;
  social moment depends on who the chosen seat sits near. Two
  interaction layers before each meeting; +1.5× session scope vs the
  recommended single-layer option, accepted.
- **Q1.delivery** — Hybrid: 3-page click-through monologue with
  doubt-gated inner-voice interjections between elder lines. Reuses
  M4 reveal-40 pattern (`DoubtMeter.value >= threshold` gate). Inner
  voice is italic, non-advancing, fades after ~2s.
- **Q1.repository** — Whole-speech .dtl pool. Each speech is one
  self-contained .dtl with all 3 pages. Pool per meeting type
  (`public_talk`, `lighthouse_study`, `midweek_training`); random
  pick at meeting time with last-played exclusion to prevent
  immediate repeat. Mirrors per-house .dtl pattern from M4.6.

**Phase 1.5 calibration decisions locked (same conversation):**
- **Q5.speaker** — Fixed by talk type. Coordinator of Elders delivers
  Public Talk and Midweek (warm, gathering / training register).
  Strict Elder delivers Lighthouse Study (rigorous, paragraph-by-
  paragraph register). Stable voice anchors per slot; add 1–2 more
  elder profiles to cast.md § 1.x in a future milestone for inside-
  slot variety. Visiting-speaker pattern from GDD canon for PT
  deferred to that future milestone.
- **Q6.effects** — Moderate magnitudes on completion: Public Talk
  +2 Conviction +1 Standing-Elders; Lighthouse Study +1/+1; Midweek
  +2/+2. Energy -1 Sunday (covers both PT and LS), -1 Tuesday.
  Attendance contributes meaningfully to Conviction without
  overshadowing Saturday field-service hours.
- **Q7.skip** — Skipping fires Standing-Elders -2 + doubt +1. No
  Conviction change (Conviction reflects faith, not behavior). Ties
  skipping into the M4 doubt spine — the empty seat reads as a small
  internal failure to a devout publisher.
- **Q8.innervoice** — Single threshold matching door_knock reveal-40
  pattern: `DoubtMeter.value >= 40` gates one italic inner-voice line
  per talk at a hand-authored beat marked in the .dtl. Across 9
  speeches in v1 pool (3 per type), 9 hand-authored inner-voice
  lines total. Inner-voice line uses italic style, non-advancing,
  fades after ~2s. Mechanically consistent with M4.

**Phase 1 proposed defaults (revisable in Phase 0):**
- Speech pool size v1 = 3 per type = 9 total speeches. Tunable when
  M5.3 dialogue subagent queue is scoped.
- Seat count = 6 named seats: Front-Left, Front-Right, Middle-Left,
  Middle-Right, Back-Left, Back-Right. Each pinned to one neighbor
  identity (Service Partner, Sister Who Talks, Strict Elder's wife,
  a Lonely Elderly attendee, the Parent in the Truth, sit-alone slot).
- Social-moment options per seat = 2 short choices based on the
  pinned neighbor. ±1 Standing (Family / Congregation / Elders)
  per pick.
- Per-meeting flow:
  - Sunday: attend? → seat picker → social moment → PT 3pg (Coordinator)
    → LS 3pg (Strict Elder) → resolve (effects fire) → return to week_view
  - Tuesday: attend? → seat picker → social moment → Midweek 3pg
    (Coordinator) → resolve → return to week_view

**Architecture sketch (M5.0 – M5.3):**
- M5.0 — `scenes/meeting_hall.tscn` + `scripts/ui/meeting_hall.gd`.
  Single scene parameterized by meeting type (Sunday two-talk vs
  Tuesday one-talk). Hall background placeholder, 4–6 seats overlay,
  speaker portrait + name panel, dialogic-driven 3-page talk pane,
  inner-voice italic overlay layer.
- M5.1 — `scripts/ui/week_view.gd` gains "Attend Meeting" button
  on Sunday + Tuesday day cards (mirrors "Go Out in Service" pattern).
  Routes to `meeting_hall.tscn` with `MeetingManager.set_pending_meeting`
  set; `Skip` advances phase and fires doubt/conviction skip-deltas.
- M5.2 — One placeholder speech per type (3 .dtl files), one elder
  identity per type, one seat layout, one social-moment per seat.
  Wires `Dialogic.signal()` → `_resolve_with_outcome(COMPLETED)`
  mirroring door_knock's resolution pattern.
- M5.3 — Dialogue subagent passes for the canned-speech pool
  (per Phase 1.5 size lock). Each subagent session = one full
  speech, voice-grounded in cast.md elder profile + authenticity-
  notes.md texture; CLAUDE.md legal guardrails enforced (no lifted
  publication text).

Wires into existing `week_view` Sunday + Tuesday `DAY_CONTENT`;
likely needs `SignalBus.meeting_attended` / `meeting_skipped` /
`talk_completed` signals; `MeetingManager` autoload similar to
`TerritoryManager` for pending-meeting state + speech-pool picking
+ last-played tracking. Cast.md elder roster (§ 1.x — Coordinator of
Elders, Strict Elder) drives speaker identity. Sermon content needs
authenticity-notes.md texture per CLAUDE.md legal guardrails (no
lifted publication text).

**M4.4 — Hostile + Gentle Apostate variants.** Still deferred below
M5 per user direction. M4.5 already wired the integration point:
`APOSTATE_SUBTYPE_PATHS` in `territory_manager.gd` maps all three
keys (hostile/wounded/gentle) to `apostate_wounded.tres` today;
M4.4 drops in new `.tres` resources for Hostile + Gentle (plus
their `.dch` + `.dtl` triplets) and updates the two path values —
no call-site changes needed. `resolve_householder_for_pending_house`
already does the per-knock variant pick at the § 4 weights
(40/35/25 Hostile/Wounded/Gentle). Four open calibration questions
carried forward: (1) does House #7 rotate between the three
variants per Saturday — the M4.5 sub-roll mechanically does this
each knock; question is whether per-knock variety is the *desired*
texture or whether DIST should pin a specific variant per house;
(2) BIBLE_STUDY_STARTED and RV_SCHEDULED reachability from the
Gentle Apostate (most plausible variant for player-pressed positive
outcomes); (3) confirm Wounded's +3/+2 deltas play right before
locking Hostile (~+5/+3?) and Gentle (~+2/+4 — gentlest pressure,
longest doubt tail?) magnitudes; (4) within-Apostate-trio variety
of the named loss — Wounded names the mother; seed Hostile and/or
Gentle with sibling or whole-congregation framing — see UNSURE in
`apostate_wounded_v1.dtl` E3.

**M4.6 + M4.3 carry-over committed (`78db20f`).** Single bundled
follow-on commit landed the M4.6 Phase 0–2 system code
(territory_manager.gd, door_knock.gd, house.gd, householder.gd,
territory_map.gd, project.godot), the 6 new-character .tres + .dch
triplets (5 PR + 1 CS), the M4.3 Apostate triplet + portrait pair,
the M4.6 shared placeholder portrait scaffold, cast.md voice profile
additions, and four `.png.import` files. Working tree is clean
heading into M5 Phase 0.

## M4.6 — Per-house PR character identity + dialogue arc continuation: complete (Phases 0–4 shipped; gate playtest pending)

Phases 0–4 all shipped this session (2026-05-24). Phase 4 commit
`da4441d` landed 8 dialogue subagent passes — 6 PR characters + 2 CS
characters, each .dtl with both `first_visit` and `returning`
arc-state branches authored end-to-end. House #4 grief and House #5
Catholic preserved their M4.2 / M3 canonical first_visit text
verbatim; only their `returning` branches were newly authored.
Topology, signal args, portrait beats, off-script registry text,
and the if/else+jump/label arc-state wrappers preserved per skeleton.
UNSURE flags embedded per character for Andrew's gate playtest
review. Phase 3 gate playtest still pending Andrew (9-item checklist
below). Headless boot clean on both `territory_map.tscn` and
`main_menu.tscn` (only standard `--quit-after` cleanup warnings).

**Commit state.** Two commits: `da4441d` landed the rename +
dialogue content for the two pre-existing canonical files
(House #4 grief, House #5 Catholic); `78db20f` followed with the
M4.6 Phase 0–2 system code, the 6 new-character triplets, the M4.3
Apostate triplet (carried over from the prior session), and the
shared placeholder portrait scaffold.

**Architecture pivot from the original M4.6 framing.** The session's
plan-mode design surfaced (via user direction) that the M4.5 Apostate
sub-roll pattern (variant rolled per knock) is the WRONG precedent
for PR. Each PR house has a permanent, specific family who lives
there — character identity is preserved across visits, weeks, and
re-knocks because portraits will be authored per character later.
That requires per-house pinning at territory build time, NOT per-knock
sub-rolling. M4.6 ships that pivot plus two additional systems:

1. **Dialogue arc continuation.** Re-knocking a PR house plays a
   different opener — the character recognizes the publisher. Each
   .dtl branches at the top on `TerritoryManager.pending_arc_state()`
   via a top-level `if`/`else` + `jump`/`label` (cleaner than nested
   indentation; M3 content stays at column 0).
2. **Clickability reset rules** (Andrew's clarification): NOT_HOME
   clears on the next service day in the SAME week (Thursday NOT_HOME
   → re-knockable Saturday); resolved outcomes (TRACT_LEFT / REFUSED
   / RV_SCHEDULED / BIBLE_STUDY_STARTED) clear on Sunday rollover
   into the next week; `house.arc_state` is NEVER reset, so character
   memory persists across both reset types.

**Phase 1 locked decisions (Q1a + Q1.granularity + Q1.scope +
Q1.reset + Q1.naming + Q1.catholic + Q1.sessions):**
- Q1a — voice profiles authored THIS session in cast.md § 6.0 (new
  parent PR section + 5 sub-type subsections, mirroring § 6.6
  Apostate's three-flavor structure). dialogue-context.md § 6 PR
  entry stays as the cadence/sample reference.
- Q1.granularity — 6 unique characters across 6 PR houses, NOT 5
  sub-types reused. Sub-types are voice categories. Pigeonhole:
  atheist repeats at houses #1 (tired flavor § 6.0.1 A) and #12
  (intellectual flavor § 6.0.1 B) — two distinct voices, same
  category.
- Q1.scope — line-pool intra-visit variation DEFERRED; arc-based
  cross-visit variation lands. Weekly re-knock support lands with
  the per-day / per-week split above.
- Q1.naming — `polite_refuser_house03_jewish.tres` convention
  (position + subtype, greppable both ways).
- Q1.catholic — existing M3-validated triplet renamed to house05
  (`polite_refuser_house05_catholic.*`). M3 dialogue text preserved
  verbatim as the "first_visit" branch. The Catholic subagent
  session in Phase 4 writes only the "returning" branch.
- Q1.sessions — one dialogue subagent session per character (6
  sessions queued), full arc both branches per session, per the
  goop-character skill's voice-per-session rule.

**Sub-type to PR-house mapping (locked in DISTRIBUTION):**
- House #1: atheist (tired) — § 6.0.1 Flavor A
- House #3: Jewish — § 6.0.3 EMPATHY-BAR red lines apply
- House #5: Catholic — § 6.0.2, M3 canonical
- House #8: gay couple — § 6.0.4 EMPATHY-BAR red lines apply
- House #10: Episcopalian — § 6.0.5
- House #12: atheist (intellectual) — § 6.0.1 Flavor B

**Files modified (5 code + 3 docs):**
- `scripts/entities/householder.gd` — added `voice_subtype: StringName`
  and `character_name: String` (cast.md § 6.0.x cross-ref + future
  display-name hook).
- `scripts/entities/house.gd` — added `arc_state: StringName =
  &"first_visit"`. Orthogonal to `state` enum (click-state); never
  reset by the new reset hooks.
- `scripts/systems/territory_manager.gd` — major: 5 new
  HOUSEHOLDER_PATHS keys (existing `polite_refuser` key removed),
  DISTRIBUTION pinning per-PR-house, FALLBACK_ARCHETYPE flipped to
  `polite_refuser_house05_catholic` (the M3-validated content),
  reset hooks `_on_phase_changed` (per-service-day NOT_HOME clear)
  and `_on_week_advanced` (per-week resolved clear), and a new
  `pending_arc_state()` accessor mirroring the
  `DoubtMeter.value` access pattern for .dtl inline expressions.
- `scripts/ui/door_knock.gd` — `_resolve_with_outcome` now sets
  `_pending_house.arc_state = &"returning"` on every terminal
  outcome (Dialogic signal, walk-away, or Hostile Slammer scene).
- `project.godot` — `dch_directory` and `dtl_directory` each gain 6
  new entries; existing `polite_refuser` / `polite_refuser_v1`
  entries removed (replaced by the 6 per-house entries).
- `docs/design/cast.md` — added § 6.0 Polite Refuser parent section
  plus § 6.0.1 atheist (two flavors), § 6.0.2 Catholic (M3 canonical),
  § 6.0.3 Jewish (EMPATHY-BAR red lines), § 6.0.4 gay couple
  (EMPATHY-BAR red lines), § 6.0.5 Episcopalian. § 7 quick-reference
  table gained a Polite Refuser (shared) row.
- `docs/STATUS.md` — this section + queue promotion.

**Files renamed (3, via `git mv` to preserve history):**
- `data/householders/polite_refuser.tres` →
  `polite_refuser_house05_catholic.tres` (id, voice_subtype,
  dialogue_timeline path updated inline)
- `data/dialogues/characters/polite_refuser.dch` →
  `polite_refuser_house05_catholic.dch` (description updated;
  portrait scene paths re-pointed at the consolidated
  `_shared_placeholder/`)
- `data/dialogues/polite_refuser_v1.dtl` →
  `polite_refuser_house05_catholic_v1.dtl` (speaker slug updated
  throughout; arc_state if/else+jump/label wrapper added with M3
  content as the first_visit branch and a [DRAFT PENDING]
  scaffolding for returning)

**Files created (18 — 5 triplets × 3 + portrait + consolidation):**
- 5 new `.tres` Householders (house01 atheist, house03 jewish,
  house08 gay_couple, house10 episcopalian, house12 atheist).
  Each with `archetype = &"polite_refuser"` (broad category) +
  per-house `id` slug + `voice_subtype` + empty `character_name`.
- 5 new `.dch` Dialogic Characters with distinct `color` fields
  (atheist=grey-blue, jewish=warm tan, gay_couple=teal,
  episcopalian=lavender-grey, intellectual atheist=olive) driving
  the shared placeholder portrait tint.
- 5 new `.dtl` Dialogic Timelines — structural skeletons with both
  `first_visit` and `returning` arc branches, full E1–E4 choice
  topology mirroring the Catholic .dtl, all speaking lines as
  `[DRAFT PENDING — house?? subtype branch E#]` placeholders.
- `assets/sprites/portraits/_shared_placeholder/placeholder_portrait.gd`
  + `.tscn` — shared placeholder script that reads
  `character.color` × per-expression brightness multiplier, so all
  6 PR characters render distinct colors using one script.

**Files unchanged by intent (asserted):**
- `scripts/systems/doubt_meter.gd` — arc_state is content state,
  not doubt state. No trigger changes.
- `scripts/systems/time_manager.gd` — `week_advanced` + `phase_changed`
  signals already exist; reset hooks consume them as-is.
- `scripts/ui/territory_map.gd` — slot interaction unchanged. The
  reset hooks fire `territory_house_visited` with NOT_VISITED state,
  so badges re-flip without a new signal type or handler edit.
- `assets/sprites/portraits/polite_refuser/` (original M3 placeholder)
  — left in place; no references remain after the .dch rename, so
  it's effectively dead. Future cleanup pass can delete.
- `assets/sprites/portraits/curious_seeker/` and `apostate_wounded/`
  placeholder dirs — unchanged. The shared placeholder is PR-only
  for M4.6.
- `data/dialogues/curious_seeker_v1.dtl`, `apostate_wounded_v1.dtl`,
  `internals/reveal_40.dtl` — untouched. arc_state branching is
  not yet wired into those .dtl files (CS still 1 character across
  2 houses; future per-house identity work for CS / HS is a
  follow-on milestone).

**Headless boot:** clean on both scenes
(`godot --headless --quit-after 4 res://scenes/territory_map.tscn`
and `... res://scenes/main_menu.tscn`); only the standard
`--quit-after` cleanup warnings (ObjectDB leaked / 26 resources in
use). No autoload errors, no .tres / .dch parse errors, no .gd
parse errors. `godot --headless --check-only` was attempted but
hangs in parallel with the editor process; the boot test covers
the equivalent surface for M4.6 changes (script parse + .tres
load + autoload chain).

**Polish add (same session, post-Phase-2):** two follow-up requests
landed in-session, both extending the territory_map slot rendering
and Householder/House schema. They're tracked here as part of M4.6
rather than a separate milestone because they're tightly coupled to
the per-house reset rules above.

1. **Click gate on resolved houses.** `_on_slot_gui_input` now
   ignores left-clicks on any house with `state != NOT_VISITED`.
   Affordance cue: the slot's `mouse_default_cursor_shape` flips
   to `CURSOR_FORBIDDEN` on resolved slots and back to
   `CURSOR_POINTING_HAND` after a reset. Hover/select still works
   so the detail panel populates regardless. Debug `Shift+click`
   bypass also skips the click gate (so arc-state branch testing
   can re-visit resolved houses without waiting for resets).
2. **Lifetime indicator pip.** New `House.lifetime_best_outcome:
   int = State.NOT_VISITED` field, upgraded in
   `TerritoryManager.resolve_pending_house` whenever the new
   positive outcome ranks higher than the current lifetime value
   (TRACT_LEFT=3 < RV=4 < STUDY=5, monotonic with State enum
   order; REFUSED=2 and NOT_HOME=1 never upgrade). Reset hooks
   leave this field untouched, so the indicator persists across
   per-day and per-week resets. Rendered as a 16×16 circular pip
   anchored at the top-right corner of each slot:
   - TRACT_LEFT lifetime → `BADGE_GREEN` (muted)
   - RV_SCHEDULED lifetime → `BADGE_AMBER`
   - BIBLE_STUDY_STARTED lifetime → new `BADGE_GREEN_BRIGHT`
     (saturated; visually outranks plain TRACT_LEFT at a glance)
   - Otherwise → invisible (no progress yet)

**Files modified by the polish add (3):**
- `scripts/entities/house.gd` — added `lifetime_best_outcome: int`.
- `scripts/systems/territory_manager.gd` — `resolve_pending_house`
  upgrade logic + new private `_is_positive_outcome` helper.
- `scripts/ui/territory_map.gd` — new `BADGE_GREEN_BRIGHT` const,
  `LifetimePip` Panel added in `_make_slot`, refresh + cursor
  logic in `_refresh_slot`, new `_pip_color_for_lifetime` +
  `_make_pip_style` helpers, click gate in `_on_slot_gui_input`.

**No file renames or new triplets from the polish add** —
content stays at the M4.6 Phase 2 set.

**Second polish add (same session) — Curious Seeker pinning.** User
flagged that Houses #4 and #9 were both serving the same Curious
Seeker character (since CS was still on the M4.1 shared-template
model after PR moved to per-house identity). Applied the M4.6 PR
pattern to CS: two unique characters, sub-types as voice categories,
arc_state branching scaffolded for both.

**Sub-type → CS-house mapping:**
- House #4: grief (M4.2 canonical, "my friend's husband just passed")
  per cast.md § 6.2.1.
- House #9: inquisitive ("what's your group about?") per cast.md
  § 6.2.2 — NEW character, [DRAFT PENDING] dialogue.

**Files renamed (3, via `git mv`):**
- `data/householders/curious_seeker.tres` →
  `curious_seeker_house04_grief.tres` (id, voice_subtype,
  dialogue_timeline path updated)
- `data/dialogues/characters/curious_seeker.dch` →
  `curious_seeker_house04_grief.dch` (description updated;
  portrait scene paths re-pointed at `_shared_placeholder/`)
- `data/dialogues/curious_seeker_v1.dtl` →
  `curious_seeker_house04_grief_v1.dtl` (speaker slug
  `curious_seeker` → `curious_seeker_house04_grief` throughout;
  M4.2 content wrapped in `first_visit` branch via top-level
  if/else + jump/label; `returning` branch scaffolded as
  [DRAFT PENDING])

**Files created (3, new house09 triplet):**
- `data/householders/curious_seeker_house09_inquisitive.tres`
- `data/dialogues/characters/curious_seeker_house09_inquisitive.dch`
  — distinct color `Color(0.75, 0.63, 0.50, 1)` (warm sandy-brown)
  vs house04 grief's `Color(0.62, 0.7, 0.65, 1)` (sage greenish-grey)
- `data/dialogues/curious_seeker_house09_inquisitive_v1.dtl` —
  full skeleton with both arc branches, all lines [DRAFT PENDING]

**Files modified (4):**
- `assets/sprites/portraits/_shared_placeholder/placeholder_portrait.gd`
  — `EXPRESSION_BRIGHTNESS` extended to include CS expression names
  (`interested_lean_in`, `genuine_question`, `considering`,
  `warm_thank_you`) so both CS characters render with
  character-color × per-expression brightness like the PR
  characters.
- `scripts/systems/territory_manager.gd` — `HOUSEHOLDER_PATHS`
  loses `curious_seeker` key, gains the two house-pinned CS keys.
  `DISTRIBUTION` slots 4 and 9 updated.
- `project.godot` — `dch_directory` / `dtl_directory`: removed
  `curious_seeker` / `curious_seeker_v1` entries, added the four
  new per-house entries.
- `docs/design/cast.md` — § 6.2 Curious Seeker section gained a
  sub-type pinning table and two subsections (§ 6.2.1 grief —
  documenting the M4.2 canonical interpretation; § 6.2.2
  inquisitive — new voice profile). § 7 quick-reference row
  updated to "Curious Seeker (shared)".

**Phase 4 dialogue subagent queue updated.** The 6-session queue
from the PR work expands to 8 sessions:
- 6 PR character sessions (unchanged)
- 1 CS house04 grief — arc-continuation-only session (first_visit
  content is M4.2 canonical, only `returning` branch needs
  authoring)
- 1 CS house09 inquisitive — full first_visit + returning session

**Files unchanged by intent:**
- `assets/sprites/portraits/curious_seeker/` (M4.1 placeholder dir)
  — left in place; no references remain after the .dch rename, so
  it's now dead (same disposition as the original M3 PR placeholder
  dir). Future cleanup pass can delete both.
- `scripts/ui/door_knock.gd::OFFSCRIPT_CHOICE_TEXTS` — the off-script
  text-key `"I don't know. Honestly."` covers both CS characters
  (the new inquisitive character's [DRAFT PENDING] notes preserve
  the same text-key explicitly so no registry update is needed
  during Phase 4 unless the subagent re-words it).

**Headless boot:** clean on `territory_map.tscn` after the CS
work (same pattern as the M4.6 boot — standard `--quit-after`
cleanup warnings only).

**Phase 3 gate playtest (Andrew):**
- [ ] 6 PR houses (#1/3/5/8/10/12) load distinct characters —
      hover detail panels show distinct slugs; clicked portraits
      render distinct colors.
- [ ] Click House #1 → atheist first_visit branch plays
      ([DRAFT PENDING] placeholders visible); resolve TRACT_LEFT.
- [ ] Click House #1 again same Saturday → still TRACT_LEFT,
      no re-click.
- [ ] Advance to Sun Week 2 → return to territory_map (if Saturday
      → next phase auto-routes to week_view, advance once more) →
      House #1 reset to NOT_VISITED. Click House #1 → atheist
      RETURNING branch plays. **CRITICAL: arc_state persisted.**
- [ ] Thursday service: NOT_HOME at a PR house; advance Thu → Fri
      → Sat; open territory_map → that house re-clickable
      (NOT_VISITED).
- [ ] Thursday service: TRACT_LEFT at a PR house; advance to Sat
      same week; that house still locked (TRACT_LEFT badge);
      advance Sat → Sun Week 2; same house now NOT_VISITED.
- [ ] No regression — House #7 (Apostate) still sub-rolls per knock;
      Houses #2/6/11 still play Hostile Slammer scene; Houses #4/9
      still play Curious Seeker with off-script gated at doubt 25.
- [ ] M4.5 Shift+click debug bypass still works on PR houses (rare
      sub-type spike-testing not yet needed since sub-types are
      pinned, but bypass for sub-type playtesting still useful).
- [ ] **.dtl parse** — first knock on each of the 6 PR houses
      successfully starts the Dialogic timeline (Dialogic runtime
      parses the .dtl on `Dialogic.start()`). If any character's
      .dtl errors, the if/else+jump/label scaffolding may need
      revision; the Catholic .dtl is the safest reference since it
      shipped with M3 content (only the wrapper is new).

**Open unknowns surfaced for future milestones:**
- **Line-pool intra-visit variation.** If a player walks away from
  a PR house and immediately re-clicks the same Saturday (NOT_HOME
  not gating since arc didn't fire), they'd see the identical
  opener. M4.6 scope explicitly deferred this. M4.7+ candidate.
- **arc_state coarseness.** v1 has 2 states (`first_visit` /
  `returning`). The 4 prior-outcome distinctions (`post_refused`
  vs `post_tract_left` etc.) collapse to `returning` for now.
  Playtest may reveal the same returning branch reading across
  outcomes feels generic — M4.7+ content extension, no schema
  change required.
- **Custom portraits per character.** Placeholder consolidation
  ships with 6 distinct colors via the shared script; real art
  per character is a deferred polish session.
- **`character_name` field empty for all 6 PR characters.** The
  dialogue subagent's Phase 4 sessions choose family names per
  cultural specificity; the field gets populated alongside the
  dialogue writing. Detail-panel display of character_name is also
  a polish add (currently `territory_map.gd` doesn't read it).
- **Sub-type identity for other archetypes.** Curious Seeker (2
  houses) and Hostile Slammer (3 houses) still share templates.
  Per-house identity for CS / HS is a follow-on milestone with
  the same scope multiplier (×3 dialogue surface area for HS,
  ×2 for CS).
- **OFFSCRIPT_CHOICE_TEXTS registry text-key brittleness.** Still
  present from M4.3 STATUS. The "Why is that for you?" key works
  across all 6 PR characters since they share the off-script
  prompt text. If a Phase 4 dialogue subagent re-words the
  off-script choice for any character, the dict needs a new entry.

## M4.5 — Encounter Distribution Spike: complete

End-to-end NOT_HOME flow shipped. Per-knock outcome roll model
validated: `TerritoryManager.roll_door_outcome()` returns true
(~26.5%) / false (~73.5%); answered path runs §4 Apostate
sub-roll (`roll_apostate_subtype`) then the existing M3+M4 door-
knock flow; not-home path resolves in-place via
`territory_map.gd::_resolve_not_home` with a brief on-map beat
("No one came to the door.", 0.2s fade-in / 0.5s hold / 0.3s
fade-out tween over the clicked slot), no scene transition. The
existing `SignalBus.territory_house_visited` → `_on_house_visited`
chain handles the grey "NOT HOME" badge, detail panel copy, hours
tick, and Today's Progress untouched.

**Phase 1 decisions locked (Q1a–f):**
- Q1a — at-knock-time roll (each click rolls fresh).
- Q1b — hybrid: DIST pins archetype-when-answered; roller picks
  answered vs. not-answered (binary). House #7 stays the Apostate
  slot; M4.6 sub-type trees inherit the same authorial-override
  model.
- Q1c — NO_ANSWER_BUT_HOME (§3, 3.5%) folded into NOT_HOME for v1.
  Combined ~73.5% not-home rate. Atmospheric beat content
  re-investible in M4.7+.
- Q1d — NOT_HOME visual after knock only (forced by Q1a).
- Q1e — same `HOURS_PER_KNOCK` (0.25h) for NOT_HOME. Single
  tunable constant; revisit post-playtest if cadence is off.
- Q1f — moot under hybrid (DIST owns archetype distribution; the
  roller never picks unimplemented archetypes).

**Cadence verdict (Andrew playtest, single Saturday):** 3 answered
of 12 (25%, expected 26.5%). The math holds and the NOT_HOME beat
reads as feedback rather than friction. House #7 Apostate happened
to roll NOT_HOME this run; the spike-friendliness gap that
surfaced — targeted testing of single-slot rare archetypes is
~26.5%/Saturday reachable — got a debug-only workaround.

**Architectural verdict:** Keep the hybrid. DIST + at-knock roller
+ §4 sub-roll all hold. No revert needed; promote M4.6.

**Open unknowns surfaced for future milestones:**
- **Rare-archetype reachability.** Single-slot archetypes are
  ~26.5%/Saturday reachable, ~80% cumulative after 5 Saturdays.
  Atmospheric rarity (intentional) or testing friction (calibrate)?
  `P_ANSWERED` is the one-line tunable.
- **NOT_HOME-house re-clickability.** Pre-existing M2-era
  behavior, now exposed: a NOT_HOME house can be re-clicked and
  re-rolls. Should resolution lock the slot? Spike didn't address;
  M4.7 candidate.
- **Per-territory `P_ANSWERED`.** §6.1 modifiers explicitly call
  for apartment-dense ×0.8 NOT_HOME, working-class ×1.1, etc.
  M4.5 ships a single global constant. M4.7+ multi-territory work
  lays the override mechanism; `const P_ANSWERED` is the hook
  point.
- **Save/load and at-knock RNG (M7).** Rolls fire per-click at
  runtime, no save state needed. M7 reload mid-Saturday will see
  outcomes-so-far in `house.state` and not re-roll resolved
  houses — same as today, but worth re-confirming when M7 lands.
- **Within-archetype sub-roll architecture (M4.6 input).** §4 is
  the only sub-roll wired today; generalizing to PR / CS / etc.
  is M4.6's central work. The pattern is established but not yet
  abstracted (PR doesn't have its own `PR_SUB_WEIGHTS` constant or
  archetype-category dispatch).

**Files modified (2 code + 1 doc):**
- `scripts/systems/territory_manager.gd` — added constants
  `P_ANSWERED` (0.265), `APOSTATE_SUB_WEIGHTS` (40/35/25),
  `APOSTATE_SUBTYPE_PATHS` (all three v1 keys → apostate_wounded
  .tres; M4.4 swap point), `APOSTATE_ARCHETYPES`; new functions
  `roll_door_outcome`, `roll_apostate_subtype`,
  `resolve_householder_for_pending_house`. No changes to
  `_build_default_territory`, `resolve_pending_house`, or
  `outcome_label`.
- `scripts/ui/territory_map.gd` — new `_beat_active` state flag
  and `_resolve_not_home` helper; `_commit_visit` now branches on
  `TerritoryManager.roll_door_outcome()`; `_on_slot_gui_input`
  gates clicks during the ~1s NOT_HOME beat; **debug-only
  Shift+click bypass** via `_force_answered_visit` (gated on
  `OS.is_debug_build()`) for targeted spike-testing of rare slots;
  `_build_legend` gains a grey "Not Home" row.
- `docs/STATUS.md` — this section plus queue promotion.

**Files explicitly unchanged (asserted):**
- `scripts/systems/doubt_meter.gd` — NOT_HOME fires zero doubt
  events; T4 (Saturday-zero-RV) unchanged.
- `scripts/entities/house.gd` — `State.NOT_HOME` already in enum.
- `scripts/ui/door_knock.gd` — NOT_HOME never enters this scene.
- `scripts/systems/territory_manager.gd::DISTRIBUTION` — House #7
  stays apostate_wounded under hybrid model; no slot reassignment.
- All `data/dialogues/*` and `data/householders/*` — no new
  content this spike.
- `project.godot` — no autoload additions.

**Headless boot:** clean on `territory_map.tscn` (direct) and
`main_menu.tscn` (autoload chain) — only standard `--quit-after`
cleanup warnings (ObjectDB leaked / 26 resources in use), no
parse errors.

**Debug Shift+click note:** The bypass is committed (not stripped
post-spike) because M4.6 sub-type playtesting will face the same
rare-slot reachability friction — generalizing the sub-roll to PR
sub-types means individual PR sub-types are 1/6 chance per PR
slot × 26.5% answered = ~4.4% per knock, even less reachable than
the Apostate. Shift+click stays useful. Strip if M4.7+ adds a
designed-in playtest seed/force mechanism.

## M4.3 — The Apostate (Wounded variant): Phases 0–2 complete

Structural ship: Wounded Apostate now lives at House #7 in Maple
Street; placeholder Polite Refuser flipped out. `apostate_wounded`
.tres + .dch + _v1.dtl triplet plus a placeholder portrait pair
(`assets/sprites/portraits/apostate_wounded/`) mirror the
PR/CS pattern. All dialogue lines are `[DRAFT PENDING — …]`
placeholders pending the M4.3 Phase 3 subagent run.

**Locked decisions (Q1–Q6):**
- Q1: Wounded only this session; Hostile + Gentle queue for M4.4.
- Q2: +doubt-on-positive mechanism = extend `doubt_delta_overrides`
  dict (zero schema change; `_resolve_doubt_delta` already handles
  arbitrary ints). First archetype to exercise the semantic.
- Q3: Outcomes reachable = REFUSED + TRACT_LEFT only (no RV_SCHED,
  no BIBLE_STUDY from this door; defer to Gentle in M4.4).
- Q4: Off-script choice = "I'm sorry that happened to you.", gated
  at `DoubtMeter.value >= 35` (higher than PR/CS's 25). Collapses
  to REFUSED — the moment is too heavy to also leave a tract.
- Q5: Calibration locked. `doubt_delta_overrides = {"REFUSED": 3,
  "TRACT_LEFT": 2}`. Off-script choice fires +2 via the registry.
  Exposure ceiling per encounter: +5 (off-script + REFUSED).
- Q6: Reveal-40 chain = standard generic. No new plumbing.

**One deviation from the literal plan:** the plan said "No other
code changes" beyond adding the Apostate's off-script choice text
to `OFFSCRIPT_CHOICE_TEXTS`. But the existing handler hardcoded +3
for any registry entry, which conflicted with Q5's +2 Apostate
calibration. Resolved by refactoring `OFFSCRIPT_CHOICE_TEXTS` from
`Dictionary[String, bool]` → `Dictionary[String, int]` (per-choice
delta). PR and CS stay at +3 by entry value; Apostate is +2.
`_on_choice_selected` now reads `int(OFFSCRIPT_CHOICE_TEXTS[text])`.
Doubt source label changed from `&"offscript_why_taken"` (PR-
specific) to `&"offscript_choice"` (generic). Stale documentary
comment in `polite_refuser_v1.dtl` updated to reflect the new
shape — this is the only PR-content touch and is annotation-only,
no dialogue text changed. STATUS's "T1 brittleness — still text-
keyed" tightening target remains open (the magnitude is now data,
but the lookup is still string-equal).

**Files created (5):**
- `data/householders/apostate_wounded.tres`
- `data/dialogues/characters/apostate_wounded.dch`
- `data/dialogues/apostate_wounded_v1.dtl` (DRAFT PENDING)
- `assets/sprites/portraits/apostate_wounded/placeholder_portrait.tscn`
- `assets/sprites/portraits/apostate_wounded/placeholder_portrait.gd`

**Files modified (4):**
- `scripts/systems/territory_manager.gd` — `HOUSEHOLDER_PATHS` +
  `DISTRIBUTION[6]` flip from `&"polite_refuser"` to `&"apostate_wounded"`.
- `scripts/ui/door_knock.gd` — registry refactor + new entry.
- `project.godot` — Dialogic dch_directory + dtl_directory.
- `data/dialogues/polite_refuser_v1.dtl` — documentary comment
  update only (no dialogue change).

**Verification status:** Headless `godot --headless --check-only`
ran without error output (exit 0) but was slow due to the editor
holding the project simultaneously, so I'm treating it as
inconclusive rather than fully clean. Andrew's gate playtest
(Phase 4) covers the rest: traverse all three terminal branches at
House #7, confirm off-script disabled when doubt < 35, verify
doubt deltas fire as +3 REFUSED / +2 TRACT_LEFT / +2 extra
off-script, confirm reveal-40 fires the next door if doubt
crossed 40 during the encounter.

**Silent-decisions audit (Phase 0):** No undiscovered silent
decisions surfaced beyond the OFFSCRIPT_CHOICE_TEXTS hardcoded
+3 (which became Q5's deviation). `_resolve_doubt_delta`,
reveal-40 chain, and the `Householder` schema were all confirmed
inert for Apostate work — the mechanism was already in place from
M4.1, just not exercised.

## M4.3 Phase 3 — dialogue subagent pass complete

All seven `[DRAFT PENDING — …]` placeholders in
`apostate_wounded_v1.dtl` replaced with final line text. Structure,
branch logic, choice gating, portrait beats, and off-script
registry text all untouched per the goop-character skill's Phase 3
contract. Off-script choice text "I'm sorry that happened to you."
matches the registry exactly (door_knock.gd line 49) so T1 +2
still fires. Five exchanges written total (E1 publisher + E1
householder + E2 recognition + E3 grief + the three E4 closes);
three outcomes reachable across the branches as planned (E4a
REFUSED, E4b TRACT_LEFT, E4c REFUSED via off-script).

**Subagent interpretation locked into the file:** Wounded Apostate
is a woman in her early-to-mid 40s, born-in, disfellowshipped ~5
years ago, opens the door tired and unrehearsed. The E2 "tell" is
"…That's the public Lighthouse, isn't it." — the *public-vs-study
edition* distinction is the precise piece of org vocabulary only
an ex-member tracks. The E3 grief line names the mother
specifically, with elapsed time ("It's been almost five years.")
sitting in the sentence. The E4c off-script response is a broken
doubled "Thank you" with an aborted thought between, intended to
read as receipt-without-script rather than grateful-as-performance.

**# UNSURE flags embedded for Andrew's playtest review (4 total):**
- **E2 — public Lighthouse tell**: assumes the publisher's pre-folded
  magazine is visible at the door (per dialogue-context.md § 10).
  Re-check once door_knock background art lands; if no magazine
  in-frame, the tell loses one beat of evidentiary weight but still
  reads.
- **E3 — "almost five years"**: picked five for fact-not-fresh-wound
  texture. Three or seven both defensible; revisit when M4.4 Hostile
  + Gentle variants land so the three Apostates' time-since-leaving
  reads as varied rather than coincidental.
- **E3 — mother specifically**: per cast.md § 6.6 canonical sample.
  If M4.4 ships sibling-cost or whole-congregation-cost framing on
  Hostile or Gentle, keeping mother on Wounded reads as the deepest
  version. If all three name mother, within-archetype variety
  collapses — fold this into M4.4's voice planning. (Mirrored into
  the M4.4 entry in "Next session (queued)" above.)
- **E4a — "You take care" register**: sits adjacent to the Polite
  Refuser's "you have a good one" relief close. Intended to land
  knowingly (former publisher → publishers) rather than as warmth.
  If it reads warm during playtest, the file note suggests
  "Yeah. …Okay. Go on, then." as a flatter swap.
- **E4c — doubled "Thank you"**: deepest call in the pass and the
  one with the most risk. Read 1 (intended): broken receipt, she
  has no script for being acknowledged at her doorstep. Read 2
  (risk): grateful-as-performance, which dialogue-context.md § 8
  warns against. File note documents the trim options
  ("Oh. — …Thank you." or "Oh. — …Yeah.") for one-line softening
  during playtest if needed.

**Structural concerns surfaced (flagged for Phase 4, not fixed in
Phase 3):**
- The Wounded Apostate's E1 opener is the same generic pitch line
  as Polite Refuser's E1 ("Good morning. We're sharing a brief
  encouraging message from the Bible today."). Intentional — the
  recognition is hers to deliver in E2, so the publisher should
  not telegraph anything in E1. But if a player runs three doors
  in a row that all open with the identical pitch verbatim, it
  will read as copy-paste. M4.4 / M4.6 line-pool variation work
  resolves this naturally; flagging now in case it surfaces
  during the M4.3 playtest before that work lands.
- The `[end_timeline]` is present on every branch and the
  `[signal arg="..."]` immediately precedes it on each — the
  structure parses cleanly by inspection but headless
  `godot --headless --check-only` not re-run this session
  (Phase 3 is content-only, no structural edits). Phase 4
  playtest validates the parse and the branch reachability.

## Current milestone

**M4-LF2 — Day Screen Visual Polish: complete (headless boot clean;
gate playtest pending Andrew).** The `week_view` (day) screen now
mirrors the new day-screen mockup (ChatGPT-generated, 2026-05-23, in
chat — not committed): top banner shared with the territory map,
center "day card" with per-day title + flavor sentence + iconed
activity rows + primary "GO OUT IN SERVICE" gold button + secondary
"ADVANCE TO NEXT PHASE" button, right-hand "TODAY'S SCHEDULE" card
with Morning/Midday/Evening rows + Matthew 5:16 scripture, "← BACK
TO MENU" bottom-left, ESC bound to back.

Same session also **extracted the top banner into a reusable
component**: `scenes/top_banner.tscn` + `scripts/ui/top_banner.gd`.
Both `territory_map.tscn` and `week_view.tscn` now instance it.
`territory_map.gd` lost its inline HUD-wiring (6 @onready vars,
`_refresh_hud`, `_on_resource_changed`) since the banner now owns
those signals. Legacy `scenes/hud.tscn` still wired into
`door_knock.tscn`; replacement is a future polish session.

## Previous milestone

**M4-LF1 — Territory Map Visual Polish: complete (headless boot
clean; gate playtest pending Andrew).** The Saturday field-service
screen matches `docs/design/mockups/territory_map_v1.png`: top
banner with "GO OUT AND PREACH" branding + tagline + 6-resource HUD,
three-column layout (info card / painted map / detail panel), 12
Godot-drawn house slots overlaying `territory_background.png` with
numbered medallions and color-coded outcome badges, single shared
detail-panel painting with per-state copy, "Today's Progress" counters
driven by `SignalBus.territory_house_visited`, parked-car decoration
under the info card, "END FIELD SERVICE" button bottom-right, ESC/Back
bottom-left. As of M4-LF2 the inline top banner has been refactored
out into the shared `top_banner.tscn` (same visuals).

## Implicit decisions this session (M4-LF2)

- **Painted desk-scene background deferred.** The mockup shows a
  painted desk scene (window view, sacred writings book, Lighthouse
  magazine, framed Galatians 6:9, mug). No painted asset was shipped
  for the day screen; v1 uses flat deep sepia like the territory map.
  Queued as polish add — see "Post-M4-LF2 playtest priorities" below.
- **Top banner extraction.** Worth the small refactor: two scenes
  share the banner today, more will tomorrow (meeting_hall, home).
  Single source of truth in `scenes/top_banner.tscn` +
  `scripts/ui/top_banner.gd`. `territory_map.gd` lost ~30 lines of
  duplicated HUD-wiring code.
- **Per-day content written for all 7 phases.** Authentic Society-of-
  the-Truth vocabulary (Hall of Witness, Lighthouse, magazine case,
  service group, midweek meeting). One flavor sentence, 1-2 activity
  rows, and 3 morning/midday/evening schedule rows per day. Lives
  inline in `week_view.gd::DAY_CONTENT` — moving to .tres resources is
  a future content-pass decision.
- **Iconography = Godot-drawn square panels with unicode glyphs.** ✦
  for ornamental, ☀ for morning, ☾ for evening, 📖 for study, ✎ for
  prep/notes. Matches the mockup's square icon framing without
  requiring new image assets.
- **Scripture quote unchanged from territory map.** Matthew 5:16 stays
  as the static brand verse on both screens. Rotation per-day deferred.

## Completed this session (M4-LF2)

- **`scenes/top_banner.tscn`** + **`scripts/ui/top_banner.gd`** —
  shared component. PanelContainer root sized 88px tall by default,
  anchors top-stretch when instanced. Owns the 6 stat readouts and
  the `SignalBus.resource_changed` listener; auto-refreshes on any
  resource mutation.
- **`scenes/territory_map.tscn`** — replaced the inline TopBanner
  subtree (~140 lines of node definitions + a StyleBoxFlat sub-
  resource) with `[node name="TopBanner" parent="." instance=ExtResource("5_banner")]`.
  Net visual change: zero. Net code change: -135 lines from the .tscn,
  +1 ext_resource line.
- **`scripts/ui/territory_map.gd`** — removed `_conviction_value`,
  `_elders_value`, `_cong_value`, `_family_value`, `_energy_value`,
  `_hours_value` @onready vars; removed `_refresh_hud()` and
  `_on_resource_changed()` functions; removed the
  `SignalBus.resource_changed.connect` line and the
  `_refresh_hud()` call in `_ready`. The banner handles its own state
  now.
- **`scenes/week_view.tscn`** — full rebuild. Discarded the
  M1-era stacked-VBox with grey buttons + corner HUD. New tree:
  flat deep-sepia root, top banner instance, ~720×620 dark center
  card (ornament divider + title + flavor + activity rows + GO OUT
  IN SERVICE primary button + ADVANCE secondary button), 300px-wide
  right-side schedule card (header + period rows + scripture), back
  button bottom-left.
- **`scripts/ui/week_view.gd`** — full rewrite around the `DAY_CONTENT`
  dictionary. `_refresh()` re-renders title, flavor, activity rows,
  schedule rows on `_ready` and on every `SignalBus.phase_changed`.
  Helpers: `_make_activity_row()`, `_make_schedule_row()`,
  `_make_icon_square()`. Service button hides/shows based on
  `SERVICE_DAY_PHASES = [THURSDAY, SATURDAY]`. ESC routes through the
  back button handler.

## Files unchanged by intent (M4-LF2)

- `scenes/hud.tscn`, `scripts/ui/hud.gd` — still instanced by
  `door_knock.tscn` (a future polish target).
- `scenes/door_knock.tscn` — out of scope. Still uses legacy HUD.
- `scripts/systems/*` — no schema or behavior changes. The new screen
  is purely presentation over existing state.

## Gate verification — Andrew's checklist (M4-LF2)

**Headless boot: clean.** `godot --headless --quit-after 4
res://scenes/week_view.tscn` and `... res://scenes/territory_map.tscn`
both return 0 errors; only the standard `--quit-after` cleanup
warnings appear.

**Visual gate (Andrew runs editor playtest):**

- [ ] **Banner identical across screens.** Boot to week_view (default).
      Banner shows "GO OUT AND PREACH" + tagline + 6 stats. Click GO
      OUT IN SERVICE (on Thu/Sat) → territory_map shows the same
      banner identically. Walk back via "← Back" → banner still
      identical. (Confirms the extraction didn't drift.)
- [ ] **Day card content on Sunday.** Fresh game opens on Week 1 —
      Sunday. Title "Week 1 — Sunday", flavor "The Lord's day at the
      Hall of Witness…", two activity rows ("Public Talk" + "Lighthouse
      Study") with descriptions, GO OUT IN SERVICE hidden (Sunday is
      not a service day), ADVANCE TO NEXT PHASE visible.
- [ ] **Click ADVANCE 4×.** Walk Sun → Mon → Tue → Wed → Thu. At
      Thursday, title reads "Week 1 — Thursday", flavor matches the
      mockup exactly ("A thoughtful day of preparation strengthens the
      work ahead."), activities are Service prep + Return visit prep,
      GO OUT IN SERVICE button appears.
- [ ] **Today's Schedule updates per day.** On Thursday, schedule reads:
      Morning "Personal study and prayer", Midday "Service and return
      visit preparation", Evening "Review the day and plan tomorrow"
      — matches the mockup wording.
- [ ] **Saturday → GO OUT IN SERVICE.** Advance to Saturday. Title
      "Week 1 — Saturday", flavor "Field service day. Go out and
      preach.", single Field Service activity row, GO OUT IN SERVICE
      visible. Click it → territory_map. End Field Service → returns
      to week_view as Sunday Week 2 with new schedule.
- [ ] **Top banner stat live wiring.** During a Saturday: visit a
      house, return to territory_map → Hours This Month updates to
      0.3 in the banner. End Field Service → week_view shows the same
      0.3 still in the banner (state preserved across scene change).
- [ ] **ESC + back button.** Press ESC anywhere on week_view → returns
      to main menu. Clicking "← BACK TO MENU" does the same.
- [ ] **Layout sanity at 1920×1080.** Center card sits roughly mid-
      screen, schedule card pinned to the right with ~24px margin,
      back button bottom-left ~16px in.
- [ ] **No regression.** territory_map still renders correctly with
      hover/select/click. door_knock still loads with the legacy HUD
      (intentional).

## Post-M4-LF2 playtest priorities

- **Painted desk-scene background.** Closest L&F gap. If the flat
  deep-sepia fill reads as too thin compared to the mockup, queue a
  3-asset add (window-view background, sacred writings book stack,
  Lighthouse magazine) and overlay them like the territory map's
  parked car.
- **Icon glyph rendering.** ☀ ☾ ✎ ✦ 📖 may render inconsistently
  depending on Godot's bundled fallback font coverage. If any glyph
  squares or boxes (tofu), swap to plain letters M/D/E for periods
  or to ✦ for everything.
- **Schedule content is generic on personal-time days.** Mon/Wed/Fri
  schedule strings (working day / lunch / personal study) are honest
  but flat — playtest may show they need more texture. Easy to enrich
  in `week_view.gd::DAY_CONTENT`.
- **Title font size = 44.** Lifts off the mockup's serif weight. If
  the default sans reads thin at 44pt, a serif TTF (EB Garamond per
  M4-LF1 follow-up) lands the diegetic feel better.

## Previous milestone

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

## Locked design decisions this session (M4-LF1)

Seven Phase 1 decisions, all resolved on recommendations.

- **Q1: HUD scope = all 6 resources from the mockup.** Conviction,
  Elders, Congregation, Family, Energy, Hours This Month. All fields
  already existed on `ResourceManager` with sensible defaults — wire-
  only, no schema changes. Top banner labels live inline in
  `territory_map.tscn`; values bound to `ResourceManager` and refreshed
  via the existing `SignalBus.resource_changed` signal.
- **Q2: End Field Service = silent SAT → SUN advance.** Preserved the
  M2-era behavior: `TimeManager.advance_phase()` then
  `change_scene_to_file("res://scenes/week_view.tscn")`. Plus a new
  bottom-left "ESC ← Back" button that returns to week_view *without*
  advancing time, bound to `ui_cancel` for keyboard parity.
- **Q3: Scripture quote = hardcoded for v1.** "Let your light shine
  before others..." — MATTHEW 5:16. Const on the scene script
  (`SCRIPTURE_QUOTE` / `SCRIPTURE_REF`). Per-territory variation
  deferred to M5+ multi-territory work.
- **Q4: Banner tagline = permanent branding.** "Remember the good
  news. — MARK 13:10". Static label in the scene file; identical on
  every load.
- **Q5: Single shared detail-panel painting confirmed.** All 12 slots
  share `assets/sprites/territory/house_painting.png`. Per-state copy
  (caption + body) varies via the script's `_caption_for_state` /
  `_body_for_state` matches. Per-house art deferred to M4.4+.
- **Q6: Today's Progress aggregator = SignalBus listener with cached
  counters on the scene.** `_tract_left_count`, `_return_visit_count`,
  `_studies_started_count` rebuild from `current_territory.houses` on
  `_ready` (survives re-entry) and recompute on
  `territory_house_visited`. No per-frame work.
- **Q7: Slot interaction = hover-selects, click-commits.** Mouseover
  populates the right detail panel + paints a 3px gold border on the
  selected slot. Click commits unchanged: `set_pending_house` →
  `change_scene_to_file` for door_knock. ESC (ui_cancel) routes
  through the back button handler.

## Locked implicit decisions

- **Typography = Godot default font.** No serif TTF added in M4-LF1.
  Visual differentiation between diegetic and system text comes from
  size + casing (uppercase eyebrows for system, large mixed-case for
  diegetic place names). EB Garamond pass deferred to a later L&F
  follow-up if playtest demands.
- **Asset placement.** Three painted files copied (originals kept) from
  `docs/design/mockups/` to `assets/sprites/territory/`. Runtime
  references live under `assets/`.
- **Shared `hud.tscn` untouched.** Bespoke top banner inline in
  `territory_map.tscn` only; `week_view` and `door_knock` continue to
  instance the original vertical HUD.

## Completed this session (M4-LF1)

- **`assets/sprites/territory/{background,house_painting,car}.png`** —
  three painted assets copied from `docs/design/mockups/`. Triggered
  `godot --headless --import` to materialize the `.import` resources
  so the Texture2D ext_resource refs in the scene resolve.
- **`scenes/territory_map.tscn`** — full rebuild. Discarded the
  M2-era `CenterPanel + GridContainer` of grey buttons and removed the
  HUD instance for this scene. New tree: dark-sepia root background,
  top banner (`TopBanner` PanelContainer with brand column + 6-stat
  HBox), main row (`LeftInfoCard` / `CenterMap` / `RightDetailPanel`),
  bottom-left parked-car decoration, bottom-left ESC back button,
  bottom-right styled "END FIELD SERVICE" button. All non-painted UI
  elements (panels, dividers, badge swatches, ornament glyphs) drawn
  via `StyleBoxFlat` + Label.
- **`scripts/ui/territory_map.gd`** — substantial rewrite.
  - `SLOT_FRACTIONS` const: 12 `Vector4(x, y, w, h)` fractional offsets
    of the `CenterMap` rect. `_layout_slots()` re-resolves to pixel
    positions on `_ready` (one frame later, so the container has its
    final size) and on `_map_area.resized`. Tuned by eye against the
    background art's 4×3 yard grid.
  - `_make_slot()` builds each slot as: a `Hit` PanelContainer (empty
    style box; gold border when selected), a `Medallion` Panel
    (38×38 navy disc with gold border, numeral 1-12 inside), and a
    bottom-anchored `Badge` PanelContainer with state-dependent color
    and label.
  - Badge color + text resolution in `_badge_info_for_state(state)`:
    green for TRACT_LEFT and BIBLE_STUDY_STARTED, amber for
    RETURN_VISIT_SCHEDULED, deep red for REFUSED, grey for NOT_HOME,
    cream for NOT_VISITED. `TerritoryManager.outcome_label()` is left
    untouched — the new NOT_VISITED string lives view-side.
  - Hover wiring on the slot's root Control: `mouse_entered` →
    `_select(house_id)` which repaints the previously-selected slot,
    paints the new gold outline, and populates the detail panel.
  - Click via `gui_input` on the slot root → `_commit_visit(house_id)`
    which preserves the existing
    `TerritoryManager.set_pending_house` → `change_scene_to_file`
    contract used by M2/M3/M4 code paths.
  - `_caption_for_state` + `_body_for_state` provide the right-panel
    copy table per the plan (NOT_VISITED: "No prior contact." / "This
    household has not been visited yet. A good opportunity to introduce
    the message.", plus one line each for visited states).
  - `_refresh_progress()` scans `current_territory.houses` and writes
    the three Today's Progress values. Called once on `_ready` and on
    every `territory_house_visited` emission. 12 houses; per-frame is
    not needed.
  - `_refresh_hud()` reads all six fields off `ResourceManager` and
    writes them into the top banner's value labels. Wired to
    `SignalBus.resource_changed` for live updates (e.g. when
    `add_hours(0.25)` fires on door resolve).
  - `_build_legend()` constructs the right-panel legend at runtime so
    the swatch colors stay in lock-step with the badge `Color`
    constants (no chance of the scene file drifting from the script).
  - ESC and the back button both call `_on_back_pressed()` → return
    to `week_view` without advancing the clock.

## Files unchanged by intent (M4-LF1)

- `scenes/hud.tscn`, `scripts/ui/hud.gd` — still used by `week_view`
  and `door_knock`. Confirmed via grep.
- `scripts/systems/resource_manager.gd` — all 6 HUD resources already
  present with mockup-matching defaults (Conviction 50, Elders 0,
  Cong 0, Family 0, Energy 10/10, Hours 0.0).
- `scripts/systems/territory_manager.gd::outcome_label()` — unchanged;
  the NOT_VISITED label lives in the scene script's badge dict so the
  manager's pure outcome→label resolution stays minimal.
- `scripts/systems/time_manager.gd::advance_phase()` — already advances
  SAT → SUN and fires `week_advanced` on wrap. Drives End Field Service
  with zero changes.
- `scripts/systems/signal_bus.gd::territory_house_visited` — already
  fired inside `TerritoryManager.resolve_pending_house`. Drives
  Today's Progress + per-slot badge refresh without per-frame work.
- `scripts/entities/house.gd`, `territory.gd`, `householder.gd` — no
  schema changes; reused as-is.

## Gate verification — Andrew's checklist (M4-LF1)

**Headless boot: clean.** `godot --headless --quit-after 4
res://scenes/territory_map.tscn` returns 0 errors; the only warnings
are the standard "ObjectDB instances leaked at exit" and "26 resources
still in use at exit" which are normal `--quit-after` cleanup.

**Visual gate (Andrew runs editor playtest):**

- [ ] **Layout at 1920×1080.** Three columns visible: ~320px info card
      left, painted map centered, ~320px detail panel right. Top
      banner spans full width at 88px. END FIELD SERVICE styled button
      anchored bottom-right; ESC ← Back text button bottom-left.
- [ ] **Banner branding.** "GO OUT AND PREACH" + tagline left-aligned;
      6 stat readouts (CONVICTION 50, ELDERS 0, CONGREGATION 0, FAMILY
      0, ENERGY 10 / 10, HOURS THIS MONTH 0.0) right-aligned.
- [ ] **Info card content.** "✦ SATURDAY · FIELD SERVICE ✦" eyebrow,
      "Maple Street" large title, flavor sentence, TODAY'S PROGRESS
      header with Tract Left / Return Visits / Studies Started rows
      (all 0 at fresh load), scripture quote + "— MATTHEW 5:16" at
      bottom of the card.
- [ ] **Map slots.** 12 numbered medallions (1-12) sit roughly over
      the 4×3 yard grid in the painted background. Each slot has a
      cream "NOT VISITED" badge below the medallion at fresh load.
- [ ] **Hover/select.** Mouseover slot #1 → gold 3px outline appears
      on slot, detail panel updates to "✦ HOUSE #1 ✦" + "No prior
      contact." caption + body sentence. Move to slot #11 → outline
      follows; detail panel switches. Move to slot #7 → same (it's
      still PR-placeholder for M4.3).
- [ ] **Click commit.** Click slot #1 → routes to door_knock as before
      with PR archetype. Resolve TRACT_LEFT and return. Slot #1's
      badge is now green "TRACT LEFT". Detail panel still shows slot
      #1 selected with the TRACT_LEFT caption/body. Today's Progress
      shows Tract Left = 1. Banner Hours = 0.3 (or 0.2 — the format
      truncates).
- [ ] **All five outcome badge colors render.** Visit one of each
      outcome (PR #1 → TRACT_LEFT/green; HS #2 → REFUSED/red; CS #4 →
      RETURN_VISIT/amber; CS #9 → STUDY_STARTED/green). Confirm color
      mapping. (NOT_HOME has no producer yet — see note below.)
- [ ] **Today's Progress accuracy.** After the four visits above:
      Tract Left = 1, Return Visits = 1, Studies Started = 1. Hours
      banner = 1.0.
- [ ] **End Field Service.** Click button → `TimeManager` advances
      SAT → SUN, scene swaps to week_view, week_view shows "Sunday"
      with Public Talk / Lighthouse Study activities. Hours This
      Month preserved.
- [ ] **Back button + ESC.** Press ESC or click back button → returns
      to week_view *without* advancing the clock. current_phase still
      SATURDAY.
- [ ] **No regression.** `door_knock.tscn` still loads with the
      original vertical HUD top-right (shared `hud.tscn` unchanged).
      `week_view.tscn` likewise.
- [ ] **Visual sanity against mockup.** Side-by-side compare with
      `docs/design/mockups/territory_map_v1.png`. Banner branding,
      info card cadence, badge colors, gold selection outline, parked
      car position, end-button styling should all read as the same
      artifact.

## Post-M4-LF1 playtest priorities

Carried forward and added during M4-LF1. Touch only if a session
reveals an issue.

- **Slot fraction tuning.** `SLOT_FRACTIONS` in `territory_map.gd` was
  set by eye from the background art's 4×3 grid. If a row or column
  of medallions visually drifts off the yards in the painted image,
  nudge the affected entries. The eye-by-eye tuning is the cheapest
  iteration here.
- **NOT_HOME has no producer.** No archetype currently yields the
  NOT_HOME outcome (cf. STATUS "Known gaps / deferred" — NOT_HOME
  stays a territory-level mechanic). The badge color/text is wired
  in case it lands later; legend entry left for now.
- **Single shared detail-panel painting.** May read as obvious reuse
  to a tester. M4.4 carries per-house art variants if playtest flags
  it. The state copy strings are deliberately neutral — they describe
  the player's last interaction, not the house, which softens the
  reuse tell.
- **Typography is plain default font.** Diegetic accents (scripture
  quote, "Maple Street" header) lack the serif treatment GDD § 9 calls
  for. Acceptable for v1; queue an EB Garamond TTF drop if playtest
  finds the look "thin."
- **No confirm modal on End Field Service.** If a playtester misclicks
  and burns their Saturday accidentally, surface this as a feedback
  point — the confirm-with-summary modal alternative from Phase 1 is
  cheap to add later.
- **Carried from M4.2/M4.1**: three `# UNSURE` flags in
  `curious_seeker_v1.dtl`, `UNSURE:` on line 39 of
  `polite_refuser_v1.dtl`, N=25 calibration, reveal-40 text,
  T1 brittleness, dialogic_character dead-code cleanup, HS pool
  weighting, T4 study-counts question — see prior sessions for
  detail.

## Previous milestones (M4.1)

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

## Roadmap after M4-LF1

- **M4.3 — The Apostate (Wounded variant): Phases 0–2 shipped.**
  See "M4.3 — The Apostate (Wounded variant): Phases 0–2 complete"
  above. Next up: Phase 3 dialogue subagent pass (DRAFT PENDING
  placeholders → final line text in `apostate_wounded_v1.dtl`).
  Then Phase 4 (Andrew playtest at House #7) and Phase 5 (this
  STATUS, already updated). The "+doubt on positive outcomes"
  mechanic shipped as Option A (extend `doubt_delta_overrides` per
  outcome, zero schema change). Hostile + Gentle variants queue
  for M4.4.
- **M4.4 — Hostile + Gentle Apostate variants + within-archetype
  variety + remaining archetypes.** Hostile and Gentle Apostate
  variants take priority; calibration questions in "Next session
  (queued)" block. Pre-existing M4.4 scope still in play:
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

- **M4.3 Phase 3 — Wounded Apostate dialogue subagent pass.**
  Highest priority next session. See "Next session (queued)"
  above. Wounded variant structural ship is done; Phase 3 fills
  `[DRAFT PENDING — …]` placeholders in `apostate_wounded_v1.dtl`
  with final line text per the goop-character skill template.
- **M4-LF1 visual gate playtest** — see "Gate verification" above.
  Andrew opens the editor, plays a Saturday, walks the checklist.
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
- **Real portraits and door_knock backgrounds** — placeholder
  ColorRects still through M4-LF1. The territory map has its painted
  background, house painting, and parked car after M4-LF1; portraits
  and porch scenes for door_knock remain placeholder until a later
  art pass.
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
