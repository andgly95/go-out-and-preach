extends Control
## Title screen. New Game opens a short setup on the same card (name, how
## the congregation addresses you, which parent is in the Truth — GDD § 7);
## Continue resumes the autosave from the start of the current week.

@onready var new_game_button: Button = $MenuCard/CardMargin/CardVBox/NewGameButton
@onready var continue_button: Button = $MenuCard/CardMargin/CardVBox/ContinueButton
@onready var settings_button: Button = $MenuCard/CardMargin/CardVBox/SettingsButton
@onready var quit_button: Button = $MenuCard/CardMargin/CardVBox/QuitButton
@onready var _card_vbox: VBoxContainer = $MenuCard/CardMargin/CardVBox

const CREAM_TEXT: Color = Color(0.96, 0.92, 0.79, 1)
const MUTED_TEXT: Color = Color(0.82, 0.76, 0.62, 1)

var _setup_box: VBoxContainer = null
var _name_edit: LineEdit = null
var _title_choice: String = "Brother"
var _parent_choice: String = "mother"
var _title_buttons: Dictionary = {}
var _parent_buttons: Dictionary = {}


func _ready() -> void:
	new_game_button.pressed.connect(_on_new_game_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	settings_button.visible = false
	continue_button.disabled = not SaveLoad.has_autosave()
	if SaveLoad.has_autosave():
		continue_button.tooltip_text = SaveLoad.autosave_label()
	else:
		continue_button.modulate = Color(1, 1, 1, 0.45)


func _on_new_game_pressed() -> void:
	_show_setup(true)


func _on_continue_pressed() -> void:
	if SaveLoad.load_autosave():
		get_tree().change_scene_to_file("res://scenes/week_view.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit()


# --- New game setup ----------------------------------------------------------

func _show_setup(show: bool) -> void:
	for button in [new_game_button, continue_button, quit_button]:
		button.visible = not show
	if _setup_box == null:
		_build_setup()
	_setup_box.visible = show
	if show:
		_name_edit.grab_focus()


func _build_setup() -> void:
	_setup_box = VBoxContainer.new()
	_setup_box.add_theme_constant_override("separation", 12)
	_card_vbox.add_child(_setup_box)
	_card_vbox.move_child(_setup_box, quit_button.get_index() + 1)

	_setup_box.add_child(_make_label(tr("Your name"), 17, MUTED_TEXT))
	_name_edit = LineEdit.new()
	_name_edit.text = "Jordan"
	_name_edit.max_length = 20
	_name_edit.custom_minimum_size = Vector2(0, 44)
	_name_edit.add_theme_font_size_override("font_size", 22)
	_name_edit.text_submitted.connect(func(_text: String) -> void: _begin())
	_setup_box.add_child(_name_edit)

	_setup_box.add_child(_make_label(tr("The friends call you"), 17, MUTED_TEXT))
	_setup_box.add_child(_make_choice_row(["Brother", "Sister"], _title_buttons, _on_title_picked))
	_setup_box.add_child(_make_label(tr("Your parent in the Truth"), 17, MUTED_TEXT))
	_setup_box.add_child(_make_choice_row(["mother", "father"], _parent_buttons, _on_parent_picked))
	_on_title_picked(_title_choice)
	_on_parent_picked(_parent_choice)

	var spacer: Control = Control.new()
	spacer.custom_minimum_size = Vector2(0, 6)
	_setup_box.add_child(spacer)
	var begin: Button = _make_menu_button(tr("✦       BEGIN       ✦"))
	begin.pressed.connect(_begin)
	_setup_box.add_child(begin)
	var back: Button = _make_menu_button(tr("BACK"))
	back.custom_minimum_size = Vector2(0, 40)
	back.pressed.connect(_show_setup.bind(false))
	_setup_box.add_child(back)


func _make_choice_row(values: Array, registry: Dictionary, handler: Callable) -> HBoxContainer:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	for value in values:
		var label: String = value
		if value == "mother":
			label = "Mom"
		elif value == "father":
			label = "Dad"
		var button: Button = _make_menu_button(tr(label))
		button.custom_minimum_size = Vector2(0, 44)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.toggle_mode = true
		button.pressed.connect(handler.bind(value))
		registry[value] = button
		row.add_child(button)
	return row


func _make_menu_button(text: String) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 52)
	for style in ["normal", "hover", "pressed"]:
		button.add_theme_stylebox_override(style, new_game_button.get_theme_stylebox(style))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.add_theme_font_size_override("font_size", 20)
	button.add_theme_color_override("font_color", new_game_button.get_theme_color("font_color"))
	button.add_theme_color_override("font_pressed_color", CREAM_TEXT)
	return button


func _make_label(text: String, size: int, color: Color) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label


func _on_title_picked(value: String) -> void:
	_title_choice = value
	_mark_selected(_title_buttons, value)


func _on_parent_picked(value: String) -> void:
	_parent_choice = value
	_mark_selected(_parent_buttons, value)


func _mark_selected(registry: Dictionary, value: String) -> void:
	for key in registry:
		var button: Button = registry[key]
		button.set_pressed_no_signal(key == value)
		button.modulate = Color(1, 1, 1, 1) if key == value else Color(1, 1, 1, 0.55)


func _begin() -> void:
	GameState.new_game(_name_edit.text, _title_choice, _parent_choice)
	SaveLoad.clear_autosave()
	get_tree().change_scene_to_file("res://scenes/week_view.tscn")
