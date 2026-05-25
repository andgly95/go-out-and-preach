extends Control
## Default scene after New Game / on return from territory or other phases.
## Renders the current day card (title, flavor, activity rows) and a "Today's
## Schedule" panel — both driven from per-phase content tables below.
## TimeManager.advance_phase() is the canonical way time moves forward; this
## screen is purely a presentation + entry point.

const SERVICE_DAY_PHASES: Array = [TimeManager.Phase.THURSDAY, TimeManager.Phase.SATURDAY]
const MEETING_DAY_PHASES: Array = [TimeManager.Phase.SUNDAY, TimeManager.Phase.TUESDAY]

const SCRIPTURE_QUOTE: String = "\"Let your light shine before others, so that they may see your good works.\""
const SCRIPTURE_REF:   String = "— MATTHEW 5:16"

# Per-day content. Activities feed the center card's stacked rows; schedule
# feeds the right-hand "TODAY'S SCHEDULE" panel. Keep strings authentic to
# Society of the Truth vocabulary per CLAUDE.md (publisher, Hall of Witness,
# Lighthouse, service partner) — no real-org names or quoted publications.
const DAY_CONTENT: Dictionary = {
	TimeManager.Phase.SUNDAY: {
		"flavor": "The Lord's day at the Hall of Witness. Worship anchors the week.",
		"activities": [
			{"icon": "✦", "name": "Public Talk", "description": "A speaker from another congregation delivers the morning address."},
			{"icon": "📖", "name": "Lighthouse Study", "description": "Review this week's article together, paragraph by paragraph."},
		],
		"schedule": [
			{"period": "Morning", "icon": "☀", "title": "Worship at the Hall", "description": "Public Talk and song service."},
			{"period": "Midday",  "icon": "✦", "title": "Family meal", "description": "Visit with brothers and sisters after the meeting."},
			{"period": "Evening", "icon": "☾", "title": "Lighthouse Study", "description": "Article study with the congregation."},
		],
	},
	TimeManager.Phase.MONDAY: {
		"flavor": "A working day. Steady on through the secular hours.",
		"activities": [
			{"icon": "✎", "name": "Secular work", "description": "Earn your living. Witness only as opportunity allows."},
			{"icon": "✦", "name": "Personal time", "description": "Rest, family, study — the small disciplines."},
		],
		"schedule": [
			{"period": "Morning", "icon": "☀", "title": "Begin the work week", "description": "Out the door with the day's intentions."},
			{"period": "Midday",  "icon": "✦", "title": "Lunch break", "description": "A quiet word with a coworker, perhaps."},
			{"period": "Evening", "icon": "☾", "title": "Family time", "description": "Personal study before bed."},
		],
	},
	TimeManager.Phase.TUESDAY: {
		"flavor": "Midweek strengthens what Sunday started.",
		"activities": [
			{"icon": "✦", "name": "Midweek Meeting", "description": "Theocratic instruction and ministry training at the Hall."},
		],
		"schedule": [
			{"period": "Morning", "icon": "☀", "title": "Working day continues", "description": "Mind on the evening meeting."},
			{"period": "Midday",  "icon": "📖", "title": "Review your part", "description": "If you have a student talk, go over it once more."},
			{"period": "Evening", "icon": "☾", "title": "Midweek Meeting", "description": "At the Hall of Witness with the congregation."},
		],
	},
	TimeManager.Phase.WEDNESDAY: {
		"flavor": "The middle of the week. The pace settles.",
		"activities": [
			{"icon": "✦", "name": "Personal time", "description": "An evening to yourself. Read, pray, prepare."},
		],
		"schedule": [
			{"period": "Morning", "icon": "☀", "title": "Working day", "description": "Out the door early."},
			{"period": "Midday",  "icon": "✦", "title": "Lunch", "description": "A walk if the weather allows."},
			{"period": "Evening", "icon": "☾", "title": "Personal study", "description": "Quiet hours at home."},
		],
	},
	TimeManager.Phase.THURSDAY: {
		"flavor": "A thoughtful day of preparation strengthens the work ahead.",
		"activities": [
			{"icon": "📖", "name": "Service prep", "description": "Prepare your heart and mind for field service."},
			{"icon": "✎", "name": "Return visit prep", "description": "Review past contacts and plan meaningful follow-ups."},
		],
		"schedule": [
			{"period": "Morning", "icon": "☀", "title": "Personal study and prayer", "description": "Begin the day in quiet."},
			{"period": "Midday",  "icon": "📖", "title": "Service and return visit preparation", "description": "Set the day's intentions."},
			{"period": "Evening", "icon": "☾", "title": "Review the day and plan tomorrow", "description": "Tomorrow is field service."},
		],
	},
	TimeManager.Phase.FRIDAY: {
		"flavor": "The week's edge. Tomorrow is field service.",
		"activities": [
			{"icon": "✦", "name": "Personal time", "description": "Rest your voice. Pack the magazine case. Set out early clothes."},
		],
		"schedule": [
			{"period": "Morning", "icon": "☀", "title": "Working day", "description": "Finish the week strong."},
			{"period": "Midday",  "icon": "✦", "title": "Lunch with a service partner", "description": "If one is free."},
			{"period": "Evening", "icon": "☾", "title": "Early to bed", "description": "Service begins at first light."},
		],
	},
	TimeManager.Phase.SATURDAY: {
		"flavor": "Field service day. Go out and preach.",
		"activities": [
			{"icon": "✦", "name": "Field Service", "description": "Knock the territory. Talk with whoever opens the door."},
		],
		"schedule": [
			{"period": "Morning", "icon": "☀", "title": "Service group meeting", "description": "Prayer, territory assignment, partner pairing."},
		   {"period": "Midday",  "icon": "📖", "title": "Doors and footwork", "description": "House by house through the territory."},
			{"period": "Evening", "icon": "☾", "title": "Report hours", "description": "Family meal. Pencil tomorrow."},
		],
	},
}

