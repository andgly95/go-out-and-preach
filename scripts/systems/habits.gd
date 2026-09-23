extends Node
## The habits tree (docs/design/v01-loop.md § Habits). Autoloaded as Habits.
##
## A skill tree whose points are the days you spend: each track fills with
## practice (a morning in service, an evening of study, a meeting), so
## choosing tonight's activity is spending the point. Step 1 of a track
## forms by itself; step 2 is a fork the player chooses once, between what
## gets counted and who is in front of you. The "lately" track takes no
## practice and offers no choice: its habits form from doubt, and it stays
## out of sight until doubt first reaches 40 (GDD § 5.2's faint indicator).
##
## Systems read effects through modifier(key); see Habit.modifiers.

const HABIT_DIR: String = "res://data/habits"
const LATELY_TRACK: StringName = &"lately"

# Tracks in display order: what feeds each, and what one point of practice
# is called ("in 2 more mornings"). {tokens} via GameState.fill.
const TRACKS: Array = [
	{"id": &"ministry", "title": "Ministry", "grows": "Grows with each morning in service.", "unit": ["morning", "mornings"]},
	{"id": &"study", "title": "Study", "grows": "Grows with personal study and family worship.", "unit": ["evening", "evenings"]},
	{"id": &"congregation", "title": "Congregation", "grows": "Grows with each meeting and game night.", "unit": ["meeting", "meetings"]},
	{"id": &"home", "title": "Home", "grows": "Grows with family worship and visits to {grandparent}.", "unit": ["evening", "evenings"]},
]
const LATELY_TITLE: String = "Lately"
const LATELY_NOTE: String = "These form on their own."

# Evening activities that count as practice, and on which tracks.
const PRACTICE_FROM_ACTIVITY: Dictionary = {
	&"personal_study": [&"study"],
	&"family_worship": [&"study", &"home"],
	&"visit_grandparent": [&"home"],
	&"game_night": [&"congregation"],
}

## Practice per track (StringName → int).
var practice: Dictionary = {}
var formed: Array[StringName] = []
## The fork options not chosen. Closed for the rest of the run.
var closed: Array[StringName] = []
## Habits that formed by themselves and haven't been shown yet.
var unseen: Array[StringName] = []
## Tracks whose fork is open and waiting for the player to choose.
var choices_pending: Array[StringName] = []

var _habits: Array[Habit] = []


func _ready() -> void:
	_load_habits()
	SignalBus.service_session_ended.connect(_on_service_session_ended)
	SignalBus.meeting_attended.connect(_on_meeting_attended)
	SignalBus.evening_completed.connect(_on_evening_completed)
	SignalBus.day_advanced.connect(_on_day_advanced)


func _load_habits() -> void:
	_habits.clear()
	var files: PackedStringArray = DirAccess.get_files_at(HABIT_DIR)
	files.sort()
	for file in files:
		# Exported builds list converted resources with a .remap suffix.
		var name: String = file.trim_suffix(".remap")
		if name.get_extension() != "tres":
			continue
		var habit: Habit = load(HABIT_DIR.path_join(name)) as Habit
		if habit != null:
			_habits.append(habit)
	_habits.sort_custom(func(a: Habit, b: Habit) -> bool:
		return a.step < b.step if a.step != b.step else a.order < b.order)


func reset() -> void:
	practice = {}
	formed.clear()
	closed.clear()
	unseen.clear()
	choices_pending.clear()


# --- Queries ---------------------------------------------------------------------

func all_habits() -> Array[Habit]:
	return _habits


func get_habit(id: StringName) -> Habit:
	for habit in _habits:
		if habit.id == id:
			return habit
	return null


## A track's habits in order; step 0 means every step.
func habits_on(track: StringName, step: int = 0) -> Array[Habit]:
	var result: Array[Habit] = []
	for habit in _habits:
		if habit.track == track and (step == 0 or habit.step == step):
			result.append(habit)
	return result


func has(id: StringName) -> bool:
	return formed.has(id)


func is_closed(id: StringName) -> bool:
	return closed.has(id)


func practice_on(track: StringName) -> int:
	return int(practice.get(track, 0))


## Sum of a named effect across formed habits (0 if none).
func modifier(key: String) -> float:
	var total: float = 0.0
	for id in formed:
		var habit: Habit = get_habit(id)
		if habit != null and habit.modifiers.has(key):
			total += float(habit.modifiers[key])
	return total


## An energy cost after habits ("energy:<id>"). Restoring (≤ 0) is untouched,
## and no habit makes a cost negative.
func energy_cost(id: StringName, base: int) -> int:
	if base <= 0:
		return base
	return maxi(0, base + int(modifier("energy:" + String(id))))


## What the track needs next, for the tree view: {"kind": "habit" | "choice"
## | "done", "needed": practice still to go}.
func next_step(track: StringName) -> Dictionary:
	var have: int = practice_on(track)
	for habit in habits_on(track, 1):
		if not has(habit.id):
			return {"kind": "habit", "needed": maxi(habit.practice - have, 0)}
	var fork: Array[Habit] = habits_on(track, 2)
	if fork.is_empty() or _fork_settled(fork):
		return {"kind": "done", "needed": 0}
	return {"kind": "choice", "needed": maxi(fork[0].practice - have, 0)}


