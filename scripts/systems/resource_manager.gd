extends Node
## Visible player meters from GDD § 5.1. Autoloaded as ResourceManager.
## Listens to time signals via SignalBus for energy refill and the monthly
## hours reset. Doubt is intentionally absent — that belongs to M4's
## doubt_meter.gd and must stay isolated from this file.

const STANDING_MIN: int = -100
const STANDING_MAX: int = 100
const CONVICTION_MIN: int = 0
const CONVICTION_MAX: int = 100

# GDD § 5.1 says hours "reset monthly" but never defines month length in
# week-time. Four weeks is a convention until M2/M3 playtest tunes it.
const WEEKS_PER_MONTH: int = 4

var field_service_hours: float = 0.0
var energy: int = 10
var energy_max: int = 10
var standing_elders: int = 0
var standing_congregation: int = 0
var standing_family: int = 0
var conviction: int = 50

var _weeks_since_month_reset: int = 0


func _ready() -> void:
	SignalBus.day_advanced.connect(_on_day_advanced)
	SignalBus.week_advanced.connect(_on_week_advanced)


func set_energy(value: int) -> void:
	energy = clampi(value, 0, energy_max)
	SignalBus.resource_changed.emit("energy", float(energy))


func add_energy(delta: int) -> void:
	set_energy(energy + delta)


func set_hours(value: float) -> void:
	field_service_hours = maxf(value, 0.0)
	SignalBus.resource_changed.emit("field_service_hours", field_service_hours)


func add_hours(delta: float) -> void:
	set_hours(field_service_hours + delta)


func set_standing_elders(value: int) -> void:
	standing_elders = clampi(value, STANDING_MIN, STANDING_MAX)
	SignalBus.resource_changed.emit("standing_elders", float(standing_elders))


func add_standing_elders(delta: int) -> void:
	set_standing_elders(standing_elders + delta)


func set_standing_congregation(value: int) -> void:
	standing_congregation = clampi(value, STANDING_MIN, STANDING_MAX)
	SignalBus.resource_changed.emit("standing_congregation", float(standing_congregation))


func add_standing_congregation(delta: int) -> void:
	set_standing_congregation(standing_congregation + delta)


func set_standing_family(value: int) -> void:
	standing_family = clampi(value, STANDING_MIN, STANDING_MAX)
	SignalBus.resource_changed.emit("standing_family", float(standing_family))


func add_standing_family(delta: int) -> void:
	set_standing_family(standing_family + delta)


func set_conviction(value: int) -> void:
	conviction = clampi(value, CONVICTION_MIN, CONVICTION_MAX)
	SignalBus.resource_changed.emit("conviction", float(conviction))


func add_conviction(delta: int) -> void:
	set_conviction(conviction + delta)


func _on_day_advanced(_phase: int) -> void:
	set_energy(energy_max)


func _on_week_advanced(_week: int) -> void:
	_weeks_since_month_reset += 1
	if _weeks_since_month_reset >= WEEKS_PER_MONTH:
		_weeks_since_month_reset = 0
		set_hours(0.0)
