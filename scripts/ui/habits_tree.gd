extends Control
class_name HabitsTree
## The whole habits tree, over the day screen (Habits autoload;
## docs/design/v01-loop.md § Habits). Each track is a row read left to
## right: what feeds it, the habit that forms by itself, then the fork. The
## lately row appears only once something on it has formed.
##
## Opens three ways: from the day screen's card; by itself when a fork is
## waiting (the player keeps one side, and can't close the tree until they
## have); or as a small card for one habit that just formed. Emits `closed`
## when dismissed, so the day screen can show the next pending thing and
## refresh its costs.

signal closed

enum NodeState { FORMED, KEPT, CHOOSABLE, CLOSED, LOCKED }

const PANEL_SIZE: Vector2 = Vector2(1560, 880)
const NOTICE_WIDTH: float = 640.0
const INFO_WIDTH: float = 250.0
const STEP_ONE_WIDTH: float = 380.0
const CONNECTOR_WIDTH: float = 64.0
const ROW_HEIGHT: float = 140.0

const NODE_BG: Color = Color(0.13, 0.16, 0.22, 1)
const NODE_BG_FORMED: Color = Color(0.18, 0.18, 0.2, 1)
const NODE_BG_HOVER: Color = Color(0.21, 0.23, 0.3, 1)
const GOLD: Color = Color(0.62, 0.5, 0.27, 1)
const BRIGHT_GOLD: Color = Color(0.78, 0.62, 0.28, 1)
const CREAM_TEXT: Color = Color(0.96, 0.92, 0.79, 1)
const MUTED_TEXT: Color = Color(0.82, 0.76, 0.62, 1)
const LOCKED_ALPHA: float = 0.55
const CLOSED_ALPHA: float = 0.3

const SUBTITLE_BROWSE: String = "Habits form from what you do with your days. At each fork, you keep one."
const SUBTITLE_CHOOSE: String = "A fork in %s. Keep one; the other closes for the rest of this run."
const SUBTITLE_KEPT: String = "Kept: %s."

var _kept: StringName = &""
var _center: CenterContainer = null


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	var dim: ColorRect = ColorRect.new()
	dim.color = Color(0.03, 0.04, 0.06, 0.82)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	_center = CenterContainer.new()
	_center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_center)


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


func open_tree() -> void:
	_kept = &""
	_build_tree()
	visible = true


func open_notice(habit: Habit) -> void:
	_build_notice(habit)
	visible = true


## Closes unless a fork is still waiting for a choice.
func close() -> void:
	if not visible or not Habits.choices_pending.is_empty():
		return
	visible = false
	_clear()
	closed.emit()


func _clear() -> void:
	for child in _center.get_children():
		child.queue_free()


func _fill(text: String) -> String:
	return GameState.fill(tr(text))


# --- The tree ------------------------------------------------------------------

func _build_tree() -> void:
	_clear()
	var panel: PanelContainer = _make_panel()
	panel.custom_minimum_size = PANEL_SIZE
	_center.add_child(panel)
	var margin: MarginContainer = _make_margin(36, 24)
	panel.add_child(margin)
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	vbox.add_child(_make_label(tr("✦ HABITS ✦"), 17, GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	vbox.add_child(_make_label(_subtitle(), 21, CREAM_TEXT, HORIZONTAL_ALIGNMENT_CENTER))
	vbox.add_child(_make_divider())
	for info in Habits.TRACKS:
		vbox.add_child(_track_row(info))
	if Habits.lately_visible():
		vbox.add_child(_make_divider())
		vbox.add_child(_lately_row())

	var spacer: Control = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)
	if Habits.choices_pending.is_empty():
		var footer: HBoxContainer = HBoxContainer.new()
		footer.alignment = BoxContainer.ALIGNMENT_END
		footer.add_child(_make_button(tr("Continue") if _kept != &"" else tr("Close"), close))
		vbox.add_child(footer)


func _subtitle() -> String:
	if not Habits.choices_pending.is_empty():
		var info: Dictionary = Habits.track_info(Habits.choices_pending[0])
		return tr(SUBTITLE_CHOOSE) % tr(info.get("title", ""))
	if _kept != &"":
		return tr(SUBTITLE_KEPT) % _fill(Habits.get_habit(_kept).title)
	return tr(SUBTITLE_BROWSE)


func _track_row(info: Dictionary) -> Control:
	var track: StringName = info["id"]
	var row: HBoxContainer = HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, ROW_HEIGHT)
	row.add_theme_constant_override("separation", 0)

	var about: VBoxContainer = VBoxContainer.new()
	about.custom_minimum_size = Vector2(INFO_WIDTH, 0)
	about.alignment = BoxContainer.ALIGNMENT_CENTER
	about.add_theme_constant_override("separation", 4)
	about.add_child(_make_label(tr(info["title"]).to_upper(), 19, CREAM_TEXT))
	about.add_child(_wrapped(_make_label(_fill(info["grows"]), 16, MUTED_TEXT)))
	var have: int = Habits.practice_on(track)
	var target: int = Habits.milestone(track)
	about.add_child(_make_label("%s   %d / %d" % [HabitsCard.pips(have, target), mini(have, target), target], 18, BRIGHT_GOLD))
	var next: String = Habits.next_step_text(track)
	if not next.is_empty():
		about.add_child(_wrapped(_make_label(next, 16, MUTED_TEXT)))
	row.add_child(about)
	row.add_child(_gap(24))

	var first: Array[Habit] = Habits.habits_on(track, 1)
	if not first.is_empty():
		var node: Control = _habit_node(first[0], _state_of(first[0]))
		node.custom_minimum_size.x = STEP_ONE_WIDTH
		node.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(node)

	var fork: Array[Habit] = Habits.habits_on(track, 2)
	if fork.is_empty():
		return row
	var branches: VBoxContainer = VBoxContainer.new()
	branches.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	branches.alignment = BoxContainer.ALIGNMENT_CENTER
	branches.add_theme_constant_override("separation", 8)
	var ends: Array[Control] = []
	var states: Array[int] = []
	for habit in fork:
		var state: int = _state_of(habit)
		var node: Control = _habit_node(habit, state)
		branches.add_child(node)
		ends.append(node)
		states.append(state)
	row.add_child(_connector(ends, states))
	row.add_child(branches)
	return row