## The practice the track is counting toward now (the fork's, once done).
func milestone(track: StringName) -> int:
	for habit in habits_on(track, 1):
		if not has(habit.id):
			return habit.practice
	var fork: Array[Habit] = habits_on(track, 2)
	return fork[0].practice if not fork.is_empty() else practice_on(track)


func track_info(track: StringName) -> Dictionary:
	for info in TRACKS:
		if info["id"] == track:
			return info
	return {}


## "The car group in 1 more morning", "A choice in 3 more meetings",
## "A choice is waiting.", or "" once the track is settled.
func next_step_text(track: StringName) -> String:
	if choices_pending.has(track):
		return tr("A choice is waiting.")
	var step: Dictionary = next_step(track)
	var needed: int = int(step["needed"])
	var unit: Array = track_info(track).get("unit", ["time", "times"])
	var units: String = tr(unit[0] if needed == 1 else unit[1])
	match step["kind"]:
		"habit":
			for habit in habits_on(track, 1):
				if not has(habit.id):
					return tr("%s in %d more %s") % [GameState.fill(tr(habit.title)), needed, units]
		"choice":
			return tr("A choice in %d more %s") % [needed, units]
	return ""


## The lately track shows once doubt has reached its first habit, and stays.
func lately_visible() -> bool:
	for habit in habits_on(LATELY_TRACK):
		if has(habit.id):
			return true
	return false


# --- Changes ---------------------------------------------------------------------

func add_practice(track: StringName, amount: int = 1) -> void:
	practice[track] = practice_on(track) + amount
	_check_track(track)


## Keeps one side of a fork; the other closes.
func choose(id: StringName) -> void:
	var habit: Habit = get_habit(id)
	if habit == null or habit.step != 2 or not choices_pending.has(habit.track):
		return
	for other in habits_on(habit.track, 2):
		if other.id != id:
			closed.append(other.id)
	choices_pending.erase(habit.track)
	_form(habit, false)


## The next habit that formed by itself and hasn't been shown, or null.
func take_unseen() -> Habit:
	while not unseen.is_empty():
		var habit: Habit = get_habit(unseen.pop_front())
		if habit != null:
			return habit
	return null


func _check_track(track: StringName) -> void:
	var have: int = practice_on(track)
	for habit in habits_on(track, 1):
		if not has(habit.id) and have >= habit.practice:
			_form(habit)
	var fork: Array[Habit] = habits_on(track, 2)
	if fork.is_empty() or choices_pending.has(track) or _fork_settled(fork):
		return
	if have >= fork[0].practice:
		choices_pending.append(track)
		SignalBus.habit_choice_offered.emit(track)


func _check_lately() -> void:
	for habit in habits_on(LATELY_TRACK):
		if not has(habit.id) and DoubtMeter.value >= habit.min_doubt:
			_form(habit)


func _fork_settled(fork: Array[Habit]) -> bool:
	for habit in fork:
		if has(habit.id) or is_closed(habit.id):
			return true
	return false


func _form(habit: Habit, notify: bool = true) -> void:
	formed.append(habit.id)
	if notify:
		unseen.append(habit.id)
	SignalBus.habit_formed.emit(habit.id)


func _on_service_session_ended(summary: Dictionary) -> void:
	if float(summary.get("hours", 0.0)) > 0.0:
		add_practice(&"ministry")


func _on_meeting_attended(_meeting_type: StringName) -> void:
	add_practice(&"congregation")


func _on_evening_completed(activity_id: StringName) -> void:
	for track in PRACTICE_FROM_ACTIVITY.get(activity_id, []):
		add_practice(track)


func _on_day_advanced(_day: int) -> void:
	# Once a day, so what doubt has done shows up the next morning.
	_check_lately()


# --- Save ----------------------------------------------------------------------------

func to_save() -> Dictionary:
	return {
		"practice": practice.duplicate(),
		"formed": _copy(formed),
		"closed": _copy(closed),
		"unseen": _copy(unseen),
		"choices_pending": _copy(choices_pending),
	}


# A plain copy, so a saved snapshot never aliases the live lists.
static func _copy(ids: Array[StringName]) -> Array:
	var out: Array = []
	out.append_array(ids)
	return out


func from_save(data: Dictionary) -> void:
	reset()
	var saved_practice: Dictionary = data.get("practice", {})
	for track in saved_practice:
		practice[StringName(track)] = int(saved_practice[track])
	for id in data.get("formed", []):
		formed.append(StringName(id))
	for id in data.get("closed", []):
		closed.append(StringName(id))
	for id in data.get("unseen", []):
		unseen.append(StringName(id))
	for track in data.get("choices_pending", []):
		choices_pending.append(StringName(track))
