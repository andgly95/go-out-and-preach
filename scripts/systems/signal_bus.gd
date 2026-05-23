extends Node
## Global event bus. Autoloaded as SignalBus.
## Systems emit and listen here rather than calling each other directly.
##
## Every signal carries an @warning_ignore("unused_signal") because the
## SignalBus declares signals while emitters live in other classes — the
## "unused" check is structurally wrong for this pattern.

# Time / week progression (M1)
@warning_ignore("unused_signal")
signal week_advanced(new_week: int)
@warning_ignore("unused_signal")
signal day_advanced(new_day: int)
@warning_ignore("unused_signal")
signal phase_changed(phase: int)

# Resources (M1)
@warning_ignore("unused_signal")
signal resource_changed(resource_name: String, new_value: float)

# Territory (M2)
@warning_ignore("unused_signal")
signal territory_house_visited(house_id: StringName, outcome: int)

# Doubt (M4) — hidden until thresholds
@warning_ignore("unused_signal")
signal doubt_threshold_crossed(threshold: int)

# Dialogue / scene navigation (M3+)
@warning_ignore("unused_signal")
signal dialogue_started(dialogue_id: String)
@warning_ignore("unused_signal")
signal dialogue_ended(dialogue_id: String)
@warning_ignore("unused_signal")
signal scene_requested(scene_path: String)
