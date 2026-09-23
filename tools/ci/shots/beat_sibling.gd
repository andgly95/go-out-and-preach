extends RefCounted
## Screenshot setup: the week 1 Wednesday sibling texts, a few lines in.

func setup(_tree: SceneTree) -> void:
	GameState.autosave_enabled = false
	GameState.new_game("Jordan", "Sister", "mother")
	for i in 3:
		TimeManager.advance_phase()
	Story.play(Story.beat_for_today())


func after_load(tree: SceneTree) -> void:
	for i in 4:
		for f in 20:
			await tree.process_frame
		Dialogic.Inputs.handle_input()
