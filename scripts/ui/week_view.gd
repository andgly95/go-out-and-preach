extends Control
## The day screen: what today holds and what it will cost. Each day offers a
## few options — the meeting, field service, an evening activity, rest — as
## rows showing their energy cost; options you can't afford are disabled.
## The right-hand card tracks the month: hours against any pioneer
## commitment, meetings, and standing appointments. Days end through
## GameState.end_day() (sleep, month close, run end).

const SERVICE_DAY_PHASES: Array = [TimeManager.Phase.THURSDAY, TimeManager.Phase.SATURDAY]
const MEETING_DAY_PHASES: Array = [TimeManager.Phase.SUNDAY, TimeManager.Phase.TUESDAY]

const SCRIPTURE_QUOTE: String = "\"Let your light shine before others, so that they may see your good works.\""
const SCRIPTURE_REF:   String = "— MATTHEW 5:16"

# One line of flavor per day. Society of the Truth vocabulary per CLAUDE.md.
const DAY_FLAVOR: Dictionary = {
	TimeManager.Phase.SUNDAY: "The Lord's day at the Hall of Witness. Worship anchors the week.",
	TimeManager.Phase.MONDAY: "A working day. The evening is yours, or it isn't.",
	TimeManager.Phase.TUESDAY: "Midweek strengthens what Sunday started.",
	TimeManager.Phase.WEDNESDAY: "The middle of the week. The pace settles.",
	TimeManager.Phase.THURSDAY: "A weekday morning in the territory, for anyone who can make it.",
	TimeManager.Phase.FRIDAY: "The week's edge. Tomorrow is field service.",
	TimeManager.Phase.SATURDAY: "Field service day. The car group meets at eight.",
}

const PIONEER_FLAVOR: String = "The auxiliary pioneer applications are on the table at the back of the Hall again this month."

const CREAM_TEXT: Color   = Color(0.96, 0.92, 0.79, 1)
const MUTED_TEXT: Color   = Color(0.82, 0.76, 0.62, 1)
const DARK_TEXT: Color    = Color(0.09, 0.11, 0.16, 1)
const DIM_DARK_TEXT: Color = Color(0.2, 0.2, 0.22, 1)
const NAVY_DEEP: Color    = Color(0.09, 0.11, 0.16, 0.95)
const GOLD_BORDER: Color  = Color(0.62, 0.5, 0.27, 0.8)
const GOLD: Color         = Color(0.78, 0.62, 0.28, 1)

@onready var _day_title:        Label = $CenterCard/CardMargin/CardVBox/DayTitle
@onready var _day_flavor:       Label = $CenterCard/CardMargin/CardVBox/DayFlavor
@onready var _options_box:      VBoxContainer = $CenterCard/CardMargin/CardVBox/Activities
@onready var _primary_template: Button = $CenterCard/CardMargin/CardVBox/ServiceButton
@onready var _secondary_template: Button = $CenterCard/CardMargin/CardVBox/AdvanceButton
@onready var _schedule_header:  Label = $ScheduleCard/ScheduleMargin/ScheduleVBox/ScheduleHeader
@onready var _schedule_box:     VBoxContainer = $ScheduleCard/ScheduleMargin/ScheduleVBox/ScheduleRows
@onready var _scripture_quote:  Label = $ScheduleCard/ScheduleMargin/ScheduleVBox/ScriptureQuote
@onready var _scripture_ref:    Label = $ScheduleCard/ScheduleMargin/ScheduleVBox/ScriptureRef
@onready var _back_button:      Button = $BackButton


func _ready() -> void:
	_scripture_quote.text = tr(SCRIPTURE_QUOTE)
	_scripture_ref.text = tr(SCRIPTURE_REF)
	for button_path in ["ServiceButton", "MeetingButton", "SkipButton", "AdvanceButton"]:
		($CenterCard/CardMargin/CardVBox.get_node(button_path) as Button).visible = false
	_back_button.pressed.connect(_on_back_pressed)
	_refresh()
	# Today's story beat, if any, plays first; the scene runner brings the
	# player back here with the day still to choose.
	var beat: StoryBeat = Story.beat_for_today()
	if beat != null:
		Story.play(beat)
		get_tree().change_scene_to_file.call_deferred("res://scenes/evening.tscn")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()


# --- Refresh -------------------------------------------------------------------

func _refresh() -> void:
	var phase: int = TimeManager.current_phase
	_day_title.text = tr("Week %d — %s") % [TimeManager.current_week, TimeManager.current_phase_name()]
	_day_flavor.text = tr(DAY_FLAVOR.get(phase, ""))
	if GameState.pioneer_decision_pending():
		_day_flavor.text = _pioneer_flavor()
	_rebuild_options(_options_for_today())
	_rebuild_month_card()


