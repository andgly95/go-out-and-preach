extends Control
## Month end: the field service report slip, then a conversation with an
## elder whose tone follows GameState.month_verdict(). When the conversation
## ends, GameState.close_month() files the month and picks the next scene
## (the next week, or the ending after the last month).

const TIMELINE_DIR: String = "res://data/dialogues/month/"

@onready var _card: PanelContainer = $Card
@onready var _title: Label = $Card/Margin/VBox/Title
@onready var _body: Label = $Card/Margin/VBox/Body
@onready var _rows: VBoxContainer = $Card/Margin/VBox/Rows
@onready var _continue: Button = $Card/Margin/VBox/Continue

var _finished: bool = false


func _ready() -> void:
	var month: Dictionary = GameState.month
	_title.text = tr("Field Service Report")
	_body.text = tr("Month %d. Fill it in before the meeting.") % int(month.get("month", 1))
	_add_row(tr("Name"), GameState.formal_name())
	_add_row(tr("Hours"), "%.1f" % ResourceManager.field_service_hours)
	_add_row(tr("Placements"), str(int(month.get("placements", 0))))
	_add_row(tr("Return visits"), str(int(month.get("return_visits", 0))))
	_add_row(tr("Bible studies"), str(int(month.get("study_sessions", 0))))
	if month.get("aux_pioneer", false):
		_add_row(tr("Auxiliary pioneer"), tr("Yes — %d hour goal") % int(GameState.AUX_PIONEER_HOURS))
	_continue.pressed.connect(_on_hand_in_pressed)


func _add_row(label: String, value: String) -> void:
	var row: HBoxContainer = HBoxContainer.new()
	var left: Label = Label.new()
	left.text = label
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_color_override("font_color", Color(0.82, 0.76, 0.62, 1))
	left.add_theme_font_size_override("font_size", 16)
	row.add_child(left)
	var right: Label = Label.new()
	right.text = value
	right.add_theme_color_override("font_color", Color(0.96, 0.92, 0.79, 1))
	right.add_theme_font_size_override("font_size", 16)
	row.add_child(right)
	_rows.add_child(row)


func _on_hand_in_pressed() -> void:
	_card.visible = false
	var path: String = "%smonth_%s.dtl" % [TIMELINE_DIR, GameState.month_verdict()]
	if not ResourceLoader.exists(path):
		_finish()
		return
	DialogicResourceUtil.update_directory(".dch")
	DialogicResourceUtil.update_directory(".dtl")
	Dialogic.signal_event.connect(_on_dialogic_signal)
	Dialogic.timeline_ended.connect(_on_timeline_ended)
	Dialogic.start(path)


func _on_dialogic_signal(arg: Variant) -> void:
	if typeof(arg) == TYPE_STRING:
		Evenings.apply_scene_signal(arg)


func _on_timeline_ended() -> void:
	_finish()


func _finish() -> void:
	if _finished:
		return
	_finished = true
	if Dialogic.signal_event.is_connected(_on_dialogic_signal):
		Dialogic.signal_event.disconnect(_on_dialogic_signal)
	if Dialogic.timeline_ended.is_connected(_on_timeline_ended):
		Dialogic.timeline_ended.disconnect(_on_timeline_ended)
	get_tree().change_scene_to_file.call_deferred(GameState.close_month())
