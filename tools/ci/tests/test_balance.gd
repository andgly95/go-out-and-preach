extends "res://tools/ci/test_case.gd"
## Balance simulation: plays whole eight-week runs through the real systems
## (FieldService, MeetingManager, Evenings, GameState) with scripted player
## styles, prints what happened, and checks the targets in
## docs/design/v01-loop.md § Conviction and doubt.
## Door choices approximate each archetype's real options, including the
## doubt-gated off-script choice. Scene-only [signal] effects are not
## simulated, so keep those small relative to an activity's base effects.
##
## Run alone:  bash tools/godot.sh --headless --script res://tools/ci/run_tests.gd -- --only=balance

const RUNS_PER_STYLE: int = 60
const SEED: int = 20260923

const STYLES: Dictionary = {
	# Signs up to pioneer, never misses, extends service, picks the "good"
	# publisher answer at every door.
	"devout": {
		"pioneer": true, "attend": 1.0, "thursday": 1.0, "saturday": 1.0,
		"extend": true, "reserve": 2, "doors": "dutiful", "confide": false,
		"evenings": {"family_worship": 3, "personal_study": 3, "game_night": 3, "visit_grandparent": 1, "rest": 1},
	},
	# A publisher doing what's expected, most of the time, choosing at random.
	"typical": {
		"pioneer": false, "attend": 0.9, "thursday": 0.3, "saturday": 0.9,
		"extend": false, "reserve": 3, "doors": "random", "confide": false,
		"evenings": {"family_worship": 2, "personal_study": 2, "game_night": 2, "visit_grandparent": 2, "coworker_invite": 1, "rest": 2},
	},
	# Takes the honest choice whenever it's offered; says yes to Dana.
	"curious": {
		"pioneer": false, "attend": 0.85, "thursday": 0.2, "saturday": 0.9,
		"extend": false, "reserve": 3, "doors": "honest", "confide": true,
		"evenings": {"visit_grandparent": 3, "coworker_invite": 3, "personal_study": 1, "family_worship": 1, "rest": 2},
	},
	# Going less and less.
	"drifting": {
		"pioneer": false, "attend": 0.45, "thursday": 0.0, "saturday": 0.35,
		"extend": false, "reserve": 4, "doors": "random", "confide": false,
		"evenings": {"coworker_invite": 3, "rest": 4, "visit_grandparent": 1},
	},
}

# Off-script gates per archetype, mirroring the .dtl conditions.
const OFFSCRIPT_GATES: Dictionary = {
	&"polite_refuser": [25, 3.0],
	&"curious_seeker": [25, 3.0],
	&"apostate_hostile": [30, 3.0],
	&"apostate_wounded": [35, 2.0],
	&"apostate_gentle": [40, 4.0],
}


func test_balance_targets() -> void:
	GameState.autosave_enabled = false
	seed(SEED)
	var results: Dictionary = {}
	for style in STYLES:
		var runs: Array = []
		for i in RUNS_PER_STYLE:
			runs.append(simulate_run(STYLES[style]))
		results[style] = runs
		_print_summary(style, runs)
	GameState.autosave_enabled = true

	check(_share(results["devout"], func(r: Dictionary) -> bool: return r["doubt"] < 40) >= 0.8,
		"devout: at least 80% of runs should end under 40 doubt")
	# The sim applies activity and beat base effects but not choice-level
	# [signal] extras, so it slightly understates doubt for engaged players.
	var typical_median: float = _median(results["typical"], "doubt")
	check(typical_median >= 18.0 and typical_median <= 40.0,
		"typical: median doubt at the end should land between 18 and 40 (got %.0f)" % typical_median)
	check(_percentile(results["typical"], "doubt", 0.9) >= 30,
		"typical: the top tenth of runs should see the cracks (30+ doubt)")
	check(_share(results["curious"], func(r: Dictionary) -> bool: return r["week_40"] <= 8) >= 0.7,
		"curious: at least 70% of runs should cross 40 doubt within the eight weeks")
	check(_percentile(results["curious"], "doubt", 0.5) < 95,
		"curious: the median run shouldn't spiral to the ceiling")
	check(_share(results["drifting"], func(r: Dictionary) -> bool: return r["ending"] in ["quiet_fade", "walking_away"]) >= 0.7,
		"drifting: most runs should end in the quiet fade or walking away")
	check(_share(results["devout"], func(r: Dictionary) -> bool: return r["pioneer_met"] >= 1) >= 0.6,
		"devout: most runs should meet the 30-hour pioneer target at least once")


# --- One run ------------------------------------------------------------------------

