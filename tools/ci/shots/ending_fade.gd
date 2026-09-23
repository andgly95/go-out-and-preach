extends RefCounted
## Screenshot setup: the Quiet Fade ending, partway through.

func setup(_tree: SceneTree) -> void:
	GameState.autosave_enabled = false
	GameState.new_game("Jordan", "Sister", "mother")
	GameState.ending_id = &"quiet_fade"


func after_load(tree: SceneTree) -> void:
	for i in 3:
		for f in 30:
			await tree.process_frame
		Dialogic.Inputs.handle_input()
