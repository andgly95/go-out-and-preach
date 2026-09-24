extends Control
## Porch view. Plays the conversation at the house FieldService just knocked:
## the householder's timeline (its returning branch on a return visit), a
## study session for an ongoing Bible study, or a short inline scene for the
## Hostile Slammer. Timelines report through Dialogic [signal] events and
## FieldService applies the consequences. Leaving mid-conversation (ESC /
## Walk away) resolves as REFUSED — true to lived experience.
##
## Signals understood from timelines:
##   REFUSED, TRACT_LEFT, RETURN_VISIT_SCHEDULED, BIBLE_STUDY_STARTED,
##   STUDY_CONTINUES   — terminal outcome (see FieldService.OUTCOME_EFFECTS)
##   OFFSCRIPT:<weight> — the player broke script; weight is doubt exposure
##   INNER_VOICE        — an inner-voice line played (see DoubtMeter)

const HOSTILE_SLAMMER_ARCHETYPE: StringName = &"hostile_slammer"

# Slammer line pool (cast.md § 6.1). Empty string = silent slam, door just
# closes. Profanity exists in lived experience but is held back — slot-machine
# random profanity feels off.
const HOSTILE_SLAMMER_LINES: Array[String] = [
	"No.",
	"Not interested.",
	"Please don't come back.",
	"",
]

const REVEAL_40_TIMELINE_PATH: String = "res://data/dialogues/internals/reveal_40.dtl"
const DEFAULT_STUDY_TIMELINE_PATH: String = "res://data/dialogues/study/study_session.dtl"
const DEFAULT_STUDY_BACKGROUND_PATH: String = "res://assets/backgrounds/study_kitchen.png"
const DEBUG_PANEL_SCENE_PATH: String = "res://scenes/dev/doubt_debug.tscn"
const TERRITORY_SCENE_PATH: String = "res://scenes/territory_map.tscn"

# Slammer-scene timing (seconds), ~1.5s total.
const SLAMMER_BEAT_PRE: float = 0.4
const SLAMMER_BEAT_LINE: float = 0.6
const SLAMMER_BEAT_POST: float = 0.4

@onready var _house_badge: Label = $HouseBadge
@onready var _leave_button: Button = $LeaveButton
@onready var _house_portrait: TextureRect = $HousePortrait

var _pending_house: House = null
var _timeline_path: String = ""
var _dialogue_id: String = ""
var _resolved: bool = false
var _reveal_pending: bool = false
var _slammer_active: bool = false


func _ready() -> void:
	_pending_house = TerritoryManager.get_pending_house()
	_refresh_house_badge()
	_refresh_house_portrait()
	_leave_button.pressed.connect(_on_walk_away_pressed)
	Dialogic.signal_event.connect(_on_dialogic_signal)
	Dialogic.timeline_ended.connect(_on_timeline_ended)
	_maybe_instantiate_debug_panel()
	_start()


func _maybe_instantiate_debug_panel() -> void:
	if not OS.is_debug_build() or not ResourceLoader.exists(DEBUG_PANEL_SCENE_PATH):
		return
	var packed: PackedScene = load(DEBUG_PANEL_SCENE_PATH)
	add_child(packed.instantiate())


func _unhandled_input(event: InputEvent) -> void:
	if _slammer_active:
		return
	if event.is_action_pressed("ui_cancel"):
		_on_walk_away_pressed()
		get_viewport().set_input_as_handled()


func _refresh_house_badge() -> void:
	if _pending_house == null:
		_house_badge.text = tr("(no house)")
		return
	var number: int = TerritoryManager.house_number_for(_pending_house)
	var name: String = _pending_house.householder.character_name if _pending_house.householder != null else ""
	if _pending_house.visit_count > 0 and not name.is_empty():
		_house_badge.text = tr("House %d — %s") % [number, name]
	else:
		_house_badge.text = tr("House %d") % number


func _refresh_house_portrait() -> void:
	if _pending_house == null:
		return
	# A study happens inside, at the kitchen table, once that art exists.
	if _pending_house.state == House.State.BIBLE_STUDY_STARTED and _pending_house.householder != null:
		var inside: String = _pending_house.householder.study_background
		if inside.is_empty():
			inside = DEFAULT_STUDY_BACKGROUND_PATH
		if ResourceLoader.exists(inside):
			_house_portrait.texture = load(inside)
			return
	var tex: Texture2D = TerritoryManager.get_house_portrait(TerritoryManager.house_number_for(_pending_house))
	if tex != null:
		_house_portrait.texture = tex


