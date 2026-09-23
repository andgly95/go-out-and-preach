extends Node
## Saves and restores a run. Autoloaded as SaveLoad. Autosave happens at the
## start of each day (GameState listens for day_advanced); Continue on the
## main menu resumes it. Manual slots are GDD § 10 scope for later.

const AUTOSAVE_PATH: String = "user://autosave.tres"


func has_autosave() -> bool:
	return FileAccess.file_exists(AUTOSAVE_PATH)


func autosave() -> void:
	var save: SaveGame = SaveGame.new()
	save.saved_at = Time.get_datetime_string_from_system()
	save.label = "Week %d — %s" % [TimeManager.current_week, TimeManager.current_phase_name()]
	save.data = snapshot()
	var err: Error = ResourceSaver.save(save, AUTOSAVE_PATH)
	if err != OK:
		push_warning("[SaveLoad] Autosave failed: %s" % error_string(err))


func load_autosave() -> bool:
	if not has_autosave():
		return false
	var save: SaveGame = ResourceLoader.load(AUTOSAVE_PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as SaveGame
	if save == null:
		push_warning("[SaveLoad] Autosave at %s could not be read." % AUTOSAVE_PATH)
		return false
	restore(save.data)
	return true


func clear_autosave() -> void:
	if has_autosave():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(AUTOSAVE_PATH))


func autosave_label() -> String:
	if not has_autosave():
		return ""
	var save: SaveGame = ResourceLoader.load(AUTOSAVE_PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as SaveGame
	return save.label if save != null else ""


## Every system's state as plain data.
func snapshot() -> Dictionary:
	return {
		"game": GameState.to_save(),
		"time": TimeManager.to_save(),
		"resources": ResourceManager.to_save(),
		"doubt": DoubtMeter.to_save(),
		"territory": TerritoryManager.to_save(),
		"meetings": MeetingManager.to_save(),
		"habits": Habits.to_save(),
	}


func restore(data: Dictionary) -> void:
	GameState.new_game()
	TimeManager.from_save(data.get("time", {}))
	ResourceManager.from_save(data.get("resources", {}))
	DoubtMeter.from_save(data.get("doubt", {}))
	TerritoryManager.from_save(data.get("territory", {}))
	MeetingManager.from_save(data.get("meetings", {}))
	Habits.from_save(data.get("habits", {}))
	GameState.from_save(data.get("game", {}))
