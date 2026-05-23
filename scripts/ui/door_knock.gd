extends Control
## Porch view. Runs a Dialogic timeline for the pending house's householder.
## Outcomes are emitted from the timeline via [signal arg="..."] events and
## mapped to House.State. Mid-conversation exit (ESC / Walk away button) is
## treated as REFUSED — true to lived experience and reuses the existing
## enum without introducing a new state.
##
## M4 layers four trigger and two decrement events onto the existing flow.
## All doubt firing happens here, the only systems code that knows about
## both Dialogic and TerritoryManager. doubt_meter.gd stays content-agnostic.

# Map from Dialogic signal_event argument strings to House.State enum values.
# Strings must exactly match the [signal arg="..."] values in
# data/dialogues/polite_refuser_v1.dtl.
const SIGNAL_OUTCOME_MAP: Dictionary = {
	"REFUSED": House.State.REFUSED,
	"TRACT_LEFT": House.State.TRACT_LEFT,
	"RETURN_VISIT_SCHEDULED": House.State.RETURN_VISIT_SCHEDULED,
}

# T3 / D1 / D2 — outcome-driven doubt deltas keyed by the same signal arg.
# Walk-away is NOT here; it has its own handler (T2).
const OUTCOME_DOUBT_DELTAS: Dictionary = {
	"REFUSED": 1,            # T3 polite refusal
	"TRACT_LEFT": -1,        # D1 low-bar positive
	"RETURN_VISIT_SCHEDULED": -2,  # D2 gold-star outcome
}

# T1 — off-script choice. The match is intentionally string-equal to the
# choice text in polite_refuser_v1.dtl E3d. If that text changes, this
# constant must change with it. STATUS flags this as a tightening target.
const OFFSCRIPT_CHOICE_TEXT: String = "Why is that for you?"

const REVEAL_40_TIMELINE_PATH: String = "res://data/dialogues/internals/reveal_40.dtl"
const DEBUG_PANEL_SCENE_PATH: String = "res://scenes/dev/doubt_debug.tscn"

@onready var _house_badge: Label = $HouseBadge
@onready var _leave_button: Button = $LeaveButton

var _pending_house: House = null
var _dialogue_id: String = ""
var _resolved: bool = false
var _reveal_pending: bool = false


func _ready() -> void:
	_pending_house = TerritoryManager.get_pending_house()
	_refresh_house_badge()
	_leave_button.pressed.connect(_on_walk_away_pressed)
	Dialogic.signal_event.connect(_on_dialogic_signal)
	Dialogic.timeline_ended.connect(_on_timeline_ended)
	Dialogic.Choices.choice_selected.connect(_on_choice_selected)
	_maybe_instantiate_debug_panel()
	_start_dialogue_for_pending_house()


func _maybe_instantiate_debug_panel() -> void:
	if not OS.is_debug_build():
		return
	if not ResourceLoader.exists(DEBUG_PANEL_SCENE_PATH):
		return
	var packed: PackedScene = load(DEBUG_PANEL_SCENE_PATH)
	add_child(packed.instantiate())


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_walk_away_pressed()
		get_viewport().set_input_as_handled()


func _refresh_house_badge() -> void:
	if _pending_house == null:
		_house_badge.text = tr("(no house)")
		return
	_house_badge.text = tr("House %s") % str(_pending_house.id).trim_prefix("house_")


