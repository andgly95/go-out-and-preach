# STATUS

Last updated: 2026-05-22

## Current milestone

**M0 — Scaffold: complete.**

The project skeleton, autoloads, and main-menu shell are in place. Opening the
project in Godot 4.x and pressing Play boots into the main menu. New Game,
Continue, and Settings print to the console; Quit closes the window.

## Completed this session (M0)

- `project.godot` configured: main scene set to `scenes/main_menu.tscn`, 1920×1080
  viewport with `canvas_items` + `keep` aspect, Compatibility renderer (2D-only).
- Full GDD § 11 directory tree scaffolded with `.gdkeep` placeholders in empty
  leaves (data/, assets/, ui/, addons/).
- `SignalBus` autoload at `scripts/systems/signal_bus.gd` — declares
  forward-looking signals for time, resources, doubt, dialogue, and scene
  navigation. Nothing emits or listens yet.
- `PlayerState` autoload at `scripts/entities/player_state.gd` — empty stub.
- `scenes/main_menu.tscn` + `scripts/ui/main_menu.gd` — four buttons, placeholder
  behavior (print to console; Quit actually quits).
- `icon.svg` placeholder.

## Next session entry point — M1: Time & Resources

Per GDD § 13. Suggested order:

1. **`scripts/systems/time_manager.gd`** — week-phase enum (Sunday → Saturday per
   GDD § 4), current week counter, `advance_phase()` / `advance_day()` /
   `advance_week()` methods. Emit `SignalBus.phase_changed` /
   `day_advanced` / `week_advanced`.
2. **`scripts/systems/resource_manager.gd`** — meters from GDD § 5.1 (Field
   Service Hours, Energy, Standing: Elders/Congregation/Family, Conviction).
   Energy resets on `day_advanced`; Hours reset on month boundary. Emit
   `SignalBus.resource_changed`.
3. **`scripts/ui/hud.gd` + HUD scene** — display Conviction + the three Standing
   meters + Energy + this-month Hours. Listen to `resource_changed`. Do *not*
   show Doubt — hidden until M4 threshold logic ships.
4. **`scenes/week_view.tscn`** — current day label, "advance to next phase"
   button, HUD overlay. This is the M1 default scene after New Game; later
   milestones replace the advance button with real actions (field service,
   meetings, home, journal).

**Wire-up note:** M1 should change `run/main_scene` to `week_view.tscn` *only*
for dev iteration if convenient — but the New Game button in `main_menu.gd`
should be the canonical entry point (load `week_view.tscn` via
`get_tree().change_scene_to_file()`). Don't lose the main menu.

## Open design questions

None new from M0. The questions in GDD § 15 remain open — most surface at M3
(dialogue) and M4 (doubt UI) playtests.

## Known gaps / deferred decisions

- **Dialogue plugin (Dialogic vs godot-ink):** decision deferred to M3 per
  GDD § 10. `addons/` is empty.
- **Settings menu:** placeholder only. Real implementation lands in M7.
- **Save/load:** not yet wired. Continue button is a stub. M7.
- **Localization:** button/label text lives in the `.tscn` as plain strings;
  Godot's auto-translate will route them through `tr()` at runtime. No PO/POT
  files yet — extract when v1 string set stabilizes.
- **Authenticity notes / dialogue style guide:** referenced by CLAUDE.md but not
  yet created. Andrew populates `docs/design/authenticity-notes.md` before M3
  dialogue work; `dialogue-style-guide.md` is written at the start of M3.
