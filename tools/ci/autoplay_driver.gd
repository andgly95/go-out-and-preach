extends RefCounted
## Driver for tools/ci/autoplay.gd (loaded at runtime so autoload names
## resolve). Plays a whole run through the real scenes, headless: presses the day
## screen's option buttons, knocks doors on the map, clicks through Dialogic
## (random enabled choice at each question), and follows every scene change
## until the ending. Fails (exit 1) if the run gets stuck or never ends.
## Script errors surface as engine ERROR lines, which tools/check.sh catches.
##
##   bash tools/godot.sh --headless --script res://tools/ci/autoplay.gd -- --seed=3
##
## Prints one line per scene visited and a summary.

const MAX_FRAMES: int = 60000
const STUCK_FRAMES: int = 900
const TIME_SCALE: float = 12.0

var _rng_seed: int = 1
var _verbose: bool = false
var _last_scene: String = ""
var _frames_in_state: int = 0
var _last_signature: String = ""
var _visits: Dictionary = {}
var _stop_week: int = 99
var _stop_after: int = 100000
var _start_day: int = 0
var _scene_changes: int = 0
var tree: SceneTree = null


func run(scene_tree: SceneTree) -> void:
	tree = scene_tree
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--seed="):
			_rng_seed = int(arg.trim_prefix("--seed="))
		elif arg == "--verbose":
			_verbose = true
		elif arg.begins_with("--start-day="):
			_start_day = int(arg.trim_prefix("--start-day="))
		elif arg.begins_with("--stop-after="):
			_stop_after = int(arg.trim_prefix("--stop-after="))
		elif arg.begins_with("--stop-week="):
			_stop_week = int(arg.trim_prefix("--stop-week="))
	seed(_rng_seed)
	Engine.time_scale = TIME_SCALE
	GameState.autosave_enabled = false
	GameState.new_game("Auto", "Sister" if _rng_seed % 2 == 0 else "Brother", "mother" if _rng_seed % 3 else "father")
	for i in _start_day:
		TimeManager.advance_phase()
	tree.change_scene_to_file("res://scenes/week_view.tscn")
	for frame in MAX_FRAMES:
		await tree.process_frame
		var scene: Node = tree.current_scene
		if scene == null:
			continue
		var name: String = scene.scene_file_path.get_file().get_basename()
		if name != _last_scene:
			_last_scene = name
			_visits[name] = int(_visits.get(name, 0)) + 1
			_scene_changes += 1
			if _scene_changes > _stop_after:
				await _finish(true, "stopped after %d scenes (in %s)" % [_stop_after, name])
				return
			if _verbose:
				print("  [autoplay] week %d %s → %s" % [TimeManager.current_week, TimeManager.current_phase_name(), name])
		if TimeManager.current_week >= _stop_week and name == "week_view":
			await _finish(true, "stopped at week %d" % _stop_week)
			return
		if name == "ending" and _ending_done(scene):
			await _finish(true, "reached the ending: %s" % GameState.ending_id)
			return
		if frame % 3 != 0:
			continue
		var signature: String = "%s|%d|%d|%d|%s" % [name, TimeManager.current_week, TimeManager.current_phase, Dialogic.current_event_idx, str(Dialogic.current_timeline)]
		if signature == _last_signature:
			_frames_in_state += 3
			if _frames_in_state > STUCK_FRAMES:
				await _finish(false, "stuck in %s (week %d %s, Dialogic state %d)" % [name, TimeManager.current_week, TimeManager.current_phase_name(), Dialogic.current_state])
				return
		else:
			_last_signature = signature
			_frames_in_state = 0
		_step(scene, name)
	await _finish(false, "ran out of frames")


func _step(scene: Node, name: String) -> void:
	if Dialogic.current_timeline != null:
		_step_dialogic()
		return
	match name:
		"territory_map":
			_step_territory(scene)
		"door_knock":
			pass  # slammer scene or between timelines; wait
		_:
			_press_random_button(scene)


func _step_dialogic() -> void:
	match Dialogic.current_state:
		Dialogic.States.AWAITING_CHOICE:
			var info: Dictionary = Dialogic.Choices.get_current_question_info()
			var enabled: Array = info["choices"].filter(func(c: Dictionary) -> bool: return not c["disabled"])
			if enabled.is_empty():
				return
			var pick: Dictionary = enabled[randi() % enabled.size()]
			if _verbose:
				print("  [autoplay]     choice: %s" % pick["text"])
			Dialogic.Choices._on_choice_selected(pick)
		Dialogic.States.IDLE, Dialogic.States.REVEALING_TEXT:
			Dialogic.Inputs.handle_input()


func _step_territory(scene: Node) -> void:
	if scene.get("_beat_active"):
		return
	var report: Control = scene.get_node_or_null("AfterServiceCard")
	if report != null and report.visible:
		_press(scene.get_node("AfterServiceCard/Margin/VBox/SubmitButton"))
		return
	# Sometimes keep going an extra hour, as a pioneer would.
	if FieldService.stops_left() <= 1 and randf() < 0.3 and FieldService.can_extend():
		FieldService.extend()
		scene.call("_refresh_session_panel")
		return
	var candidates: Array = TerritoryManager.current_territory.houses.filter(func(h: House) -> bool: return FieldService.can_visit(h))
	if candidates.is_empty() or randf() < 0.05:
		scene.call("_on_end_pressed")
		return
	var house: House = candidates[randi() % candidates.size()]
	scene.call("_commit_visit", house.id)


func _press_random_button(scene: Node) -> void:
	var buttons: Array = []
	_collect_buttons(scene, buttons)
	if buttons.is_empty():
		return
	_press(buttons[randi() % buttons.size()])


func _collect_buttons(node: Node, into: Array) -> void:
	if node is Button:
		var button: Button = node
		var label: String = button.text.to_upper()
		if button.is_visible_in_tree() and not button.disabled and not label.contains("BACK") and not label.contains("WALK AWAY"):
			into.append(button)
	for child in node.get_children():
		_collect_buttons(child, into)


func _press(button: Button) -> void:
	if _verbose and not button.text.is_empty():
		print("  [autoplay]     press: %s" % button.text)
	button.pressed.emit()


func _ending_done(scene: Node) -> bool:
	var card: Control = scene.get_node_or_null("Card")
	return card != null and card.visible


func _finish(ok: bool, message: String) -> void:
	Engine.time_scale = 1.0
	print("[autoplay] seed %d: %s — week %d, doubt %d, conviction %d, visits %s" % [
		_rng_seed, message, TimeManager.current_week, DoubtMeter.value, ResourceManager.conviction, str(_visits)])
	# Tear down before quitting: exiting with a live timeline and scene
	# crashes the engine during shutdown.
	if Dialogic.current_timeline != null:
		Dialogic.end_timeline(true)
	if tree.current_scene != null:
		tree.current_scene.queue_free()
	for i in 3:
		await tree.process_frame
	tree.quit(0 if ok else 1)
