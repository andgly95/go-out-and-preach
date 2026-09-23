extends RefCounted
## Screenshot setup: Daniel's second study session, on a long line.

func setup(_tree: SceneTree) -> void:
	GameState.autosave_enabled = false
	GameState.new_game("Jordan", "Brother", "mother")
	for i in 6:
		TimeManager.advance_phase()
	var house: House = TerritoryManager.get_house(&"house_9")
	house.state = House.State.BIBLE_STUDY_STARTED
	house.study_sessions = 1
	house.visit_count = 2
	house.arc_state = &"returning"
	FieldService.start_session()
	TerritoryManager.set_pending_house(&"house_9")


func after_load(tree: SceneTree) -> void:
	for i in 2:
		for f in 40:
			await tree.process_frame
		Dialogic.Inputs.handle_input()
	for f in 120:
		await tree.process_frame
