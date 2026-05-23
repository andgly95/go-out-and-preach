extends Node
## Global event bus. Autoloaded as SignalBus.
## Systems emit and listen here rather than calling each other directly.

# Time / week progression (M1)
signal week_advanced(new_week: int)
signal day_advanced(new_day: int)
signal phase_changed(phase: int)

# Resources (M1)
signal resource_changed(resource_name: String, new_value: float)

# Doubt (M4) — hidden until thresholds
signal doubt_threshold_crossed(threshold: int)

# Dialogue / scene navigation (M3+)
signal dialogue_started(dialogue_id: String)
signal dialogue_ended(dialogue_id: String)
signal scene_requested(scene_path: String)
