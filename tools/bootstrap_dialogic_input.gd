extends SceneTree
## One-shot bootstrap: registers Dialogic's default input action
## ("dialogic_default_action") into project.godot.
##
## Normally Dialogic's plugin.gd does this in `_enable_plugin()`, which
## fires once when the plugin is first toggled on in the editor UI.
## Since we enabled the plugin by editing project.godot directly, that
## callback never ran. This script reproduces the same setup.
##
## Run:  godot --headless --script res://tools/bootstrap_dialogic_input.gd
##
## Safe to re-run; bails out if the action already exists.

const ACTION_NAME: String = "dialogic_default_action"


func _initialize() -> void:
	if ProjectSettings.has_setting("input/" + ACTION_NAME):
		print("[bootstrap] input/", ACTION_NAME, " already exists; nothing to do.")
		quit(0)
		return

	var input_enter: InputEventKey = InputEventKey.new()
	input_enter.keycode = KEY_ENTER
	var input_left_click: InputEventMouseButton = InputEventMouseButton.new()
	input_left_click.button_index = MOUSE_BUTTON_LEFT
	input_left_click.pressed = true
	input_left_click.device = -1
	var input_space: InputEventKey = InputEventKey.new()
	input_space.keycode = KEY_SPACE
	var input_x: InputEventKey = InputEventKey.new()
	input_x.keycode = KEY_X
	var input_controller: InputEventJoypadButton = InputEventJoypadButton.new()
	input_controller.button_index = JOY_BUTTON_A

	ProjectSettings.set_setting("input/" + ACTION_NAME, {
		"deadzone": 0.5,
		"events": [input_enter, input_left_click, input_space, input_x, input_controller],
	})

	var err: int = ProjectSettings.save()
	if err != OK:
		printerr("[bootstrap] ProjectSettings.save() failed with err=", err)
		quit(1)
		return
	print("[bootstrap] Registered input/", ACTION_NAME, " and saved project.godot.")
	quit(0)


func _process(_delta: float) -> bool:
	return true
