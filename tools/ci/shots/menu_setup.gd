extends RefCounted
## Screenshot setup: the New Game card.

func after_load(tree: SceneTree) -> void:
	tree.current_scene.call("_on_new_game_pressed")