func _lately_row() -> Control:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 0)
	var about: VBoxContainer = VBoxContainer.new()
	about.custom_minimum_size = Vector2(INFO_WIDTH, 0)
	about.alignment = BoxContainer.ALIGNMENT_CENTER
	about.add_theme_constant_override("separation", 4)
	about.add_child(_make_label(tr(Habits.LATELY_TITLE).to_upper(), 19, CREAM_TEXT))
	about.add_child(_wrapped(_make_label(tr(Habits.LATELY_NOTE), 16, MUTED_TEXT)))
	row.add_child(about)
	row.add_child(_gap(24))
	var first: bool = true
	for habit in Habits.habits_on(Habits.LATELY_TRACK):
		if not Habits.has(habit.id):
			continue
		if not first:
			row.add_child(_gap(CONNECTOR_WIDTH / 2.0))
		var node: Control = _habit_node(habit, NodeState.FORMED)
		node.custom_minimum_size.x = STEP_ONE_WIDTH
		row.add_child(node)
		first = false
	return row


func _state_of(habit: Habit) -> int:
	if Habits.has(habit.id):
		return NodeState.KEPT if habit.step == 2 else NodeState.FORMED
	if Habits.is_closed(habit.id):
		return NodeState.CLOSED
	if habit.step == 2 and Habits.choices_pending.has(habit.track):
		return NodeState.CHOOSABLE
	return NodeState.LOCKED


