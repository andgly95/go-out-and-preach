extends Control
## The run's ending (GDD § 8): "Five years later", a narrated snapshot chosen
## by GameState.resolve_ending(), then a quiet summary of the run.

const TIMELINE_DIR: String = "res://data/dialogues/endings/"
const MENU_SCENE_PATH: String = "res://scenes/main_menu.tscn"

const ENDING_TITLES: Dictionary = {
	&"regular_pioneer": "The Regular Pioneer",
	&"in_fold": "A Life in the Truth",
	&"keeping_up_appearances": "Keeping Up Appearances",
	&"walking_away": "Walking Away",
	&"quiet_fade": "The Quiet Fade",
}

@onready var _card: PanelContainer = $Card
@onready var _title: Label = $Card/Margin/VBox/Title
@onready var _body: Label = $Card/Margin/VBox/Body
@onready var _rows: VBoxContainer = $Card/Margin/VBox/Rows
@onready var _continue: Button = $Card/Margin/VBox/Continue

var _ending: StringName = &""


func _ready() -> void:
	_ending = GameState.ending_id if GameState.ending_id != &"" else GameState.resolve_ending()
	_continue.pressed.connect(_on_continue_pressed)
	var path: String = "%s%s.dtl" % [TIMELINE_DIR, _ending]
	if not ResourceLoader.exists(path):
		_show_summary()
		return
	_card.visible = false
	Dialogic.timeline_ended.connect(_on_timeline_ended)
	Dialogic.start(path)


func _on_timeline_ended() -> void:
	if Dialogic.timeline_ended.is_connected(_on_timeline_ended):
		Dialogic.timeline_ended.disconnect(_on_timeline_ended)
	_show_summary()


func _show_summary() -> void:
	_card.visible = true
	_title.text = tr(ENDING_TITLES.get(_ending, "Five years later"))
	_body.text = GameState.fill(tr("{title} {name}, eight weeks in the Truth."))
	var hours: float = 0.0
	var attended: int = 0
	var skipped: int = 0
	var conversations: int = 0
	for record in GameState.months:
		hours += float(record.get("hours", 0.0))
		attended += int(record.get("meetings_attended", 0))
		skipped += int(record.get("meetings_skipped", 0))
		conversations += int(record.get("conversations", 0))
	_add_row(tr("Hours in field service"), "%.1f" % hours)
	_add_row(tr("Meetings attended"), "%d of %d" % [attended, attended + skipped])
	_add_row(tr("Conversations at the door"), str(conversations))


func _add_row(label: String, value: String) -> void:
	var row: HBoxContainer = HBoxContainer.new()
	var left: Label = Label.new()
	left.text = label
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_color_override("font_color", Color(0.82, 0.76, 0.62, 1))
	left.add_theme_font_size_override("font_size", 20)
	row.add_child(left)
	var right: Label = Label.new()
	right.text = value
	right.add_theme_color_override("font_color", Color(0.96, 0.92, 0.79, 1))
	right.add_theme_font_size_override("font_size", 20)
	row.add_child(right)
	_rows.add_child(row)


func _on_continue_pressed() -> void:
	get_tree().change_scene_to_file(MENU_SCENE_PATH)
