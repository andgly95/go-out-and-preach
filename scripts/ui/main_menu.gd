extends Control
## Main menu controller. Buttons are placeholders for M0 — real wiring lands in
## later milestones (New Game → M1 week view, Continue → M7 save/load, Settings → M7).

@onready var new_game_button: Button = $MenuCard/CardMargin/CardVBox/NewGameButton
@onready var continue_button: Button = $MenuCard/CardMargin/CardVBox/ContinueButton
@onready var settings_button: Button = $MenuCard/CardMargin/CardVBox/SettingsButton
@onready var quit_button: Button = $MenuCard/CardMargin/CardVBox/QuitButton


func _ready() -> void:
	new_game_button.pressed.connect(_on_new_game_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)


func _on_new_game_pressed() -> void:
	print("[main_menu] New Game pressed — loading week_view")
	get_tree().change_scene_to_file("res://scenes/week_view.tscn")


func _on_continue_pressed() -> void:
	print("[main_menu] Continue pressed")


func _on_settings_pressed() -> void:
	print("[main_menu] Settings pressed")


func _on_quit_pressed() -> void:
	get_tree().quit()
