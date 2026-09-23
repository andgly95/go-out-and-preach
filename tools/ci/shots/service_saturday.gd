extends RefCounted
## Screenshot setup: Saturday service with a return visit and a study on the map.

func setup(_tree: SceneTree) -> void:
	GameState.autosave_enabled = false
	GameState.new_game("Jordan", "Brother", "mother")
	for i in 6:
		TimeManager.advance_phase()
	var rv: House = TerritoryManager.get_house(&"house_5")
	rv.state = House.State.RETURN_VISIT_SCHEDULED
	rv.visit_count = 1
	var study: House = TerritoryManager.get_house(&"house_9")
	study.state = House.State.BIBLE_STUDY_STARTED
	study.visit_count = 2
	FieldService.start_session()
