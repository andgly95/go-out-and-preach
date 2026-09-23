extends RefCounted
## Screenshot setup: month end after skipping meetings — the shepherding talk.

func setup(_tree: SceneTree) -> void:
	GameState.autosave_enabled = false
	GameState.new_game("Jordan", "Brother", "father")
	GameState.month["meetings_skipped"] = 3
	ResourceManager.set_standing_family(-12)


func after_load(tree: SceneTree) -> void:
	tree.current_scene.call("_on_hand_in_pressed")
	for i in 6:
		for f in 20:
			await tree.process_frame
		Dialogic.Inputs.handle_input()
