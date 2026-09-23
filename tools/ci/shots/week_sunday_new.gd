extends RefCounted
## Screenshot setup: a fresh run on its first Sunday (pioneer decision).

func setup(_tree: SceneTree) -> void:
	GameState.autosave_enabled = false
	GameState.new_game("Jordan", "Brother", "father")