func simulate_run(style: Dictionary) -> Dictionary:
	GameState.new_game("Sim", "Brother", "mother")
	var week_25: int = 99
	var week_40: int = 99
	var exhausted: int = 0
	var pioneer_met: int = 0
	var guard: int = 0
	while guard < 200:
		guard += 1
		if GameState.pioneer_decision_pending():
			GameState.decide_pioneer(style["pioneer"])
		var beat: StoryBeat = Story.beat_for_today()
		if beat != null:
			Story.play(beat)
			Story.finish()
		_play_day(style)
		if ResourceManager.energy <= 0:
			exhausted += 1
		if DoubtMeter.value >= 25 and week_25 == 99:
			week_25 = TimeManager.current_week
		if DoubtMeter.value >= 40 and week_40 == 99:
			week_40 = TimeManager.current_week
		var next_scene: String = GameState.end_day()
		if next_scene == GameState.SCENE_MONTH_REPORT:
			_play_month_conversation(style)
			if GameState.month_verdict() == &"pioneer_met":
				pioneer_met += 1
			if GameState.close_month() == GameState.SCENE_ENDING:
				break
	return {
		"doubt": DoubtMeter.value,
		"conviction": ResourceManager.conviction,
		"week_25": week_25,
		"week_40": week_40,
		"ending": String(GameState.ending_id),
		"hours": GameState.months.map(func(m: Dictionary) -> float: return float(m.get("hours", 0.0))),
		"pioneer_met": pioneer_met,
		"exhausted": exhausted,
		"elders": ResourceManager.standing_elders,
		"congregation": ResourceManager.standing_congregation,
		"family": ResourceManager.standing_family,
	}


func _play_day(style: Dictionary) -> void:
	var phase: int = TimeManager.current_phase
	if MeetingManager.is_meeting_day(phase):
		_play_meeting(style, MeetingManager.meeting_type_for_phase(phase))
		return
	var wants_service: bool = (phase == TimeManager.Phase.SATURDAY and randf() < style["saturday"]) \
		or (phase == TimeManager.Phase.THURSDAY and randf() < style["thursday"])
	if wants_service and FieldService.start_session():
		_play_service(style)
		return
	_play_evening(style, phase)


func _play_meeting(style: Dictionary, meeting_type: StringName) -> void:
	if randf() >= style["attend"] or not MeetingManager.begin_meeting(meeting_type):
		MeetingManager.resolve_meeting_skipped(meeting_type)
		return
	if randf() < 0.5:
		ResourceManager.add_standing_congregation(1)
	for talk_type in MeetingManager.talks_for_meeting(meeting_type):
		var slug: StringName = MeetingManager.pick_speech_for(talk_type)
		if DoubtMeter.value >= 40:
			DoubtMeter.inner_voice()
		MeetingManager.resolve_talk_completed(talk_type, slug)
	MeetingManager.resolve_meeting_completed(meeting_type)


func _play_service(style: Dictionary) -> void:
	var houses: Array = TerritoryManager.current_territory.houses.duplicate()
	houses.shuffle()
	# Appointments first — they're the people expecting you.
	houses.sort_custom(func(a: House, b: House) -> bool:
		return TerritoryManager.is_appointment(a) and not TerritoryManager.is_appointment(b))
	for house in houses:
		while style["extend"] and FieldService.stops_left() < FieldService.stop_cost(house) \
				and ResourceManager.energy - FieldService.EXTENSION_ENERGY_COST >= style["reserve"] \
				and ResourceManager.field_service_hours < GameState.hours_target():
			FieldService.extend()
		if not FieldService.can_visit(house):
			continue
		if FieldService.knock(house):
			TerritoryManager.resolve_householder_for_pending_house()
			_play_door(style, house)
		else:
			FieldService.resolve_not_home(house)
	FieldService.end_session()


func _play_door(style: Dictionary, house: House) -> void:
	var archetype: StringName = house.householder.archetype
	if archetype == &"hostile_slammer":
		FieldService.resolve_outcome(house, "REFUSED")
		return
	if house.state == House.State.BIBLE_STUDY_STARTED:
		FieldService.resolve_outcome(house, "STUDY_CONTINUES" if randf() < 0.95 else "REFUSED")
		return
	var options: Array = _door_options(archetype)
	var gate: Array = OFFSCRIPT_GATES.get(archetype, [999, 0.0])
	var offscript_open: bool = DoubtMeter.value >= int(gate[0])
	var doors: String = style["doors"]
	if offscript_open and (doors == "honest" or (doors == "random" and randi() % (options.size() + 1) == 0)):
		FieldService.resolve_offscript(float(gate[1]))
		FieldService.resolve_outcome(house, "REFUSED" if randf() < 0.7 else "TRACT_LEFT")
		return
	if doors == "dutiful":
		FieldService.resolve_outcome(house, options[options.size() - 1])
		return
	FieldService.resolve_outcome(house, options[randi() % options.size()])


