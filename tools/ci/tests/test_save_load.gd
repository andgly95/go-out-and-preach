extends "res://tools/ci/test_case.gd"
## Save/load round trip and run-state basics.


func test_snapshot_round_trip() -> void:
	GameState.new_game("Ruth", "Sister", "father")
	GameState.decide_pioneer(true)
	for i in 9:
		TimeManager.advance_phase()
	ResourceManager.add_hours(6.5)
	ResourceManager.add_standing_family(-4)
	DoubtMeter.expose(7.0, &"test")
	var house: House = TerritoryManager.get_house(&"house_9")
	house.state = House.State.BIBLE_STUDY_STARTED
	house.visit_count = 3
	house.study_sessions = 2
	house.arc_state = &"returning"
	GameState.set_flag("activity_family_worship", 2)
	var before: Dictionary = SaveLoad.snapshot()

	GameState.new_game()
	SaveLoad.restore(before)

	check_eq(GameState.player_name, "Ruth", "player name restored")
	check_eq(GameState.parent_word, "Dad", "parent restored")
	check_eq(TimeManager.current_week, 2, "week restored")
	check_eq(TimeManager.current_phase, TimeManager.Phase.TUESDAY, "day restored")
	check(is_equal_approx(ResourceManager.field_service_hours, 6.5), "hours restored")
	check_eq(ResourceManager.standing_family, -4, "family standing restored")
	check(is_equal_approx(DoubtMeter.exact, before["doubt"]["exact"]), "doubt restored")
	check_eq(GameState.month.get("aux_pioneer"), true, "pioneer commitment restored")
	var restored: House = TerritoryManager.get_house(&"house_9")
	check_eq(restored.state, House.State.BIBLE_STUDY_STARTED, "study appointment restored")
	check_eq(restored.study_sessions, 2, "study session count restored")
	check_eq(restored.arc_state, &"returning", "arc state restored")
	check_eq(GameState.flag("activity_family_worship"), 2, "flags restored")
	check_eq(SaveLoad.snapshot(), before, "a restored snapshot matches the original")


func test_appointments_survive_the_week_but_refusals_reset() -> void:
	var rv: House = TerritoryManager.get_house(&"house_5")
	var refused: House = TerritoryManager.get_house(&"house_1")
	rv.state = House.State.RETURN_VISIT_SCHEDULED
	refused.state = House.State.REFUSED
	for i in 7:
		TimeManager.advance_phase()
	check_eq(rv.state, House.State.RETURN_VISIT_SCHEDULED, "return visit persists into next week")
	check_eq(refused.state, House.State.NOT_VISITED, "refusal clears at the week boundary")


func test_month_close_resets_hours_and_advances() -> void:
	GameState.autosave_enabled = false
	for i in 27:
		TimeManager.advance_phase()
	check_eq(TimeManager.current_phase, TimeManager.Phase.SATURDAY, "reached the last Saturday of month 1")
	ResourceManager.add_hours(12.0)
	check_eq(GameState.end_day(), GameState.SCENE_MONTH_REPORT, "last Saturday of the month goes to the report")
	check_eq(GameState.close_month(), GameState.SCENE_WEEK, "month 1 closes into week 5")
	check_eq(TimeManager.current_week, 5, "week 5 begins")
	check(is_equal_approx(ResourceManager.field_service_hours, 0.0), "hours reset for the new month")
	check_eq(GameState.months.size(), 1, "month 1 filed")
	check(is_equal_approx(float(GameState.months[0]["hours"]), 12.0), "month 1 hours recorded")
	GameState.autosave_enabled = true


func test_run_ends_after_week_eight() -> void:
	GameState.autosave_enabled = false
	for i in 27:
		TimeManager.advance_phase()
	GameState.end_day()
	GameState.close_month()
	for i in 27:
		TimeManager.advance_phase()
	check_eq(TimeManager.current_week, 8, "reached week 8")
	check_eq(GameState.end_day(), GameState.SCENE_MONTH_REPORT, "week 8 Saturday goes to the report")
	check_eq(GameState.close_month(), GameState.SCENE_ENDING, "month 2 closes into the ending")
	check(GameState.ending_id != &"", "an ending was chosen")
	GameState.autosave_enabled = true
