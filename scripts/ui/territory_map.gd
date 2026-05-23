extends Control
## Top-down view of the current territory. Each house is a button; clicking
## one routes through TerritoryManager and loads the door-knock shell.
## Visited houses get a muted tint and an outcome sub-label.

const VISITED_MODULATE: Color = Color(0.55, 0.55, 0.55, 1.0)
const UNVISITED_MODULATE: Color = Color(1.0, 1.0, 1.0, 1.0)

@onready var _grid: GridContainer = $CenterPanel/VBoxContainer/HouseGrid
@onready var _header_label: Label = $CenterPanel/VBoxContainer/HeaderLabel
@onready var _end_button: Button = $EndButton

var _house_buttons: Dictionary = {}  # house_id -> Button


func _ready() -> void:
	_grid.columns = TerritoryManager.GRID_COLS
	_build_grid()
	_refresh_all()
	SignalBus.territory_house_visited.connect(_on_house_visited)
	_end_button.pressed.connect(_on_end_pressed)


func _build_grid() -> void:
	for house in TerritoryManager.current_territory.houses:
		var button: Button = Button.new()
		button.custom_minimum_size = Vector2(140, 100)
		button.toggle_mode = false
		button.pressed.connect(_on_house_pressed.bind(house.id))
		_grid.add_child(button)
		_house_buttons[house.id] = button


func _refresh_all() -> void:
	_header_label.text = tr("Territory: %s") % TerritoryManager.current_territory.display_name
	for house in TerritoryManager.current_territory.houses:
		_refresh_house(house)


func _refresh_house(house: House) -> void:
	var button: Button = _house_buttons.get(house.id)
	if button == null:
		return
	var number: int = house.grid_position.y * TerritoryManager.GRID_COLS + house.grid_position.x + 1
	var label: String = tr("#%d") % number
	if house.last_outcome_label != "":
		label += "\n" + house.last_outcome_label
	button.text = label
	button.modulate = VISITED_MODULATE if house.state != House.State.NOT_VISITED else UNVISITED_MODULATE


func _on_house_pressed(house_id: StringName) -> void:
	TerritoryManager.set_pending_house(house_id)
	get_tree().change_scene_to_file("res://scenes/door_knock.tscn")


func _on_house_visited(house_id: StringName, _outcome: int) -> void:
	var house: House = TerritoryManager.get_house(house_id)
	if house != null:
		_refresh_house(house)


func _on_end_pressed() -> void:
	TimeManager.advance_phase()
	get_tree().change_scene_to_file("res://scenes/week_view.tscn")
