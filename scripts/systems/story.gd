extends Node
## Schedules the run's story beats (data/beats/*.tres). Autoloaded as Story.
## The day screen asks for today's beat; if there is one it plays in the
## scene runner (scenes/evening.tscn) and returns to the day screen, the day
## still ahead of the player.

const BEAT_DIR: String = "res://data/beats"

var pending: StoryBeat = null
var _beats: Array[StoryBeat] = []


func _ready() -> void:
	_beats.clear()
	for file in DirAccess.get_files_at(BEAT_DIR):
		var name: String = file.trim_suffix(".remap")
		if name.get_extension() != "tres":
			continue
		var beat: StoryBeat = load(BEAT_DIR.path_join(name)) as StoryBeat
		if beat != null:
			_beats.append(beat)


func all_beats() -> Array[StoryBeat]:
	return _beats


func beat_for_today() -> StoryBeat:
	for beat in _beats:
		if beat.week == TimeManager.current_week and beat.day == TimeManager.current_phase and is_eligible(beat):
			return beat
	return null


func is_eligible(beat: StoryBeat) -> bool:
	if GameState.flag(played_flag(beat)):
		return false
	if not beat.requires_flag.is_empty() and not GameState.flag(beat.requires_flag):
		return false
	if not beat.hide_if_flag.is_empty() and GameState.flag(beat.hide_if_flag):
		return false
	if DoubtMeter.value < beat.min_doubt or DoubtMeter.value > beat.max_doubt:
		return false
	if int(GameState.month.get("meetings_skipped", 0)) < beat.min_meetings_skipped:
		return false
	if not beat.requires_count.is_empty() and int(GameState.flag(beat.requires_count)) < 1:
		return false
	return true


func played_flag(beat: StoryBeat) -> String:
	return "beat_" + String(beat.id)


## Marks the beat played and applies its base effects. The timeline (if any)
## is left for the scene runner.
func play(beat: StoryBeat) -> void:
	GameState.set_flag(played_flag(beat), 1)
	ResourceManager.add_conviction(beat.conviction)
	ResourceManager.add_standing_elders(beat.standing_elders)
	ResourceManager.add_standing_congregation(beat.standing_congregation)
	ResourceManager.add_standing_family(beat.standing_family)
	DoubtMeter.apply(-beat.doubt_relief, StringName("relief_" + String(beat.id)))
	DoubtMeter.expose(beat.exposure, StringName("beat_" + String(beat.id)))
	if not beat.sets_flag.is_empty():
		GameState.set_flag(beat.sets_flag, 1)
	pending = beat


func finish() -> void:
	pending = null
