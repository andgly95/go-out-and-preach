extends RefCounted
## Screenshot setup: opens one story beat or evening activity by id, so new
## background art can be checked in place. Pick it with an environment variable:
##   BEAT=parent_coffee bash tools/screenshot.sh res://scenes/evening.tscn out.png res://tools/ci/shots/scene.gd
##   ACTIVITY=visit_grandparent bash tools/screenshot.sh res://scenes/evening.tscn out.png res://tools/ci/shots/scene.gd


func setup(_tree: SceneTree) -> void:
	GameState.autosave_enabled = false
	GameState.new_game("Jordan", "Sister", "mother")
	var beat_id: String = OS.get_environment("BEAT")
	var activity_id: String = OS.get_environment("ACTIVITY")
	if not beat_id.is_empty():
		for beat in Story.all_beats():
			if String(beat.id) == beat_id:
				while TimeManager.current_week < beat.week or TimeManager.current_phase != beat.day:
					TimeManager.advance_phase()
				GameState.set_flag("dana_asked", 1)
				Story.play(beat)
				return
		push_error("No beat with id %s" % beat_id)
	elif not activity_id.is_empty():
		var activity: Activity = Evenings.get_activity(StringName(activity_id))
		if activity == null:
			push_error("No activity with id %s" % activity_id)
			return
		Evenings.choose(activity)
	else:
		push_error("Set BEAT=<id> or ACTIVITY=<id>")


func after_load(tree: SceneTree) -> void:
	# Advance past the first line so the textbox shows real dialogue.
	for f in 40:
		await tree.process_frame
	Dialogic.Inputs.handle_input()
