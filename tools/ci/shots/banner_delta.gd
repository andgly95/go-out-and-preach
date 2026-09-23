extends RefCounted
## Screenshot setup: meters changed just before the scene loaded.

func setup(_tree: SceneTree) -> void:
	GameState.autosave_enabled = false
	GameState.new_game("Jordan", "Sister", "mother")
	TimeManager.advance_phase()
	ResourceManager.add_conviction(-3)
	ResourceManager.add_standing_family(2)
	ResourceManager.add_energy(-2)