func _start_dialogue_for_pending_house() -> void:
	if _pending_house == null or _pending_house.householder == null:
		push_warning("[door_knock] No pending house or householder; treating as REFUSED.")
		_resolve_with_outcome(House.State.REFUSED)
		return
	# Force a fresh scan of .dch/.dtl directories so the character/timeline
	# identifiers in the .dtl resolve even on a cold headless launch where
	# the project-settings directories aren't yet populated by the editor.
	DialogicResourceUtil.update_directory(".dch")
	DialogicResourceUtil.update_directory(".dtl")
	var timeline_path: String = _pending_house.householder.dialogue_timeline
	if timeline_path.is_empty():
		push_warning("[door_knock] Householder has no dialogue_timeline; treating as REFUSED.")
		_resolve_with_outcome(House.State.REFUSED)
		return
	_dialogue_id = timeline_path.get_file().get_basename()
	SignalBus.dialogue_started.emit(_dialogue_id)
	# Threshold-40 reveal (one-shot). consume_reveal_40 returns true only on
	# the first door-knock after doubt crosses 40, and self-clears the flag.
	# We play the reveal first, then chain into the householder timeline via
	# _on_timeline_ended.
	if DoubtMeter.consume_reveal_40():
		_reveal_pending = true
		Dialogic.start(REVEAL_40_TIMELINE_PATH)
		return
	Dialogic.start(timeline_path)


func _on_dialogic_signal(arg: Variant) -> void:
	if typeof(arg) != TYPE_STRING:
		return
	var key: String = arg
	if not SIGNAL_OUTCOME_MAP.has(key):
		return
	# T3 / D1 / D2 — outcome-driven doubt firing. Walk-away is excluded
	# here (its own handler fires T2) so we never double-count.
	if OUTCOME_DOUBT_DELTAS.has(key):
		var delta: int = OUTCOME_DOUBT_DELTAS[key]
		DoubtMeter.apply(delta, StringName("outcome_" + key.to_lower()))
	_resolve_with_outcome(SIGNAL_OUTCOME_MAP[key])


func _on_choice_selected(info: Dictionary) -> void:
	# T1 — off-script choice. Text-match against the M3-validated line.
	# Brittle by design: the M4 plan accepts this and STATUS flags it as a
	# tightening target (replace with a Dialogic choice tag or metadata once
	# the addon offers a stable hook).
	var text: String = String(info.get("text", "")).strip_edges()
	if text == OFFSCRIPT_CHOICE_TEXT:
		DoubtMeter.apply(3, &"offscript_why_taken")


func _on_timeline_ended() -> void:
	if _resolved:
		return
	# Reveal-40 just ended — chain into the householder timeline.
	if _reveal_pending:
		_reveal_pending = false
		var timeline_path: String = _pending_house.householder.dialogue_timeline
		Dialogic.start(timeline_path)
		return
	# Safety net: a householder timeline reached its end without emitting one
	# of the expected outcome signals. With the current Polite Refuser timeline
	# every branch terminates in [signal arg=...] + [end_timeline], so this
	# only fires on author error or future timelines that forget.
	push_warning("[door_knock] Timeline %s ended without emitting an outcome signal. Defaulting to REFUSED." % _dialogue_id)
	_resolve_with_outcome(House.State.REFUSED)


func _on_walk_away_pressed() -> void:
	if _resolved:
		return
	# T2 — walk away. Applied before resolve so the event log records it
	# before the scene transition tears this scene down. Cancel any pending
	# reveal → householder chain so _on_timeline_ended doesn't try to start
	# the householder timeline mid-bail.
	DoubtMeter.apply(2, &"walked_away")
	_reveal_pending = false
	if Dialogic.current_timeline != null:
		Dialogic.end_timeline()
	_resolve_with_outcome(House.State.REFUSED)


func _resolve_with_outcome(outcome: int) -> void:
	if _resolved:
		return
	_resolved = true
	if Dialogic.signal_event.is_connected(_on_dialogic_signal):
		Dialogic.signal_event.disconnect(_on_dialogic_signal)
	if Dialogic.timeline_ended.is_connected(_on_timeline_ended):
		Dialogic.timeline_ended.disconnect(_on_timeline_ended)
	if Dialogic.Choices.choice_selected.is_connected(_on_choice_selected):
		Dialogic.Choices.choice_selected.disconnect(_on_choice_selected)
	TerritoryManager.resolve_pending_house(outcome)
	if not _dialogue_id.is_empty():
		SignalBus.dialogue_ended.emit(_dialogue_id)
	get_tree().change_scene_to_file("res://scenes/territory_map.tscn")