## One habit as a card: title and tag, the quiet line, what it does. A
## choosable card carries a flat button over it.
func _habit_node(habit: Habit, state: int) -> Control:
	var card: PanelContainer = PanelContainer.new()
	var formed: bool = state == NodeState.FORMED or state == NodeState.KEPT
	var style: StyleBoxFlat = _node_style(NODE_BG_FORMED if formed else NODE_BG,
		BRIGHT_GOLD if formed or state == NodeState.CHOOSABLE else Color(GOLD, 0.45),
		2 if formed or state == NodeState.CHOOSABLE else 1)
	card.add_theme_stylebox_override("panel", style)
	match state:
		NodeState.LOCKED:
			card.modulate = Color(1, 1, 1, LOCKED_ALPHA)
		NodeState.CLOSED:
			card.modulate = Color(1, 1, 1, CLOSED_ALPHA)

	var margin: MarginContainer = _make_margin(14, 8)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(margin)
	var content: VBoxContainer = VBoxContainer.new()
	content.add_theme_constant_override("separation", 3)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(content)
	var head: HBoxContainer = HBoxContainer.new()
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var title: Label = _make_label(_fill(habit.title), 19, BRIGHT_GOLD if formed else CREAM_TEXT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	head.add_child(_make_label(_tag(habit, state), 13, GOLD))
	content.add_child(head)
	content.add_child(_wrapped(_make_label(_fill(habit.flavor), 16, MUTED_TEXT)))
	content.add_child(_wrapped(_make_label("▸ " + _fill(habit.effect_text), 16, CREAM_TEXT)))

	if state == NodeState.CHOOSABLE:
		var button: Button = Button.new()
		button.flat = true
		button.tooltip_text = _fill(habit.effect_text)
		button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		button.pressed.connect(_on_keep.bind(habit.id))
		button.mouse_entered.connect(func() -> void: style.bg_color = NODE_BG_HOVER)
		button.mouse_exited.connect(func() -> void: style.bg_color = NODE_BG)
		card.add_child(button)
	return card


func _tag(habit: Habit, state: int) -> String:
	match state:
		NodeState.FORMED:
			return tr("FORMED")
		NodeState.KEPT:
			return tr("KEPT")
		NodeState.CHOOSABLE:
			return tr("KEEP THIS")
		NodeState.CLOSED:
			return tr("CLOSED")
	if habit.step == 1:
		return tr("IN %d MORE") % maxi(habit.practice - Habits.practice_on(habit.track), 0)
	return tr("LATER")


## Lines from the step-one card to each side of the fork. The side kept is
## bright, the side closed faint.
func _connector(ends: Array[Control], states: Array[int]) -> Control:
	var lines: Control = Control.new()
	lines.custom_minimum_size = Vector2(CONNECTOR_WIDTH, 0)
	lines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lines.draw.connect(func() -> void:
		var mid_x: float = lines.size.x / 2.0
		var origin_y: float = lines.size.y / 2.0
		lines.draw_line(Vector2(0, origin_y), Vector2(mid_x, origin_y), Color(GOLD, 0.6), 2.0)
		for i in ends.size():
			var end_rect: Rect2 = ends[i].get_global_rect()
			var y: float = end_rect.get_center().y - lines.global_position.y
			var alpha: float = 0.9 if states[i] == NodeState.KEPT else (0.15 if states[i] == NodeState.CLOSED else 0.5)
			var color: Color = Color(BRIGHT_GOLD, alpha)
			lines.draw_line(Vector2(mid_x, origin_y), Vector2(mid_x, y), color, 2.0)
			lines.draw_line(Vector2(mid_x, y), Vector2(lines.size.x, y), color, 2.0))
	for node in ends:
		node.resized.connect(lines.queue_redraw)
	lines.resized.connect(lines.queue_redraw)
	return lines


func _on_keep(id: StringName) -> void:
	Habits.choose(id)
	_kept = id
	_build_tree()


# --- One habit, just formed ------------------------------------------------------

func _build_notice(habit: Habit) -> void:
	_clear()
	var panel: PanelContainer = _make_panel()
	panel.custom_minimum_size = Vector2(NOTICE_WIDTH, 0)
	_center.add_child(panel)
	var margin: MarginContainer = _make_margin(40, 30)
	panel.add_child(margin)
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)
	var kicker: String = tr("LATELY") if habit.track == Habits.LATELY_TRACK else tr("A HABIT HAS FORMED")
	vbox.add_child(_make_label("✦ %s ✦" % kicker, 16, GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	vbox.add_child(_make_label(_fill(habit.title), 32, CREAM_TEXT, HORIZONTAL_ALIGNMENT_CENTER))
	vbox.add_child(_wrapped(_make_label(_fill(habit.flavor), 20, MUTED_TEXT, HORIZONTAL_ALIGNMENT_CENTER)))
	vbox.add_child(_wrapped(_make_label(_fill(habit.effect_text), 18, BRIGHT_GOLD, HORIZONTAL_ALIGNMENT_CENTER)))
	var buttons: HBoxContainer = HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 16)
	buttons.add_child(_make_button(tr("See the whole tree"), open_tree))
	buttons.add_child(_make_button(tr("Continue"), close))
	vbox.add_child(buttons)


# --- Building blocks -------------------------------------------------------------

func _make_panel() -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiStyle.panel(Vector2(4, 4)))
	return panel


func _node_style(bg: Color, border: Color, width: int) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(4)
	return style


func _make_margin(horizontal: int, vertical: int) -> MarginContainer:
	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", horizontal)
	margin.add_theme_constant_override("margin_right", horizontal)
	margin.add_theme_constant_override("margin_top", vertical)
	margin.add_theme_constant_override("margin_bottom", vertical)
	return margin


func _make_label(text: String, size: int, color: Color, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.horizontal_alignment = align
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _wrapped(label: Label) -> Label:
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


func _make_divider() -> HSeparator:
	var divider: HSeparator = HSeparator.new()
	divider.add_theme_color_override("separator", Color(GOLD, 0.35))
	return divider


func _make_button(text: String, action: Callable) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(200, 44)
	button.add_theme_font_size_override("font_size", 19)
	button.pressed.connect(action)
	return button


func _gap(width: float) -> Control:
	var gap: Control = Control.new()
	gap.custom_minimum_size = Vector2(width, 0)
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return gap
