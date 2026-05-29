extends Control
## Hall of Witness meeting scene (M5). Single scene parameterized by
## MeetingManager.pending_meeting_type. Sunday runs Public Talk then
## Lighthouse Study back-to-back in one trip; Tuesday runs Midweek alone.
##
## Per Decision A (M5 Phase 1): per-talk resolve in the same scene. Each
## talk's effects fire on its own timeline_ended; meeting Energy fires once
## after the final talk (or on skip — but skip is handled at week_view, not
## here). Per Decision B: inner-voice gate uses direct-read
## DoubtMeter.value >= 40 inside the .dtl (no in-scene rendering needed;
## Dialogic renders the italic [i] line as a regular text event).
##
## Phase state machine:
##   SEAT_PICKER → SOCIAL_MOMENT → TALK (one or more) → RESOLVE
##
## meeting_hall does NOT have a back/walk-away button. Once the player
## clicks ATTEND on week_view, they commit to the meeting flow. The
## Skip-the-Meeting choice is made at week_view (per Decision E) — fires
## inline there and never enters this scene.

const DEBUG_PANEL_SCENE_PATH: String = "res://scenes/dev/doubt_debug.tscn"

# Brief beat between talks so the per-talk effects landing feels distinct
# from the next talk's opening. Mirrors door_knock's slammer pre/post timing.
const INTER_TALK_BEAT_SECONDS: float = 0.5

enum Phase {
	SEAT_PICKER,
	SOCIAL_MOMENT,
	SONG,
	TALK,
	RESOLVE,
}

@onready var _phase_title: Label = $PhaseCard/PhaseMargin/PhaseVBox/PhaseTitle
@onready var _phase_flavor: Label = $PhaseCard/PhaseMargin/PhaseVBox/PhaseFlavor
@onready var _phase_content: VBoxContainer = $PhaseCard/PhaseMargin/PhaseVBox/PhaseContent
@onready var _phase_card: PanelContainer = $PhaseCard
@onready var _hall_background: TextureRect = $HallBackground

# Per-speaker stage BG paths. The default hall_of_witness.png (set in
# meeting_hall.tscn) is used outside the TALK phase and as a fallback for
# any speaker without a stage shot. Speaker .id is the lookup key — matches
# Speaker.id in data/speakers/*.tres.
const STAGE_BG_PATHS: Dictionary = {
	&"elder_coordinator": "res://assets/backgrounds/coordinator_stage.png",
	&"elder_strict":      "res://assets/backgrounds/strict_stage.png",
}
const DEFAULT_HALL_BG_PATH: String = "res://assets/backgrounds/hall_of_witness.png"

var _meeting_type: StringName = &""
var _talks_remaining: Array = []
var _current_talk: StringName = &""
var _current_speech_slug: StringName = &""
var _chosen_seat: StringName = &""
var _phase: Phase = Phase.SEAT_PICKER
var _resolved: bool = false


func _ready() -> void:
	_meeting_type = MeetingManager.get_pending_meeting()
	if _meeting_type == &"":
		push_warning("[meeting_hall] No pending meeting; returning to week_view.")
		# change_scene_to_file is illegal inside _ready (parent is mid-add);
		# defer so the scene-tree settles before swapping.
		call_deferred("_return_to_week_view")
		return
	_talks_remaining = MeetingManager.talks_for_meeting(_meeting_type).duplicate()
	if _talks_remaining.is_empty():
		push_warning("[meeting_hall] Meeting type %s has no talks; returning to week_view." % _meeting_type)
		call_deferred("_return_to_week_view")
		return
	# Dialogic wiring stays connected for the full meeting; talks share the
	# same handler that pops _talks_remaining and chains the next start.
	DialogicResourceUtil.update_directory(".dch")
	DialogicResourceUtil.update_directory(".dtl")
	Dialogic.signal_event.connect(_on_dialogic_signal)
	Dialogic.timeline_ended.connect(_on_timeline_ended)
	_maybe_instantiate_debug_panel()
	_show_seat_picker()


func _maybe_instantiate_debug_panel() -> void:
	if not OS.is_debug_build():
		return
	if not ResourceLoader.exists(DEBUG_PANEL_SCENE_PATH):
		return
	var packed: PackedScene = load(DEBUG_PANEL_SCENE_PATH)
	add_child(packed.instantiate())


# --- Phase: seat picker ------------------------------------------------------