func _options_for_today() -> Array:
	if GameState.pioneer_decision_pending():
		return _pioneer_options()
	var phase: int = TimeManager.current_phase
	var options: Array = []
	if phase in MEETING_DAY_PHASES:
		var meeting_type: StringName = MeetingManager.meeting_type_for_phase(phase)
		var cost: int = MeetingManager.energy_cost_for(meeting_type)
		options.append({
			"icon": "✦",
			"name": "Attend the meeting",
			"description": "Public Talk, a song, then the Lighthouse Study." if phase == TimeManager.Phase.SUNDAY else "Midweek instruction and ministry training at the Hall.",
			"cost": cost,
			"primary": true,
			"action": _on_attend_pressed.bind(meeting_type),
		})
		options.append({
			"icon": "☾",
			"name": "Stay home",
			"description": "Someone will notice the empty seat.",
			"cost": 0,
			"action": _on_skip_pressed.bind(meeting_type),
		})
		return options
	if phase in SERVICE_DAY_PHASES:
		options.append({
			"icon": "✎",
			"name": "Go out in service",
			"description": "Two hours in the territory. Keep going longer if you can." if phase == TimeManager.Phase.SATURDAY else "A weekday morning with whoever can make it. Two hours.",
			"cost": FieldService.MORNING_ENERGY_COST,
			"primary": phase == TimeManager.Phase.SATURDAY,
			"action": _on_service_pressed,
		})
	for activity in Evenings.available_for(phase):
		options.append({
			"icon": activity.icon,
			"name": _fill(activity.title),
			"description": _fill(activity.description),
			"cost": activity.energy_cost,
			"action": _on_activity_pressed.bind(activity),
		})
	if options.is_empty():
		options.append({"icon": "☾", "name": "Go to bed", "description": "", "cost": 0, "action": _on_bed_pressed})
	return options


func _pioneer_flavor() -> String:
	if GameState.months.is_empty():
		return tr(PIONEER_FLAVOR)
	match GameState.months.back().get("verdict", ""):
		"pioneer_met":
			return tr("The applications are out again. Brother Phillips catches your eye across the Hall and lifts his eyebrows, just slightly.")
		"pioneer_missed":
			return tr("The applications are out again. Last month's is still folded in your Bible, the thirty in your own handwriting.")
		"shepherding":
			return tr("The applications are out again. Brother Whitcomb is standing near the table, talking to no one in particular.")
	return tr(PIONEER_FLAVOR)


func _pioneer_options() -> Array:
	return [
		{
			"icon": "✎",
			"name": "Sign up to auxiliary pioneer",
			"description": "Commit to %d hours of field service this month. The elders will see the application." % int(GameState.AUX_PIONEER_HOURS),
			"cost": 0,
			"primary": true,
			"action": _on_pioneer_decided.bind(true),
		},
		{
			"icon": "☾",
			"name": "Not this month",
			"description": "Nobody will say anything.",
			"cost": 0,
			"action": _on_pioneer_decided.bind(false),
		},
	]


func _fill(text: String) -> String:
	return GameState.fill(tr(text))


# --- Option rows -----------------------------------------------------------------

func _rebuild_options(options: Array) -> void:
	for child in _options_box.get_children():
		child.queue_free()
	for option in options:
		_options_box.add_child(_make_option_row(option))


func _make_option_row(option: Dictionary) -> Button:
	var primary: bool = option.get("primary", false)
	var template: Button = _primary_template if primary else _secondary_template
	var cost: int = int(option.get("cost", 0))
	var affordable: bool = cost <= 0 or ResourceManager.can_afford(cost)
	var button: Button = Button.new()
	button.custom_minimum_size = Vector2(0, 72)
	for style in ["normal", "hover", "pressed"]:
		button.add_theme_stylebox_override(style, template.get_theme_stylebox(style))
	button.add_theme_stylebox_override("disabled", template.get_theme_stylebox("normal"))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.disabled = not affordable
	if not affordable:
		button.modulate = Color(1, 1, 1, 0.5)
	button.pressed.connect(option["action"])

	var margin: MarginContainer = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 18)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(margin)
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(row)
	row.add_child(_make_icon_square(option.get("icon", "✦"), 44, 20))

	var text_column: VBoxContainer = VBoxContainer.new()
	text_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_column.alignment = BoxContainer.ALIGNMENT_CENTER
	text_column.add_theme_constant_override("separation", 2)
	text_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(text_column)
	var name_label: Label = _make_label(tr(option.get("name", "")).to_upper(), 16, DARK_TEXT if primary else CREAM_TEXT)
	text_column.add_child(name_label)
	var description: String = tr(option.get("description", ""))
	if not affordable:
		description = tr("Too tired.") + " " + description
	if not description.is_empty():
		var desc_label: Label = _make_label(description, 13, DIM_DARK_TEXT if primary else MUTED_TEXT)
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text_column.add_child(desc_label)

	var cost_text: String = ""
	if cost > 0:
		cost_text = tr("−%d energy") % cost
	elif cost < 0:
		cost_text = tr("+%d energy") % -cost
	var cost_label: Label = _make_label(cost_text, 13, DARK_TEXT if primary else GOLD)
	cost_label.custom_minimum_size = Vector2(84, 0)
	cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(cost_label)
	return button