func _start() -> void:
	if _pending_house == null or _pending_house.householder == null:
		push_warning("[door_knock] No pending house or householder; returning to the map.")
		_leave_scene()
		return
	var householder: Householder = _pending_house.householder
	if householder.archetype == HOSTILE_SLAMMER_ARCHETYPE:
		_timeline_path = ""
	elif _pending_house.state == House.State.BIBLE_STUDY_STARTED:
		_timeline_path = householder.study_timeline if not householder.study_timeline.is_empty() else DEFAULT_STUDY_TIMELINE_PATH
	else:
		_timeline_path = householder.dialogue_timeline
	if householder.archetype != HOSTILE_SLAMMER_ARCHETYPE and _timeline_path.is_empty():
		push_warning("[door_knock] Householder has no timeline; resolving as REFUSED.")
		_resolve("REFUSED")
		return
	# The threshold-40 reveal plays once, before the next conversation after
	# doubt first crosses 40, then chains into it via _on_timeline_ended.
	if DoubtMeter.consume_reveal_40():
		_reveal_pending = true
		Dialogic.start(REVEAL_40_TIMELINE_PATH)
		return
	_start_conversation()


func _start_conversation() -> void:
	if _timeline_path.is_empty():
		_run_hostile_slammer_scene()
		return
	_dialogue_id = _timeline_path.get_file().get_basename()
	SignalBus.dialogue_started.emit(_dialogue_id)
	Dialogic.start(_timeline_path)


func _on_dialogic_signal(arg: Variant) -> void:
	if typeof(arg) != TYPE_STRING or _resolved:
		return
	var key: String = arg
	if key.begins_with("OFFSCRIPT:"):
		FieldService.resolve_offscript(float(key.get_slice(":", 1)))
		return
	if key == "INNER_VOICE":
		DoubtMeter.inner_voice()
		return
	if FieldService.OUTCOME_EFFECTS.has(key):
		_resolve(key)


func _on_timeline_ended() -> void:
	if _resolved:
		return
	if _reveal_pending:
		_reveal_pending = false
		_start_conversation()
		return
	# Every validated branch ends in an outcome signal (tools/ci test_content);
	# this only fires on author error.
	push_warning("[door_knock] Timeline %s ended without an outcome signal; resolving as REFUSED." % _dialogue_id)
	_resolve("REFUSED")


func _on_walk_away_pressed() -> void:
	if _resolved or _slammer_active:
		return
	_resolved = true
	_reveal_pending = false
	if Dialogic.current_timeline != null:
		Dialogic.end_timeline()
	if _pending_house != null:
		FieldService.resolve_walk_away(_pending_house)
	_leave_scene()


func _run_hostile_slammer_scene() -> void:
	# ~1.5s, no Dialogic, no portrait — the lack of a face is the texture.
	_slammer_active = true
	_leave_button.visible = false
	var line: String = HOSTILE_SLAMMER_LINES[randi() % HOSTILE_SLAMMER_LINES.size()]
	var label: Label = Label.new()
	label.text = tr(line)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.modulate = Color(0.95, 0.92, 0.86, 0.0)
	label.add_theme_font_size_override("font_size", 36)
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	await get_tree().create_timer(SLAMMER_BEAT_PRE).timeout
	if _resolved or not is_inside_tree():
		return
	if not line.is_empty():
		label.modulate.a = 0.8
	await get_tree().create_timer(SLAMMER_BEAT_LINE).timeout
	if _resolved or not is_inside_tree():
		return
	label.modulate.a = 0.0
	await get_tree().create_timer(SLAMMER_BEAT_POST).timeout
	if _resolved or not is_inside_tree():
		return
	_resolve("REFUSED")


func _resolve(outcome_key: String) -> void:
	if _resolved:
		return
	_resolved = true
	if _pending_house != null:
		FieldService.resolve_outcome(_pending_house, outcome_key)
	_leave_scene()


func _leave_scene() -> void:
	_resolved = true
	if Dialogic.signal_event.is_connected(_on_dialogic_signal):
		Dialogic.signal_event.disconnect(_on_dialogic_signal)
	if Dialogic.timeline_ended.is_connected(_on_timeline_ended):
		Dialogic.timeline_ended.disconnect(_on_timeline_ended)
	if not _dialogue_id.is_empty():
		SignalBus.dialogue_ended.emit(_dialogue_id)
	# Deferred: resolution can happen inside _ready, when the tree is still
	# adding this scene and can't swap it out yet.
	get_tree().change_scene_to_file.call_deferred(TERRITORY_SCENE_PATH)