const CARD_GLYPH_COLOR_FILL: Color = Color(0.78, 0.62, 0.28, 1)
const CARD_GLYPH_COLOR_TEXT: Color = Color(0.09, 0.11, 0.16, 1)
const NAVY_DEEP: Color    = Color(0.09, 0.11, 0.16, 0.95)
const GOLD_BORDER: Color  = Color(0.62, 0.5, 0.27, 0.8)
const CREAM_TEXT: Color   = Color(0.96, 0.92, 0.79, 1)
const MUTED_TEXT: Color   = Color(0.82, 0.76, 0.62, 1)
const FAINT_TEXT: Color   = Color(0.78, 0.7, 0.52, 0.9)

@onready var _day_title:        Label = $CenterCard/CardMargin/CardVBox/DayTitle
@onready var _day_flavor:       Label = $CenterCard/CardMargin/CardVBox/DayFlavor
@onready var _activities_box:   VBoxContainer = $CenterCard/CardMargin/CardVBox/Activities
@onready var _service_button:   Button = $CenterCard/CardMargin/CardVBox/ServiceButton
@onready var _meeting_button:   Button = $CenterCard/CardMargin/CardVBox/MeetingButton
@onready var _skip_button:      Button = $CenterCard/CardMargin/CardVBox/SkipButton
@onready var _advance_button:   Button = $CenterCard/CardMargin/CardVBox/AdvanceButton
@onready var _schedule_box:     VBoxContainer = $ScheduleCard/ScheduleMargin/ScheduleVBox/ScheduleRows
@onready var _scripture_quote:  Label = $ScheduleCard/ScheduleMargin/ScheduleVBox/ScriptureQuote
@onready var _scripture_ref:    Label = $ScheduleCard/ScheduleMargin/ScheduleVBox/ScriptureRef
@onready var _back_button:      Button = $BackButton


func _ready() -> void:
	_scripture_quote.text = tr(SCRIPTURE_QUOTE)
	_scripture_ref.text = tr(SCRIPTURE_REF)
	_service_button.pressed.connect(_on_service_pressed)
	_meeting_button.pressed.connect(_on_meeting_pressed)
	_skip_button.pressed.connect(_on_skip_pressed)
	_advance_button.pressed.connect(_on_advance_pressed)
	_back_button.pressed.connect(_on_back_pressed)
	SignalBus.phase_changed.connect(_on_phase_changed)
	_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()


# --- Refresh -----------------------------------------------------------------

