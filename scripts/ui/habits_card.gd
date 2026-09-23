extends PanelContainer
class_name HabitsCard
## The habits tree at a glance, on the day screen's left: each track's
## practice toward its next step and the habits it has formed. The button
## asks the day screen to open the full tree (scenes/habits_tree.tscn).

signal open_requested

const GOLD: Color = Color(0.62, 0.5, 0.27, 1)
const BRIGHT_GOLD: Color = Color(0.78, 0.62, 0.28, 1)
const CREAM_TEXT: Color = Color(0.96, 0.92, 0.79, 1)
const MUTED_TEXT: Color = Color(0.82, 0.76, 0.62, 1)

@onready var _rows: VBoxContainer = $Margin/VBox/Rows
@onready var _open_button: Button = $Margin/VBox/OpenButton


func _ready() -> void:
	_open_button.pressed.connect(func() -> void: open_requested.emit())
	refresh()


func refresh() -> void:
	for child in _rows.get_children():
		child.queue_free()
	for info in Habits.TRACKS:
		var track: StringName = info["id"]
		_add_row(tr(info["title"]), pips(Habits.practice_on(track), Habits.milestone(track)),
			_formed_titles(track), Habits.next_step_text(track))
	if Habits.lately_visible():
		_add_row(tr(Habits.LATELY_TITLE), "", _formed_titles(Habits.LATELY_TRACK), "")


func _formed_titles(track: StringName) -> String:
	var names: PackedStringArray = PackedStringArray()
	for habit in Habits.habits_on(track):
		if Habits.has(habit.id):
			names.append(GameState.fill(tr(habit.title)))
	return " · ".join(names)


## "●●●○○": practice toward a milestone.
static func pips(have: int, target: int) -> String:
	var filled: int = clampi(have, 0, target)
	return "●".repeat(filled) + "○".repeat(maxi(target - filled, 0))


func _add_row(title: String, pip_text: String, formed: String, next: String) -> void:
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 1)
	var head: HBoxContainer = HBoxContainer.new()
	var title_label: Label = _make_label(title.to_upper(), 12, CREAM_TEXT)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title_label)
	head.add_child(_make_label(pip_text, 11, BRIGHT_GOLD))
	column.add_child(head)
	for line in [[formed, BRIGHT_GOLD], [next, MUTED_TEXT]]:
		if String(line[0]).is_empty():
			continue
		var label: Label = _make_label(line[0], 12, line[1])
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		column.add_child(label)
	_rows.add_child(column)


func _make_label(text: String, size: int, color: Color) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label
