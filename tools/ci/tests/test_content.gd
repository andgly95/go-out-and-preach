extends "res://tools/ci/test_case.gd"
## Content integrity: every script, resource, and dialogue file loads, and
## every householder conversation branch resolves to a known outcome.

const OUTCOME_SIGNALS: Array[String] = [
	"REFUSED", "TRACT_LEFT", "RETURN_VISIT_SCHEDULED", "BIBLE_STUDY_STARTED", "STUDY_CONTINUES",
]


static func files_under(root: String, extension: String) -> Array[String]:
	var found: Array[String] = []
	for file in DirAccess.get_files_at(root):
		if file.get_extension() == extension:
			found.append(root.path_join(file))
	for dir in DirAccess.get_directories_at(root):
		found.append_array(files_under(root.path_join(dir), extension))
	return found


func test_all_scripts_compile() -> void:
	for path in files_under("res://scripts", "gd"):
		var script: GDScript = load(path)
		check(script != null and script.can_instantiate(), "script failed to compile: %s" % path)


func test_all_data_resources_load() -> void:
	for path in files_under("res://data", "tres"):
		check(load(path) != null, "resource failed to load: %s" % path)


func test_all_timelines_parse() -> void:
	for path in files_under("res://data/dialogues", "dtl"):
		var timeline: Resource = load(path)
		check(timeline != null, "timeline failed to load: %s" % path)
		if timeline == null:
			continue
		timeline.process()
		check(timeline.events.size() > 0, "timeline has no events: %s" % path)


func test_householder_branches_end_with_outcome() -> void:
	# Every [end_timeline] in a door conversation must be directly preceded by
	# an outcome signal, or door_knock falls back to REFUSED with a warning.
	var door_timelines: Array[String] = []
	for file in DirAccess.get_files_at("res://data/dialogues"):
		if file.get_extension() == "dtl":
			door_timelines.append("res://data/dialogues".path_join(file))
	door_timelines.append_array(files_under("res://data/dialogues/study", "dtl"))
	for path in door_timelines:
		var lines: PackedStringArray = FileAccess.get_file_as_string(path).split("\n")
		var previous: String = ""
		for i in lines.size():
			var line: String = lines[i].strip_edges()
			if line.is_empty() or line.begins_with("#"):
				continue
			if line == "[end_timeline]":
				var ok: bool = false
				for outcome in OUTCOME_SIGNALS:
					if previous == '[signal arg="%s"]' % outcome:
						ok = true
				check(ok, "%s:%d [end_timeline] without an outcome signal before it" % [path, i + 1])
			previous = line


func test_householder_timelines_exist() -> void:
	for slug in TerritoryManager.HOUSEHOLDER_PATHS:
		var householder: Householder = load(TerritoryManager.HOUSEHOLDER_PATHS[slug])
		check(householder != null, "householder missing: %s" % slug)
		if householder == null or householder.archetype == &"hostile_slammer":
			continue
		check(ResourceLoader.exists(householder.dialogue_timeline),
			"%s points at missing timeline %s" % [slug, householder.dialogue_timeline])


func test_no_accidental_speakers() -> void:
	# Dialogic reads "Word: text" at the start of a line as a speaker named
	# Word. Only characters with a .dch file are allowed there. Anything else
	# is prose that grew a colon — or an ad-hoc speaker such as
	# "{GameState.x}: text", which Dialogic creates at runtime and which
	# crashes Godot on exit. Give recurring speakers a .dch instead.
	var known: Array = []
	for path in files_under("res://data/dialogues/characters", "dch"):
		known.append(path.get_file().get_basename())
	var speaker := RegEx.create_from_string("^\\s*([^\\s:(\"\\[-][^\\s:(]*)\\s*(\\([^)]*\\))?\\s*:")
	for path in files_under("res://data/dialogues", "dtl"):
		var lines: PackedStringArray = FileAccess.get_file_as_string(path).split("\n")
		for i in lines.size():
			var line: String = lines[i]
			if line.strip_edges().begins_with("#") or line.strip_edges().begins_with("["):
				continue
			var m: RegExMatch = speaker.search(line)
			if m == null:
				continue
			var name: String = m.get_string(1)
			if name in ["if", "elif", "else", "label", "jump", "join", "leave", "update"]:
				continue
			check(name in known, "%s:%d reads as a speaker named '%s'" % [path, i + 1, name])


func test_lines_fit_the_textbox() -> void:
	# The Dialogic textbox shows about four lines (~215 characters) before it
	# has to scroll. Split longer lines at a natural beat.
	for dir in ["beats", "scenes", "study", "month", "endings"]:
		for path in files_under("res://data/dialogues/" + dir, "dtl"):
			var lines: PackedStringArray = FileAccess.get_file_as_string(path).split("\n")
			for i in lines.size():
				var line: String = lines[i].strip_edges()
				if line.begins_with("#"):
					continue
				check(line.length() <= 215, "%s:%d is %d characters; split it" % [path, i + 1, line.length()])
