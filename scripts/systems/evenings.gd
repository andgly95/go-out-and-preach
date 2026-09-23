extends Node
## Offers each day's activities and runs them. Autoloaded as Evenings.
## Activities are data (data/activities/*.tres). Choosing one spends its
## energy, applies its effects, and queues the next scene in its sequence for
## scenes/evening.tscn to play. Scenes nudge state through [signal] events —
## see apply_scene_signal().

const ACTIVITY_DIR: String = "res://data/activities"
const DEFAULT_BACKGROUND: String = "res://assets/sprites/week_view/desk_background.png"

var pending: Activity = null
var pending_timeline: String = ""
var _activities: Array[Activity] = []


func _ready() -> void:
	_load_activities()


func _load_activities() -> void:
	_activities.clear()
	var files: PackedStringArray = DirAccess.get_files_at(ACTIVITY_DIR)
	files.sort()
	for file in files:
		# Exported builds list converted resources with a .remap suffix.
		var name: String = file.trim_suffix(".remap")
		if name.get_extension() != "tres":
			continue
		var activity: Activity = load(ACTIVITY_DIR.path_join(name)) as Activity
		if activity != null:
			_activities.append(activity)
	_activities.sort_custom(func(a: Activity, b: Activity) -> bool: return a.order < b.order)


func all_activities() -> Array[Activity]:
	return _activities


func get_activity(id: StringName) -> Activity:
	for activity in _activities:
		if activity.id == id:
			return activity
	return null


func available_for(phase: int) -> Array[Activity]:
	var result: Array[Activity] = []
	for activity in _activities:
		if not activity.days.has(phase):
			continue
		if ResourceManager.standing_congregation < activity.min_congregation:
			continue
		if not activity.hide_if_flag.is_empty() and GameState.flag(activity.hide_if_flag):
			continue
		if not activity.requires_flag.is_empty() and not GameState.flag(activity.requires_flag):
			continue
		result.append(activity)
	return result


## Energy the activity costs after habits; negative restores (rest).
func energy_cost(activity: Activity) -> int:
	return Habits.energy_cost(activity.id, activity.energy_cost)


func can_afford(activity: Activity) -> bool:
	var cost: int = energy_cost(activity)
	return cost <= 0 or ResourceManager.can_afford(cost)


## Commits to the activity: energy and effects land now; the scene to play
## (if any) is left in pending_timeline for the evening scene.
func choose(activity: Activity) -> void:
	var cost: int = energy_cost(activity)
	if cost > 0:
		ResourceManager.spend_energy(cost)
	elif cost < 0:
		ResourceManager.add_energy(-cost)
	var key: String = String(activity.id)
	ResourceManager.add_conviction(activity.conviction + int(Habits.modifier("conviction:" + key)))
	ResourceManager.add_standing_elders(activity.standing_elders)
	ResourceManager.add_standing_congregation(activity.standing_congregation)
	ResourceManager.add_standing_family(activity.standing_family)
	DoubtMeter.apply(-(activity.doubt_relief + int(Habits.modifier("relief:" + key))), StringName("relief_" + key))
	DoubtMeter.expose(activity.exposure, StringName("activity_" + String(activity.id)))
	if not activity.sets_flag.is_empty():
		GameState.set_flag(activity.sets_flag, 1)
	var times: int = GameState.bump("activity_" + String(activity.id))
	pending = activity
	pending_timeline = activity.repeat_scene
	if times <= activity.scenes.size():
		pending_timeline = activity.scenes[times - 1]


func background_for(activity: Activity) -> String:
	if activity == null or activity.background.is_empty():
		return DEFAULT_BACKGROUND
	return activity.background


## Handles a [signal] from a scene timeline. Returns true if understood.
##   INNER_VOICE              an inner-voice line played
##   EXPOSE:<n>               conviction-scaled doubt
##   RELIEF:<n>               unscaled doubt removed
##   CONVICTION:<n>           conviction change
##   STANDING:<track>:<n>     elders / congregation / family
##   ENERGY:<n>               energy change
##   FLAG:<key>[=<value>]     set a GameState flag (int values)
##   BUMP:<key>               add 1 to a GameState counter
func apply_scene_signal(arg: String) -> bool:
	var parts: PackedStringArray = arg.split(":")
	var source: String = "event"
	if pending != null:
		source = String(pending.id)
	elif Story.pending != null:
		source = String(Story.pending.id)
	var reason: StringName = StringName("scene_" + source)
	match parts[0]:
		"INNER_VOICE":
			DoubtMeter.inner_voice()
		"EXPOSE":
			DoubtMeter.expose(float(parts[1]), reason)
		"RELIEF":
			DoubtMeter.apply(-int(parts[1]), reason)
		"CONVICTION":
			ResourceManager.add_conviction(int(parts[1]))
		"STANDING":
			ResourceManager.add_standing(StringName(parts[1]), int(parts[2]))
		"ENERGY":
			ResourceManager.add_energy(int(parts[1]))
		"FLAG":
			var key: String = parts[1].get_slice("=", 0)
			var value: Variant = int(parts[1].get_slice("=", 1)) if parts[1].contains("=") else 1
			GameState.set_flag(key, value)
		"BUMP":
			GameState.bump(parts[1])
		_:
			return false
	return true


func finish() -> void:
	if pending != null:
		SignalBus.evening_completed.emit(pending.id)
	pending = null
	pending_timeline = ""
