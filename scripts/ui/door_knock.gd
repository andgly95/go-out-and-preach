extends Control
## Porch view. Runs a Dialogic timeline for the pending house's householder,
## OR a minimal no-Dialogic scene for the Hostile Slammer archetype.
## Outcomes are emitted from Dialogic timelines via [signal arg="..."] events
## and mapped to House.State. Mid-conversation exit (ESC / Walk away button)
## is treated as REFUSED — true to lived experience and reuses the existing
## enum without introducing a new state.
##
## M4 layers four trigger and two decrement events onto the existing flow.
## M4.1 adds: per-archetype doubt-delta overrides (Hostile Slammer REFUSED
## resolves to +0 via this overlay), a Hostile Slammer inline scene that
## bypasses Dialogic, the BIBLE_STUDY_STARTED outcome for Curious Seeker,
## and a multi-line off-script choice registry (T1 fires for either the
## PR or the CS off-script choice text).
##
## All doubt firing happens here, the only systems code that knows about
## both Dialogic and TerritoryManager. doubt_meter.gd stays content-agnostic.

# Map from Dialogic signal_event argument strings to House.State enum values.
# Strings must exactly match the [signal arg="..."] values in
# data/dialogues/*.dtl.
const SIGNAL_OUTCOME_MAP: Dictionary = {
	"REFUSED": House.State.REFUSED,
	"TRACT_LEFT": House.State.TRACT_LEFT,
	"RETURN_VISIT_SCHEDULED": House.State.RETURN_VISIT_SCHEDULED,
	"BIBLE_STUDY_STARTED": House.State.BIBLE_STUDY_STARTED,
}

# T3 / D1 / D2 / D3 — outcome-driven doubt deltas keyed by the same signal arg.
# Walk-away is NOT here; it has its own handler (T2).
# Per-archetype overrides via Householder.doubt_delta_overrides take precedence
# (see _resolve_doubt_delta below).
const OUTCOME_DOUBT_DELTAS: Dictionary = {
	"REFUSED": 1,                  # T3 polite refusal
	"TRACT_LEFT": -1,              # D1 low-bar positive
	"RETURN_VISIT_SCHEDULED": -2,  # D2 gold-star outcome
	"BIBLE_STUDY_STARTED": -3,     # D3 deepest positive — months of contact
}

# T1 — off-script choices. Registry of choice-text strings that fire the
# off-script doubt event. Multi-timeline registry as of M4.1 (M3 was single
# string). Still text-keyed and therefore brittle — STATUS carries the
# tightening target (replace with a Dialogic choice tag or [signal] shim).
const OFFSCRIPT_CHOICE_TEXTS: Dictionary = {
	"Why is that for you?": true,    # polite_refuser_v1.dtl E3d
	"I don't know. Honestly.": true, # curious_seeker_v1.dtl E3d (M4.2 dialogue subagent pass)
}

const HOSTILE_SLAMMER_ARCHETYPE: StringName = &"hostile_slammer"

# Slammer line pool (cast.md § 6.1). Empty string = silent slam, door
# just closes. Profanity options exist in lived experience but are held
# back from the M4.1 pool — slot-machine random profanity feels off.
const HOSTILE_SLAMMER_LINES: Array[String] = [
	"No.",
	"Not interested.",
	"Please don't come back.",
	"",
]

const REVEAL_40_TIMELINE_PATH: String = "res://data/dialogues/internals/reveal_40.dtl"
const DEBUG_PANEL_SCENE_PATH: String = "res://scenes/dev/doubt_debug.tscn"

# Slammer-scene timing (seconds). Sum ~1.5s per plan Q4.
const SLAMMER_BEAT_PRE: float = 0.4
const SLAMMER_BEAT_LINE: float = 0.6
const SLAMMER_BEAT_POST: float = 0.4

@onready var _house_badge: Label = $HouseBadge
@onready var _leave_button: Button = $LeaveButton

var _pending_house: House = null
var _dialogue_id: String = ""
var _resolved: bool = false
var _reveal_pending: bool = false
var _slammer_after_reveal: bool = false
var _slammer_active: bool = false


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
	if _slammer_active:
		# No walk-away during a 1.5s slammer scene. ESC is swallowed silently.
		return
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
	# Hostile Slammer: no Dialogic timeline. Branch to the inline scene.
	# If reveal-40 is pending, play the reveal first then chain to the
	# slammer scene via _on_timeline_ended (Q6).
	if _pending_house.householder.archetype == HOSTILE_SLAMMER_ARCHETYPE:
		if DoubtMeter.consume_reveal_40():
			_reveal_pending = true
			_slammer_after_reveal = true
			Dialogic.start(REVEAL_40_TIMELINE_PATH)
			return
		_run_hostile_slammer_scene()
		return
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
	# T3 / D1 / D2 / D3 — outcome-driven doubt firing. Per-archetype overrides
	# applied via _resolve_doubt_delta. Walk-away is excluded here (its own
	# handler fires T2) so we never double-count.
	var delta: int = _resolve_doubt_delta(key)
	if delta != 0:
		DoubtMeter.apply(delta, StringName("outcome_" + key.to_lower()))
	_resolve_with_outcome(SIGNAL_OUTCOME_MAP[key])


