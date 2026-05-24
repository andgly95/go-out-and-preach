# STATUS

Last updated: 2026-05-23

## Next session (queued)

**M4.3 — The Apostate.** Three variants per cast.md § 6.6 (Hostile /
Wounded / Gentle). Doubt deltas calibration-sensitive — surface in
Phase 1. With M4.1's `doubt_delta_overrides` field already in place,
Apostate-specific deltas live in `data/householders/apostate.tres` (or
three variants: `apostate_hostile.tres`, `apostate_wounded.tres`,
`apostate_gentle.tres`). The +doubt-on-positive-outcome semantic does
need a small mechanism beyond the overlay — likely a per-archetype
"positive outcomes also cost N" flag, or full custom deltas including
positive ones (`{"REFUSED": 4, "TRACT_LEFT": 3, ...}`). Surface in
M4.3 Phase 1.

House #7 is the reserved slot (currently rendering Polite Refuser as
placeholder per `territory_manager.gd::DISTRIBUTION`).

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

- **M4.3 — The Apostate (NEXT).** See "Next session (queued)" above.
  Dedicated session
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

- **M4.3 — The Apostate.** Highest priority next session. Three
  variants per cast.md § 6.6 (Hostile / Wounded / Gentle). Doubt deltas
  calibration-sensitive — surface in Phase 1. House #7 in Maple Street
  is the reserved slot; it currently renders Polite Refuser as
  placeholder per `territory_manager.gd::DISTRIBUTION`.
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
