extends "res://tools/ci/test_case.gd"
## The habits tree (Habits autoload, data/habits/): the data is well formed,
## practice forms habits and opens forks, a choice closes the other side,
## effects reach the systems, the lately track waits for doubt, and it all
## survives a save.

const TRACK_IDS: Array[StringName] = [&"ministry", &"study", &"congregation", &"home"]

# Every modifier key a system reads. A typo in a .tres would otherwise do
# nothing, silently.
const KNOWN_MODIFIERS: Array[String] = [
	"service_morning_energy", "service_extension_energy", "return_visit_stops", "study_stops",
	"conviction_wear_scale", "gate_offset", "family_loss", "comment_elders", "skip_energy",
]
const KNOWN_PREFIXES: Array[String] = ["energy:", "conviction:", "relief:"]


func test_every_track_has_one_habit_then_a_fork() -> void:
	for track in TRACK_IDS:
		var first: Array[Habit] = Habits.habits_on(track, 1)
		var fork: Array[Habit] = Habits.habits_on(track, 2)
		check_eq(first.size(), 1, "%s: one habit forms by itself" % track)
		check_eq(fork.size(), 2, "%s: a fork of two" % track)
		if first.size() == 1 and fork.size() == 2:
			check(first[0].practice < fork[0].practice, "%s: the first habit comes before the fork" % track)
			check_eq(fork[0].practice, fork[1].practice, "%s: both sides of the fork open together" % track)
	check(not Habits.habits_on(Habits.LATELY_TRACK).is_empty(), "the lately track has habits")
	for habit in Habits.habits_on(Habits.LATELY_TRACK):
		check(habit.min_doubt >= DoubtMeter.THRESHOLD_AMBIGUOUS,
			"%s: nothing on the lately track shows before doubt reaches 40" % habit.id)


func test_habit_text_and_modifiers_are_complete() -> void:
	var ids: Dictionary = {}
	for habit in Habits.all_habits():
		check(not ids.has(habit.id), "habit id %s is unique" % habit.id)
		ids[habit.id] = true
		check(not habit.title.is_empty() and not habit.flavor.is_empty() and not habit.effect_text.is_empty(),
			"%s has a title, a line, and an effect" % habit.id)
		check(not habit.modifiers.is_empty(), "%s does something" % habit.id)
		for key in habit.modifiers:
			var known: bool = KNOWN_MODIFIERS.has(String(key))
			for prefix in KNOWN_PREFIXES:
				known = known or String(key).begins_with(prefix)
			check(known, "%s: unknown modifier %s" % [habit.id, key])


func test_practice_forms_the_first_habit_then_offers_the_fork() -> void:
	var cost_before: int = FieldService.morning_energy_cost()
	Habits.add_practice(&"ministry")
	check(not Habits.has(&"car_group"), "one morning is not a habit yet")
	Habits.add_practice(&"ministry")
	check(Habits.has(&"car_group"), "two mornings form the car group")
	check_eq(FieldService.morning_energy_cost(), cost_before - 1, "a morning costs one less")
	var notice: Habit = Habits.take_unseen()
	check(notice != null and notice.id == &"car_group", "the new habit waits to be shown")
	check(Habits.take_unseen() == null, "and is shown once")
	for i in 3:
		Habits.add_practice(&"ministry")
	check(Habits.choices_pending.has(&"ministry"), "five mornings open the fork")
	check_eq(Habits.next_step_text(&"ministry"), tr("A choice is waiting."), "the card says so")


func test_choosing_keeps_one_side_and_closes_the_other() -> void:
	for i in 5:
		Habits.add_practice(&"study")
	Habits.unseen.clear()
	Habits.choose(&"reads_the_whole_chapter")
	check(Habits.has(&"reads_the_whole_chapter"), "the chosen habit is kept")
	check(Habits.is_closed(&"ready_answers"), "the other side closes")
	check(not Habits.choices_pending.has(&"study"), "the fork is settled")
	check(Habits.take_unseen() == null, "a chosen habit isn't announced again")
	for i in 10:
		Habits.add_practice(&"study")
	check(not Habits.choices_pending.has(&"study"), "a settled fork never reopens")
	Habits.choose(&"ready_answers")
	check(not Habits.has(&"ready_answers"), "a closed habit can't be taken later")
	check_eq(DoubtMeter.noticing, DoubtMeter.value + 10, "greyed-out choices open ten points sooner")


func test_activities_and_meetings_count_as_practice() -> void:
	var study: Activity = Evenings.get_activity(&"personal_study")
	var worship: Activity = Evenings.get_activity(&"family_worship")
	var base_cost: int = Evenings.energy_cost(study)
	Evenings.choose(study)
	Evenings.finish()
	Evenings.choose(worship)
	Evenings.finish()
	check_eq(Habits.practice_on(&"study"), 2, "study and family worship both count for Study")
	check_eq(Habits.practice_on(&"home"), 1, "family worship counts for Home")
	check(Habits.has(&"underlines_the_answers"), "two evenings of study form a habit")
	check_eq(Evenings.energy_cost(study), maxi(base_cost - 1, 0), "personal study costs one less")
	MeetingManager.begin_meeting(&"tuesday_meeting")
	MeetingManager.resolve_meeting_completed(&"tuesday_meeting")
	check_eq(Habits.practice_on(&"congregation"), 1, "a meeting counts for Congregation")


func test_lately_waits_for_doubt() -> void:
	DoubtMeter.apply(39, &"test")
	TimeManager.advance_phase()
	check(not Habits.lately_visible(), "nothing on the lately track below 40")
	var tuesday: int = MeetingManager.energy_cost_for(&"tuesday_meeting")
	DoubtMeter.apply(2, &"test")
	TimeManager.advance_phase()
	check(Habits.has(&"sitting_through_it"), "at 40, the next morning, meetings get heavier")
	check(Habits.lately_visible(), "and the lately track appears")
	check_eq(MeetingManager.energy_cost_for(&"tuesday_meeting"), tuesday + 1, "a meeting costs one more")
	DoubtMeter.apply(-30, &"test")
	TimeManager.advance_phase()
	check(Habits.lately_visible(), "it stays once it has appeared")


func test_keeps_the_peace_softens_family_losses() -> void:
	for i in 5:
		Habits.add_practice(&"home")
	Habits.choose(&"keeps_the_peace")
	ResourceManager.add_standing_family(-1)
	check_eq(ResourceManager.standing_family, 0, "a small loss is absorbed")
	ResourceManager.add_standing_family(-3)
	check_eq(ResourceManager.standing_family, -2, "a larger one is one smaller")
	ResourceManager.add_standing_family(2)
	check_eq(ResourceManager.standing_family, 0, "gains are untouched")


func test_habits_survive_a_save() -> void:
	for i in 5:
		Habits.add_practice(&"congregation")
	for i in 9:
		Habits.add_practice(&"ministry")
	Habits.choose(&"second_hour")
	var before: Dictionary = SaveLoad.snapshot()
	GameState.new_game()
	check(Habits.formed.is_empty(), "a new game starts with no habits")
	SaveLoad.restore(before)
	check(Habits.has(&"second_hour") and Habits.has(&"sunday_morning"), "formed habits restored")
	check(Habits.is_closed(&"return_visit_notebook"), "closed habits restored")
	check_eq(Habits.practice_on(&"ministry"), 9, "practice restored")
	check_eq(SaveLoad.snapshot()["habits"], before["habits"], "habits snapshot round-trips")