func _show_seat_picker() -> void:
	_phase = Phase.SEAT_PICKER
	_phase_card.visible = true
	_phase_title.text = tr("Choose your seat")
	_phase_flavor.text = tr("The brothers and sisters are gathering. Where do you sit?")
	_clear_phase_content()
	# 6 seats laid out 2×3 (2 columns, 3 rows). Order mirrors
	# MeetingManager.SEAT_NEIGHBORS dict iteration so the layout is stable.
	var grid: GridContainer = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 12)
	for seat_slug in MeetingManager.SEAT_NEIGHBORS:
		var button: Button = Button.new()
		button.text = _label_for_seat(seat_slug)
		button.custom_minimum_size = Vector2(280, 56)
		button.add_theme_font_size_override("font_size", 16)
		button.pressed.connect(_on_seat_picked.bind(seat_slug))
		grid.add_child(button)
	_phase_content.add_child(grid)


func _label_for_seat(seat_slug: StringName) -> String:
	# Convert &"front_left" → "Front Left". Keeps the visible label
	# decoupled from the slug; preserves slug-as-data-key discipline.
	var s: String = String(seat_slug).replace("_", " ")
	return s.capitalize()


func _on_seat_picked(seat_slug: StringName) -> void:
	if _phase != Phase.SEAT_PICKER:
		return
	_chosen_seat = seat_slug
	_show_social_moment()


# --- Phase: social moment ----------------------------------------------------

func _show_social_moment() -> void:
	_phase = Phase.SOCIAL_MOMENT
	_phase_card.visible = true
	_phase_title.text = tr("A moment before the talk")
	# Seat → neighbor → moment. SEAT_NEIGHBORS keys are seat slugs; the
	# moment options dict is keyed by the neighbor identity that the seat
	# is pinned next to.
	var neighbor: StringName = MeetingManager.SEAT_NEIGHBORS.get(_chosen_seat, &"")
	var moment: Dictionary = MeetingManager.SOCIAL_MOMENT_OPTIONS.get(neighbor, {})
	_phase_flavor.text = tr(moment.get("prompt", ""))
	_clear_phase_content()
	var choices: Array = moment.get("choices", [])
	for choice in choices:
		var button: Button = Button.new()
		button.text = tr(choice.get("label", ""))
		button.custom_minimum_size = Vector2(0, 48)
		button.add_theme_font_size_override("font_size", 15)
		button.pressed.connect(_on_social_moment_picked.bind(choice))
		_phase_content.add_child(button)


func _on_social_moment_picked(choice: Dictionary) -> void:
	if _phase != Phase.SOCIAL_MOMENT:
		return
	var delta: int = int(choice.get("standing_delta", 0))
	var standing_type: StringName = StringName(choice.get("standing_type", &"congregation"))
	if delta != 0:
		_apply_standing_delta(standing_type, delta)
	_start_next_talk()


func _apply_standing_delta(standing_type: StringName, delta: int) -> void:
	# ResourceManager exposes three add_standing_* methods; dispatch by type.
	match standing_type:
		&"congregation":
			ResourceManager.add_standing_congregation(delta)
		&"family":
			ResourceManager.add_standing_family(delta)
		&"elders":
			ResourceManager.add_standing_elders(delta)
		_:
			push_warning("[meeting_hall] Unknown standing_type %s; no delta applied." % standing_type)


# --- Phase: talks ------------------------------------------------------------

func _start_next_talk() -> void:
	if _talks_remaining.is_empty():
		_resolve_meeting()
		return
	_current_talk = _talks_remaining.pop_front()
	_current_speech_slug = MeetingManager.pick_speech_for(_current_talk)
	if _current_speech_slug == &"":
		push_warning("[meeting_hall] No speech available for %s; skipping talk." % _current_talk)
		_advance_after_talk()
		return
	var song_slug: StringName = MeetingManager.song_before_talk(_current_talk)
	if song_slug != &"":
		_show_song(song_slug)
		return
	_enter_talk_phase()


func _enter_talk_phase() -> void:
	_phase = Phase.TALK
	# Hide the phase card while Dialogic owns the screen. Dialogic instantiates
	# its own text pane + portrait layer on Dialogic.start().
	_phase_card.visible = false
	_apply_stage_background_for_current_talk()
	var timeline_path: String = MeetingManager.get_speech_path(_current_speech_slug)
	Dialogic.start(timeline_path)


