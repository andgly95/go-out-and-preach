extends Node
## Visible player meters from GDD § 5.1. Autoloaded as ResourceManager.
## Sleep restores a fixed amount of energy (not a full refill) and conviction
## drifts down a little each week — faith takes upkeep. Monthly hours are
## cleared by GameState when the month's report is filed. Doubt lives in
## DoubtMeter, deliberately separate.

const STANDING_MIN: int = -100
const STANDING_MAX: int = 100
const CONVICTION_MIN: int = 0
const CONVICTION_MAX: int = 100

const ENERGY_MAX: int = 10
const STARTING_CONVICTION: int = 50
# See docs/design/v01-loop.md § Energy. Three a night means a heavy day
# (long service, meeting, evening out) is still felt the next morning.
const SLEEP_RECOVERY: int = 3
const WEEKLY_CONVICTION_DRIFT: int = -3

var field_service_hours: float = 0.0
var energy: int = ENERGY_MAX
var energy_max: int = ENERGY_MAX
var standing_elders: int = 0
var standing_congregation: int = 0
var standing_family: int = 0
var conviction: int = STARTING_CONVICTION

## Recent changes ({name, delta, msec}) so a freshly loaded top banner can
## still show what the last scene did — most changes land right before a
## scene switch. Trimmed to the last few seconds.
var recent_changes: Array = []
const RECENT_CHANGE_WINDOW_MSEC: int = 2500


func _ready() -> void:
	SignalBus.day_advanced.connect(_on_day_advanced)
	SignalBus.week_advanced.connect(_on_week_advanced)


func reset() -> void:
	recent_changes.clear()
	field_service_hours = 0.0
	energy = ENERGY_MAX
	standing_elders = 0
	standing_congregation = 0
	standing_family = 0
	conviction = STARTING_CONVICTION
	_emit_all()


func to_save() -> Dictionary:
	return {
		"hours": field_service_hours,
		"energy": energy,
		"elders": standing_elders,
		"congregation": standing_congregation,
		"family": standing_family,
		"conviction": conviction,
	}


func from_save(data: Dictionary) -> void:
	field_service_hours = float(data.get("hours", 0.0))
	energy = int(data.get("energy", ENERGY_MAX))
	standing_elders = int(data.get("elders", 0))
	standing_congregation = int(data.get("congregation", 0))
	standing_family = int(data.get("family", 0))
	conviction = int(data.get("conviction", STARTING_CONVICTION))
	_emit_all()


func can_afford(cost: int) -> bool:
	return energy >= cost


## Spends energy if there is enough. Returns false (and spends nothing) if not.
func spend_energy(cost: int) -> bool:
	if not can_afford(cost):
		return false
	add_energy(-cost)
	return true


func add_standing(track: StringName, delta: int) -> void:
	match track:
		&"elders":
			add_standing_elders(delta)
		&"congregation":
			add_standing_congregation(delta)
		&"family":
			add_standing_family(delta)
		_:
			push_warning("[ResourceManager] Unknown standing track %s" % track)


func _record(resource_name: String, delta: float) -> void:
	if is_zero_approx(delta):
		return
	var now: int = Time.get_ticks_msec()
	recent_changes.append({"name": resource_name, "delta": delta, "msec": now})
	while not recent_changes.is_empty() and now - int(recent_changes[0]["msec"]) > RECENT_CHANGE_WINDOW_MSEC:
		recent_changes.pop_front()


## Net change per resource over the last `window_msec`.
func changes_since(window_msec: int) -> Dictionary:
	var now: int = Time.get_ticks_msec()
	var totals: Dictionary = {}
	for change in recent_changes:
		if now - int(change["msec"]) <= window_msec:
			totals[change["name"]] = float(totals.get(change["name"], 0.0)) + float(change["delta"])
	return totals


func _emit_all() -> void:
	SignalBus.resource_changed.emit("field_service_hours", field_service_hours)
	SignalBus.resource_changed.emit("energy", float(energy))
	SignalBus.resource_changed.emit("standing_elders", float(standing_elders))
	SignalBus.resource_changed.emit("standing_congregation", float(standing_congregation))
	SignalBus.resource_changed.emit("standing_family", float(standing_family))
	SignalBus.resource_changed.emit("conviction", float(conviction))


func set_energy(value: int) -> void:
	var previous: float = float(energy)
	energy = clampi(value, 0, energy_max)
	_record("energy", float(energy) - previous)
	SignalBus.resource_changed.emit("energy", float(energy))


func add_energy(delta: int) -> void:
	set_energy(energy + delta)


func set_hours(value: float) -> void:
	var previous: float = float(field_service_hours)
	field_service_hours = maxf(value, 0.0)
	_record("field_service_hours", float(field_service_hours) - previous)
	SignalBus.resource_changed.emit("field_service_hours", field_service_hours)


func add_hours(delta: float) -> void:
	set_hours(field_service_hours + delta)


func set_standing_elders(value: int) -> void:
	var previous: float = float(standing_elders)
	standing_elders = clampi(value, STANDING_MIN, STANDING_MAX)
	_record("standing_elders", float(standing_elders) - previous)
	SignalBus.resource_changed.emit("standing_elders", float(standing_elders))


func add_standing_elders(delta: int) -> void:
	set_standing_elders(standing_elders + delta)


func set_standing_congregation(value: int) -> void:
	var previous: float = float(standing_congregation)
	standing_congregation = clampi(value, STANDING_MIN, STANDING_MAX)
	_record("standing_congregation", float(standing_congregation) - previous)
	SignalBus.resource_changed.emit("standing_congregation", float(standing_congregation))


func add_standing_congregation(delta: int) -> void:
	set_standing_congregation(standing_congregation + delta)


func set_standing_family(value: int) -> void:
	var previous: float = float(standing_family)
	standing_family = clampi(value, STANDING_MIN, STANDING_MAX)
	_record("standing_family", float(standing_family) - previous)
	SignalBus.resource_changed.emit("standing_family", float(standing_family))


## Losses shrink with the "keeps the peace" habit, never past zero.
func add_standing_family(delta: int) -> void:
	if delta < 0:
		delta = mini(0, delta + int(Habits.modifier("family_loss")))
	set_standing_family(standing_family + delta)


func set_conviction(value: int) -> void:
	var previous: float = float(conviction)
	conviction = clampi(value, CONVICTION_MIN, CONVICTION_MAX)
	_record("conviction", float(conviction) - previous)
	SignalBus.resource_changed.emit("conviction", float(conviction))


func add_conviction(delta: int) -> void:
	set_conviction(conviction + delta)


func _on_day_advanced(_phase: int) -> void:
	add_energy(SLEEP_RECOVERY)


func _on_week_advanced(_week: int) -> void:
	add_conviction(WEEKLY_CONVICTION_DRIFT)
