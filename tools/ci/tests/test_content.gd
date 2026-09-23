extends "res://tools/ci/test_case.gd"
## Content integrity: every script, resource, and dialogue file loads, and
## every householder conversation branch resolves to a known outcome.

const OUTCOME_SIGNALS: Array[String] = [
	"REFUSED", "TRACT_LEFT", "RETURN_VISIT_SCHEDULED", "BIBLE_STUDY_STARTED",
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
	for path in files_under("res://data/dialogues", "dtl"):
		if path.contains("/meetings/") or path.contains("/internals/") or path.contains("/scenes/"):
			continue
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
