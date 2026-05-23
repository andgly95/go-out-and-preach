extends CanvasLayer
## Debug-only doubt inspector (M4). Instantiated by door_knock.gd only
## inside `if OS.is_debug_build():`, so it never reaches a production
## build per CLAUDE.md § Common Pitfalls.
##
## Hidden by default even in debug builds — F9 toggles. Debug builds
## should still feel production-like unless the developer asks for the
## panel. Shift+Up / Shift+Down nudge doubt by ±10 to exercise threshold
## transitions without hand-grinding doors.

const DEBUG_NUDGE_DELTA: int = 10

@onready var _value_label: Label = $Panel/Margin/VBox/ValueLabel
@onready var _log_label: RichTextLabel = $Panel/Margin/VBox/LogLabel


func _ready() -> void:
	visible = false
	_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var key_event: InputEventKey = event
	if not key_event.pressed or key_event.echo:
		return
	if key_event.keycode == KEY_F9:
		visible = not visible
		if visible:
			_refresh()
		get_viewport().set_input_as_handled()
		return
	if not visible:
		return
	if not key_event.shift_pressed:
		return
	if key_event.keycode == KEY_UP:
		DoubtMeter.apply(DEBUG_NUDGE_DELTA, &"debug_add")
		_refresh()
		get_viewport().set_input_as_handled()
	elif key_event.keycode == KEY_DOWN:
		DoubtMeter.apply(-DEBUG_NUDGE_DELTA, &"debug_subtract")
		_refresh()
		get_viewport().set_input_as_handled()


func _refresh() -> void:
	_value_label.text = "Doubt: %d / 100" % DoubtMeter.get_value()
	var log: Array = DoubtMeter.get_event_log()
	var lines: PackedStringArray = PackedStringArray()
	# Newest entries first so the most recent change is at the top.
	for i in range(log.size() - 1, -1, -1):
		var entry: Dictionary = log[i]
		var delta: int = entry["delta"]
		var sign_prefix: String = "+" if delta > 0 else ""
		lines.append("%s%d  %s  → %d" % [sign_prefix, delta, entry["reason"], entry["value"]])
	if lines.is_empty():
		_log_label.text = "(no events)"
	else:
		_log_label.text = "\n".join(lines)