func _make_label(text: String, size: int, color: Color) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return label


func _make_icon_square(glyph: String, square_size: int, glyph_size: int) -> Panel:
	var panel: Panel = Panel.new()
	panel.custom_minimum_size = Vector2(square_size, square_size)
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = NAVY_DEEP
	sb.border_color = GOLD_BORDER
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(4)
	panel.add_theme_stylebox_override("panel", sb)
	var glyph_label: Label = _make_label(glyph, glyph_size, GOLD)
	glyph_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	glyph_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	glyph_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	panel.add_child(glyph_label)
	return panel


# --- Month card ------------------------------------------------------------------

func _rebuild_month_card() -> void:
	_schedule_header.text = tr("✦ THIS MONTH ✦")
	for child in _schedule_box.get_children():
		child.queue_free()
	var month: Dictionary = GameState.month
	_add_month_row(tr("Month %d of %d") % [TimeManager.current_month(), GameState.RUN_MONTHS],
		tr("Week %d of %d") % [TimeManager.week_in_month(), TimeManager.WEEKS_PER_MONTH])
	var hours: float = ResourceManager.field_service_hours
	if month.get("aux_pioneer", false):
		var to_go: float = maxf(GameState.AUX_PIONEER_HOURS - hours, 0.0)
		_add_month_row(tr("Hours: %.1f of %d") % [hours, int(GameState.AUX_PIONEER_HOURS)],
			tr("Auxiliary pioneer. %.1f to go.") % to_go if to_go > 0.0 else tr("Auxiliary pioneer. Target met."))
	else:
		_add_month_row(tr("Hours: %.1f") % hours, tr("Publisher."))
	_add_month_row(tr("Meetings"), tr("%d attended · %d missed") % [int(month.get("meetings_attended", 0)), int(month.get("meetings_skipped", 0))])
	var appointments: Array[House] = TerritoryManager.appointments()
	if appointments.is_empty():
		_add_month_row(tr("Appointments"), tr("None yet. Return visits and studies wait for you on the map."))
	else:
		var lines: PackedStringArray = PackedStringArray()
		for house in appointments:
			var kind: String = tr("Study") if house.state == House.State.BIBLE_STUDY_STARTED else tr("Return visit")
			var who: String = house.householder.character_name if house.householder != null and not house.householder.character_name.is_empty() else tr("House %d") % TerritoryManager.house_number_for(house)
			lines.append("%s — %s" % [kind, who])
		_add_month_row(tr("Appointments"), "\n".join(lines))
	_add_month_row(tr("Tonight"), tr("Sleep restores %d energy.") % ResourceManager.SLEEP_RECOVERY)


func _add_month_row(title: String, detail: String) -> void:
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 1)
	column.add_child(_make_label(title, 14, CREAM_TEXT))
	var detail_label: Label = _make_label(detail, 12, MUTED_TEXT)
	detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(detail_label)
	_schedule_box.add_child(column)


# --- Actions -----------------------------------------------------------------------

func _on_pioneer_decided(apply: bool) -> void:
	GameState.decide_pioneer(apply)
	_refresh()


func _on_attend_pressed(meeting_type: StringName) -> void:
	if not MeetingManager.begin_meeting(meeting_type):
		return
	MeetingManager.set_pending_meeting(meeting_type)
	get_tree().change_scene_to_file("res://scenes/meeting_hall.tscn")


func _on_skip_pressed(meeting_type: StringName) -> void:
	MeetingManager.resolve_meeting_skipped(meeting_type)
	_end_day()


func _on_service_pressed() -> void:
	if not FieldService.start_session():
		return
	get_tree().change_scene_to_file("res://scenes/territory_map.tscn")


func _on_activity_pressed(activity: Activity) -> void:
	if not Evenings.can_afford(activity):
		return
	Evenings.choose(activity)
	get_tree().change_scene_to_file("res://scenes/evening.tscn")


func _on_bed_pressed() -> void:
	_end_day()


func _end_day() -> void:
	var next_scene: String = GameState.end_day()
	if next_scene == scene_file_path:
		_refresh()
	else:
		get_tree().change_scene_to_file(next_scene)


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
