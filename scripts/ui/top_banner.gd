extends PanelContainer
## Shared top banner with branding and the six visible meters. Stays in sync
## with ResourceManager through SignalBus.resource_changed, and shows each
## change as a small "+2" / "−1" that fades beside the stat — including
## changes made just before this scene loaded (ResourceManager keeps a short
## log), since most consequences land right before a scene switch.

const DELTA_REPLAY_MSEC: int = 2000
const DELTA_SECONDS: float = 2.2
const DRIFT_PIXELS: float = 12.0
const COLOR_UP: Color = Color(0.62, 0.84, 0.55, 1)
const COLOR_DOWN: Color = Color(0.92, 0.55, 0.48, 1)

@onready var _conviction_value: Label = $BannerMargin/BannerRow/StatRow/ConvictionStat/Value
@onready var _elders_value:     Label = $BannerMargin/BannerRow/StatRow/EldersStat/Value
@onready var _cong_value:       Label = $BannerMargin/BannerRow/StatRow/CongregationStat/Value
@onready var _family_value:     Label = $BannerMargin/BannerRow/StatRow/FamilyStat/Value
@onready var _energy_value:     Label = $BannerMargin/BannerRow/StatRow/EnergyStat/Value
@onready var _hours_value:      Label = $BannerMargin/BannerRow/StatRow/HoursStat/Value

var _labels: Dictionary = {}
var _shown: Dictionary = {}


func _ready() -> void:
	_labels = {
		"conviction": _conviction_value,
		"standing_elders": _elders_value,
		"standing_congregation": _cong_value,
		"standing_family": _family_value,
		"energy": _energy_value,
		"field_service_hours": _hours_value,
	}
	SignalBus.resource_changed.connect(_on_resource_changed)
	_refresh()
	_replay_recent.call_deferred()


func _replay_recent() -> void:
	# Wait for layout so the stat labels have their final positions.
	await get_tree().process_frame
	var recent: Dictionary = ResourceManager.changes_since(DELTA_REPLAY_MSEC)
	for resource_name in recent:
		_show_delta(resource_name, float(recent[resource_name]))


func _refresh() -> void:
	_conviction_value.text = str(ResourceManager.conviction)
	_elders_value.text     = str(ResourceManager.standing_elders)
	_cong_value.text       = str(ResourceManager.standing_congregation)
	_family_value.text     = str(ResourceManager.standing_family)
	_energy_value.text     = "%d / %d" % [ResourceManager.energy, ResourceManager.energy_max]
	_hours_value.text      = "%.1f" % ResourceManager.field_service_hours
	for resource_name in _labels:
		_shown[resource_name] = _current(resource_name)


func _on_resource_changed(resource_name: String, value: float) -> void:
	var before: float = float(_shown.get(resource_name, value))
	_refresh()
	_show_delta(resource_name, value - before)


func _current(resource_name: String) -> float:
	match resource_name:
		"conviction": return float(ResourceManager.conviction)
		"standing_elders": return float(ResourceManager.standing_elders)
		"standing_congregation": return float(ResourceManager.standing_congregation)
		"standing_family": return float(ResourceManager.standing_family)
		"energy": return float(ResourceManager.energy)
		"field_service_hours": return ResourceManager.field_service_hours
	return 0.0


func _show_delta(resource_name: String, delta: float) -> void:
	var anchor: Label = _labels.get(resource_name)
	if anchor == null or is_zero_approx(delta):
		return
	# Hours only ever go up in play; the month-end reset isn't a loss.
	if resource_name == "field_service_hours" and delta < 0.0:
		return
	var label: Label = Label.new()
	var magnitude: String = ("%.2f" % absf(delta)).rstrip("0").rstrip(".") if resource_name == "field_service_hours" else str(int(absf(delta)))
	label.text = ("+" if delta > 0.0 else "−") + magnitude
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", COLOR_UP if delta > 0.0 else COLOR_DOWN)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.top_level = true
	add_child(label)
	# Centered just under the value, drifting down out of the banner.
	var rect: Rect2 = anchor.get_global_rect()
	var width: float = label.get_minimum_size().x
	label.global_position = Vector2(rect.get_center().x - width * 0.5, rect.end.y + 2.0)
	var tween: Tween = label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "global_position:y", label.global_position.y + DRIFT_PIXELS, DELTA_SECONDS)
	tween.tween_property(label, "modulate:a", 0.0, DELTA_SECONDS).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(label.queue_free)
