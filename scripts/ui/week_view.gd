extends Control
## Default scene after New Game. Shows the week, the day, and the day's
## stubbed activities, with a button to advance the clock. Real action
## buttons (door-knock, meetings, home, journal) replace the activity list
## in later milestones.

# Phase int -> list of activity label keys (run through tr() at display time).
# Ints match TimeManager.Phase enum order: SUN=0, MON=1, ..., SAT=6.
const ACTIVITIES_BY_PHASE: Dictionary = {
	0: ["Public Talk", "Lighthouse Study"],
	1: ["Personal time", "Secular work"],
	2: ["Midweek Meeting"],
	3: ["Personal time"],
	4: ["Service prep", "Return visit prep"],
	5: ["Personal time"],
	6: ["Field Service"],
}

@onready var _header_label: Label = $VBoxContainer/HeaderLabel
@onready var _activities_label: RichTextLabel = $VBoxContainer/ActivitiesLabel
@onready var _service_button: Button = $VBoxContainer/ServiceButton
@onready var _advance_button: Button = $VBoxContainer/AdvanceButton
@onready var _back_button: Button = $BackButton


func _ready() -> void:
	SignalBus.phase_changed.connect(_on_phase_changed)
	_service_button.pressed.connect(_on_service_pressed)
	_advance_button.pressed.connect(_on_advance_pressed)
	_back_button.pressed.connect(_on_back_pressed)
	_refresh()


func _refresh() -> void:
	_header_label.text = tr("Week %d — %s") % [
		TimeManager.current_week,
		TimeManager.current_phase_name(),
	]
	var activities: Array = ACTIVITIES_BY_PHASE.get(TimeManager.current_phase, [])
	var bullets: PackedStringArray = PackedStringArray()
	for activity_key in activities:
		bullets.append("• " + tr(activity_key))
	_activities_label.text = "\n".join(bullets)
	_service_button.visible = _is_field_service_day(TimeManager.current_phase)


func _is_field_service_day(phase: int) -> bool:
	return phase == TimeManager.Phase.THURSDAY or phase == TimeManager.Phase.SATURDAY


func _on_phase_changed(_phase: int) -> void:
	_refresh()


func _on_service_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/territory_map.tscn")


func _on_advance_pressed() -> void:
	TimeManager.advance_phase()


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