## On-script outcomes for an archetype, least to most fruitful.
func _door_options(archetype: StringName) -> Array:
	match archetype:
		&"polite_refuser":
			return ["REFUSED", "REFUSED", "TRACT_LEFT", "RETURN_VISIT_SCHEDULED"]
		&"curious_seeker":
			return ["TRACT_LEFT", "RETURN_VISIT_SCHEDULED", "BIBLE_STUDY_STARTED"]
		&"apostate_gentle":
			return ["REFUSED", "TRACT_LEFT", "RETURN_VISIT_SCHEDULED"]
	return ["REFUSED", "TRACT_LEFT"]


func _play_evening(style: Dictionary, phase: int) -> void:
	var weights: Dictionary = style["evenings"]
	var pool: Array = []
	# A pioneer behind pace rests the night before a service day.
	var before_service: bool = phase == TimeManager.Phase.WEDNESDAY or phase == TimeManager.Phase.FRIDAY
	var pace: float = GameState.hours_target() * TimeManager.week_in_month() / TimeManager.WEEKS_PER_MONTH
	if style["pioneer"] and before_service and ResourceManager.field_service_hours < pace:
		weights = {"rest": 1}
	for activity in Evenings.available_for(phase):
		if not Evenings.can_afford(activity):
			continue
		# Tired players rest.
		if ResourceManager.energy <= style["reserve"] and activity.id != &"rest":
			continue
		for i in int(weights.get(String(activity.id), 0)):
			pool.append(activity)
	if pool.is_empty():
		var rest: Activity = Evenings.get_activity(&"rest")
		if rest != null and rest.days.has(phase):
			Evenings.choose(rest)
			Evenings.finish()
		return
	Evenings.choose(pool[randi() % pool.size()])
	Evenings.finish()


func _play_month_conversation(style: Dictionary) -> void:
	match GameState.month_verdict():
		&"pioneer_met":
			Evenings.apply_scene_signal("CONVICTION:2")
		&"pioneer_missed":
			Evenings.apply_scene_signal("STANDING:elders:1")
		&"shepherding":
			if style["confide"] and DoubtMeter.value >= 25:
				Evenings.apply_scene_signal("RELIEF:3")
			else:
				Evenings.apply_scene_signal("STANDING:elders:2")
		&"steady":
			Evenings.apply_scene_signal("STANDING:elders:1")


# --- Reporting ------------------------------------------------------------------------

func _print_summary(style: String, runs: Array) -> void:
	var endings: Dictionary = {}
	for run in runs:
		endings[run["ending"]] = int(endings.get(run["ending"], 0)) + 1
	var month_hours: Array = [0.0, 0.0]
	for run in runs:
		for i in mini(run["hours"].size(), 2):
			month_hours[i] += run["hours"][i] / runs.size()
	print("  [balance] %-8s doubt median %4.1f  p90 %3d | conviction %4.1f | cross25 wk %s  cross40 wk %s | hrs/mo %.1f, %.1f | pioneer met %.0f%% | exhausted nights %.1f" % [
		style, _median(runs, "doubt"), _percentile(runs, "doubt", 0.9), _mean(runs, "conviction"),
		_week_label(_median(runs, "week_25")), _week_label(_median(runs, "week_40")),
		month_hours[0], month_hours[1],
		100.0 * _share(runs, func(r: Dictionary) -> bool: return r["pioneer_met"] >= 1),
		_mean(runs, "exhausted")])
	print("  [balance] %-8s standings e/c/f %4.1f %4.1f %4.1f | endings %s" % [
		style, _mean(runs, "elders"), _mean(runs, "congregation"), _mean(runs, "family"), str(endings)])


func _week_label(week: float) -> String:
	return "never" if week >= 99 else "%.0f" % week


func _median(runs: Array, key: String) -> float:
	var values: Array = runs.map(func(r: Dictionary) -> float: return float(r[key]))
	values.sort()
	return values[values.size() / 2]


func _percentile(runs: Array, key: String, p: float) -> int:
	var values: Array = runs.map(func(r: Dictionary) -> int: return int(r[key]))
	values.sort()
	return values[mini(int(p * values.size()), values.size() - 1)]


func _mean(runs: Array, key: String) -> float:
	var total: float = 0.0
	for run in runs:
		total += float(run[key])
	return total / runs.size()


func _share(runs: Array, predicate: Callable) -> float:
	var count: int = 0
	for run in runs:
		if predicate.call(run):
			count += 1
	return float(count) / runs.size()