func _on_choice_selected(info: Dictionary) -> void:
	# T1 — off-script choice. Multi-timeline text registry (M4.1). Brittle by
	# design: STATUS flags it as a tightening target (replace with a Dialogic
	# choice tag or metadata once the addon offers a stable hook).
	var text: String = String(info.get("text", "")).strip_edges()
	if OFFSCRIPT_CHOICE_TEXTS.has(text):
		DoubtMeter.apply(3, &"offscript_why_taken")


func _on_timeline_ended() -> void:
	if _resolved:
		return
	# Reveal-40 just ended — chain into the next scene. Branch on whether
	# the next scene is Dialogic (standard archetype) or inline (slammer).
	if _reveal_pending:
		_reveal_pending = false
		if _slammer_after_reveal:
			_slammer_after_reveal = false
			_run_hostile_slammer_scene()
			return
		var timeline_path: String = _pending_house.householder.dialogue_timeline
		Dialogic.start(timeline_path)
		return
	# Safety net: a householder timeline reached its end without emitting one
	# of the expected outcome signals. With validated timelines every branch
	# terminates in [signal arg=...] + [end_timeline], so this only fires on
	# author error or future timelines that forget.
	push_warning("[door_knock] Timeline %s ended without emitting an outcome signal. Defaulting to REFUSED." % _dialogue_id)
	_resolve_with_outcome(House.State.REFUSED)


func _on_walk_away_pressed() -> void:
	if _resolved:
		return
	if _slammer_active:
		# UI guarantees the button is hidden during slammer scenes; this is
		# defense-in-depth in case a signal sneaks through.
		return
	# T2 — walk away. Applied before resolve so the event log records it
	# before the scene transition tears this scene down. Cancel any pending
	# reveal → next-scene chain so _on_timeline_ended doesn't try to start
	# the next scene mid-bail.
	DoubtMeter.apply(2, &"walked_away")
	_reveal_pending = false
	_slammer_after_reveal = false
	if Dialogic.current_timeline != null:
		Dialogic.end_timeline()
	_resolve_with_outcome(House.State.REFUSED)


func _run_hostile_slammer_scene() -> void:
	# Inline ~1.5s no-Dialogic scene for the Hostile Slammer archetype.
	# Sequence: brief pre-beat → transient line label → post-beat silence →
	# REFUSED resolution. No portrait — the lack of a face is the texture.
	_slammer_active = true
	_leave_button.visible = false
	_dialogue_id = ""  # No Dialogic; no dialogue_started/ended emit.
	var line: String = HOSTILE_SLAMMER_LINES[randi() % HOSTILE_SLAMMER_LINES.size()]
	var label: Label = Label.new()
	label.text = line
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.modulate = Color(0.95, 0.92, 0.86, 0.0)
	label.add_theme_font_size_override("font_size", 32)
	label.anchor_left = 0.0
	label.anchor_top = 0.0
	label.anchor_right = 1.0
	label.anchor_bottom = 1.0
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	await get_tree().create_timer(SLAMMER_BEAT_PRE).timeout
	if _resolved or not is_inside_tree():
		return
	# Fade in (instant snap for line; silence path stays at alpha 0).
	if not line.is_empty():
		label.modulate.a = 0.8
	await get_tree().create_timer(SLAMMER_BEAT_LINE).timeout
	if _resolved or not is_inside_tree():
		return
	label.modulate.a = 0.0
	await get_tree().create_timer(SLAMMER_BEAT_POST).timeout
	if _resolved or not is_inside_tree():
		return
	# Slammer doubt firing — per-archetype override resolves Hostile Slammer
	# REFUSED to +0 (Q2). apply() early-returns on delta=0 so the log stays
	# clean.
	var delta: int = _resolve_doubt_delta("REFUSED")
	if delta != 0:
		DoubtMeter.apply(delta, &"outcome_refused")
	_resolve_with_outcome(House.State.REFUSED)


func _resolve_doubt_delta(outcome_key: String) -> int:
	# Per-archetype override > global table. Empty overrides dict (default)
	# means use the global magnitude.
	if _pending_house != null and _pending_house.householder != null:
		var overrides: Dictionary = _pending_house.householder.doubt_delta_overrides
		if overrides.has(outcome_key):
			return int(overrides[outcome_key])
	return int(OUTCOME_DOUBT_DELTAS.get(outcome_key, 0))


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
