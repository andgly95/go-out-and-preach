extends RefCounted
## Screenshot setup: end of month 1 for a pioneer who fell short.

func setup(_tree: SceneTree) -> void:
	GameState.autosave_enabled = false
	GameState.new_game("Jordan", "Sister", "mother")
	GameState.decide_pioneer(true)
	ResourceManager.set_hours(24.5)
	GameState.month["placements"] = 6
	GameState.month["return_visits"] = 2
	GameState.month["study_sessions"] = 1