func _apply_stage_background_for_current_talk() -> void:
	var speaker: Speaker = MeetingManager.get_speaker_for(_current_talk)
	if speaker == null:
		_restore_default_hall_background()
		return
	var path: String = STAGE_BG_PATHS.get(speaker.id, "")
	if path == "" or not ResourceLoader.exists(path):
		_restore_default_hall_background()
		return
	var tex: Texture2D = load(path)
	if tex != null:
		_hall_background.texture = tex


func _restore_default_hall_background() -> void:
	if not ResourceLoader.exists(DEFAULT_HALL_BG_PATH):
		return
	var tex: Texture2D = load(DEFAULT_HALL_BG_PATH)
	if tex != null:
		_hall_background.texture = tex


# --- Phase: song ------------------------------------------------------------

func _show_song(song_slug: StringName) -> void:
	_phase = Phase.SONG
	_phase_card.visible = true
	var song: Dictionary = MeetingManager.get_song(song_slug)
	var number: int = int(song.get("number", 0))
	var title: String = String(song.get("title", ""))
	_phase_title.text = tr("Song %d") % number
	_phase_flavor.text = tr(title)
	_clear_phase_content()
	var lyric: Label = Label.new()
	lyric.text = tr(String(song.get("opening_lines", "")))
	lyric.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lyric.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lyric.add_theme_font_size_override("font_size", 16)
	_phase_content.add_child(lyric)
	var continue_button: Button = Button.new()
	continue_button.text = tr("Continue")
	continue_button.custom_minimum_size = Vector2(220, 44)
	continue_button.add_theme_font_size_override("font_size", 15)
	continue_button.pressed.connect(_on_song_continue_pressed)
	_phase_content.add_child(continue_button)


func _on_song_continue_pressed() -> void:
	if _phase != Phase.SONG:
		return
	_enter_talk_phase()


func _on_dialogic_signal(arg: Variant) -> void:
	# Talk completion signal — fires from each placeholder .dtl's terminal
	# [signal arg="TALK_COMPLETED"]. Effects fire here (per Decision C: per-
	# talk Conviction + Standing-Elders). Energy fires later in _resolve_meeting.
	if typeof(arg) != TYPE_STRING:
		return
	if arg != "TALK_COMPLETED":
		return
	if _phase != Phase.TALK:
		return
	MeetingManager.resolve_talk_completed(_current_talk, _current_speech_slug)


func _on_timeline_ended() -> void:
	# Reached after the .dtl's [end_timeline]. The signal_event handler above
	# already fired the per-talk effects; this just advances to the next talk
	# (with a brief beat) or resolves the meeting.
	if _phase != Phase.TALK:
		return
	_advance_after_talk()


func _advance_after_talk() -> void:
	_current_talk = &""
	_current_speech_slug = &""
	# Restore the default Hall BG between talks (and before resolve). The
	# next talk's _enter_talk_phase will swap to that speaker's stage shot.
	_restore_default_hall_background()
	if _talks_remaining.is_empty():
		_resolve_meeting()
		return
	# If the next talk has a song before it, the song itself is the transition —
	# skip the "short pause" beat. Otherwise show the phase card during a brief
	# beat so the screen isn't empty between talks.
	var next_talk: StringName = _talks_remaining[0]
	if MeetingManager.song_before_talk(next_talk) != &"":
		_start_next_talk()
		return
	_phase_card.visible = true
	_phase_title.text = tr("A short pause")
	_phase_flavor.text = tr("The hall settles. The next speaker takes the platform.")
	_clear_phase_content()
	await get_tree().create_timer(INTER_TALK_BEAT_SECONDS).timeout
	if not is_inside_tree() or _resolved:
		return
	_start_next_talk()


# --- Phase: resolve ----------------------------------------------------------

func _resolve_meeting() -> void:
	if _resolved:
		return
	_resolved = true
	_phase = Phase.RESOLVE
	if Dialogic.signal_event.is_connected(_on_dialogic_signal):
		Dialogic.signal_event.disconnect(_on_dialogic_signal)
	if Dialogic.timeline_ended.is_connected(_on_timeline_ended):
		Dialogic.timeline_ended.disconnect(_on_timeline_ended)
	MeetingManager.resolve_meeting_completed(_meeting_type)
	TimeManager.advance_phase()
	_return_to_week_view()


func _return_to_week_view() -> void:
	get_tree().change_scene_to_file("res://scenes/week_view.tscn")


# --- Helpers -----------------------------------------------------------------

func _clear_phase_content() -> void:
	for child in _phase_content.get_children():
		child.queue_free()
