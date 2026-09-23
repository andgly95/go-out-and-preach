extends RefCounted
## Screenshot setup: new game, advance to Monday of week 1.

func setup(_tree: SceneTree) -> void:
	GameState.autosave_enabled = false
	GameState.new_game("Jordan", "Sister", "mother")
	GameState.decide_pioneer(true)
	TimeManager.advance_phase()