func _refresh() -> void:
	var phase: int = TimeManager.current_phase
	var content: Dictionary = DAY_CONTENT.get(phase, {})
	_day_title.text = tr("Week %d — %s") % [TimeManager.current_week, TimeManager.current_phase_name()]
	_day_flavor.text = tr(content.get("flavor", ""))
	_rebuild_activities(content.get("activities", []))
	_rebuild_schedule(content.get("schedule", []))
	_service_button.visible = phase in SERVICE_DAY_PHASES
	_meeting_button.visible = phase in MEETING_DAY_PHASES
	_skip_button.visible = phase in MEETING_DAY_PHASES


func _rebuild_activities(activities: Array) -> void:
	for child in _activities_box.get_children():
		child.queue_free()
	for entry in activities:
		_activities_box.add_child(_make_activity_row(entry))


func _make_activity_row(entry: Dictionary) -> Control:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	row.add_child(_make_icon_square(entry.get("icon", "✦"), 48, 22))

	var text_column: VBoxContainer = VBoxContainer.new()
	text_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_column.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	text_column.add_theme_constant_override("separation", 2)

	var name_label: Label = Label.new()
	name_label.text = tr(entry.get("name", ""))
	name_label.add_theme_color_override("font_color", CREAM_TEXT)
	name_label.add_theme_font_size_override("font_size", 18)
	text_column.add_child(name_label)

	var description_label: Label = Label.new()
	description_label.text = tr(entry.get("description", ""))
	description_label.add_theme_color_override("font_color", MUTED_TEXT)
	description_label.add_theme_font_size_override("font_size", 13)
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_column.add_child(description_label)

	row.add_child(text_column)
	return row


func _rebuild_schedule(periods: Array) -> void:
	for child in _schedule_box.get_children():
		child.queue_free()
	for entry in periods:
		_schedule_box.add_child(_make_schedule_row(entry))


func _make_schedule_row(entry: Dictionary) -> Control:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	row.add_child(_make_icon_square(entry.get("icon", "✦"), 36, 16))

	var text_column: VBoxContainer = VBoxContainer.new()
	text_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_column.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	text_column.add_theme_constant_override("separation", 1)

	var period_label: Label = Label.new()
	period_label.text = tr(entry.get("period", ""))
	period_label.add_theme_color_override("font_color", CREAM_TEXT)
	period_label.add_theme_font_size_override("font_size", 14)
	text_column.add_child(period_label)

	var description_label: Label = Label.new()
	description_label.text = tr(entry.get("description", entry.get("title", "")))
	description_label.add_theme_color_override("font_color", MUTED_TEXT)
	description_label.add_theme_font_size_override("font_size", 11)
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_column.add_child(description_label)

	row.add_child(text_column)
	return row


func _make_icon_square(glyph: String, square_size: int, glyph_size: int) -> Panel:
	var panel: Panel = Panel.new()
	panel.custom_minimum_size = Vector2(square_size, square_size)
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = NAVY_DEEP
	sb.border_color = GOLD_BORDER
	sb.set_border_width_all(2)
	sb.corner_radius_top_left = 4
	sb.corner_radius_top_right = 4
	sb.corner_radius_bottom_left = 4
	sb.corner_radius_bottom_right = 4
	panel.add_theme_stylebox_override("panel", sb)

	var glyph_label: Label = Label.new()
	glyph_label.text = glyph
	glyph_label.anchor_right = 1.0
	glyph_label.anchor_bottom = 1.0
	glyph_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	glyph_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	glyph_label.add_theme_color_override("font_color", Color(0.78, 0.62, 0.28, 1))
	glyph_label.add_theme_font_size_override("font_size", glyph_size)
	glyph_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(glyph_label)
	return panel


# --- Actions -----------------------------------------------------------------

func _on_service_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/territory_map.tscn")


func _on_meeting_pressed() -> void:
	var meeting_type: StringName = MeetingManager.meeting_type_for_phase(TimeManager.current_phase)
	if meeting_type == &"":
		return
	MeetingManager.set_pending_meeting(meeting_type)
	get_tree().change_scene_to_file("res://scenes/meeting_hall.tscn")


func _on_skip_pressed() -> void:
	var meeting_type: StringName = MeetingManager.meeting_type_for_phase(TimeManager.current_phase)
	if meeting_type == &"":
		return
	MeetingManager.resolve_meeting_skipped(meeting_type)
	TimeManager.advance_phase()


func _on_advance_pressed() -> void:
	TimeManager.advance_phase()


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _on_phase_changed(_phase: int) -> void:
	_refresh()
