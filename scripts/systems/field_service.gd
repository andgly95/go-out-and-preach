extends Node
## A morning of field service (docs/design/v01-loop.md § Field service).
## Autoloaded as FieldService. Owns the session's time budget, rolls whether
## a new door is answered, and applies what each conversation does to hours,
## conviction, and doubt. territory_map and door_knock are views over this;
## the balance simulation drives it directly.

const HOURS_PER_STOP: float = 0.25
const STOPS_PER_MORNING: int = 8
const STOPS_PER_EXTENSION: int = 4
const MORNING_ENERGY_COST: int = 3
const EXTENSION_ENERGY_COST: int = 2
const STOP_COST_NEW_DOOR: int = 1
const STOP_COST_RETURN_VISIT: int = 2
const STOP_COST_STUDY: int = 4
const P_ANSWERED_SATURDAY: float = 0.35
const P_ANSWERED_WEEKDAY: float = 0.25

# What each outcome does. "exposure" is conviction-scaled doubt (see
# DoubtMeter.expose); "relief" is unscaled doubt removed. A householder's
# doubt_delta_overrides replaces the exposure for that archetype — the
# apostates' encounters weigh more, the slammer's refusal weighs nothing.
const OUTCOME_EFFECTS: Dictionary = {
	"REFUSED":                {"exposure": 1.0, "conviction": 0, "relief": 0},
	"TRACT_LEFT":             {"exposure": 0.0, "conviction": 0, "relief": 0},
	"RETURN_VISIT_SCHEDULED": {"exposure": 0.0, "conviction": 1, "relief": 0},
	"BIBLE_STUDY_STARTED":    {"exposure": 0.0, "conviction": 2, "relief": 1},
	"STUDY_CONTINUES":        {"exposure": 0.0, "conviction": 1, "relief": 0},
}

const OUTCOME_STATES: Dictionary = {
	"REFUSED": House.State.REFUSED,
	"TRACT_LEFT": House.State.TRACT_LEFT,
	"RETURN_VISIT_SCHEDULED": House.State.RETURN_VISIT_SCHEDULED,
	"BIBLE_STUDY_STARTED": House.State.BIBLE_STUDY_STARTED,
	"STUDY_CONTINUES": House.State.BIBLE_STUDY_STARTED,
}

# A polite refuser who agreed to a return visit to end the conversation stops
# answering after a couple of them — the car's in the driveway, nobody comes.
const POLITE_REFUSER_ARCHETYPE: StringName = &"polite_refuser"
const POLITE_REFUSER_RETURN_PATIENCE: int = 3

const WALK_AWAY_DOUBT: int = 2
# A morning where nobody opened a door: the quiet walk back to the car.
const CLOSED_DOORS_EXPOSURE: float = 1.0
const CLOSED_DOORS_MIN_STOPS: int = 4

var active: bool = false
var stops_total: int = 0
var stops_used: int = 0
var extensions: int = 0
var tally: Dictionary = {}


func reset() -> void:
	active = false
	stops_total = 0
	stops_used = 0
	extensions = 0
	tally = _empty_tally()


func _ready() -> void:
	reset()


func can_start() -> bool:
	return ResourceManager.can_afford(MORNING_ENERGY_COST)


func start_session() -> bool:
	if active:
		return true
	if not ResourceManager.spend_energy(MORNING_ENERGY_COST):
		return false
	active = true
	stops_total = STOPS_PER_MORNING
	stops_used = 0
	extensions = 0
	tally = _empty_tally()
	return true


func stops_left() -> int:
	return stops_total - stops_used


func minutes_left() -> int:
	return stops_left() * 15


func can_extend() -> bool:
	return active and ResourceManager.can_afford(EXTENSION_ENERGY_COST)


func extend() -> bool:
	if not can_extend():
		return false
	ResourceManager.spend_energy(EXTENSION_ENERGY_COST)
	stops_total += STOPS_PER_EXTENSION
	extensions += 1
	return true


func stop_cost(house: House) -> int:
	match house.state:
		House.State.RETURN_VISIT_SCHEDULED:
			return STOP_COST_RETURN_VISIT
		House.State.BIBLE_STUDY_STARTED:
			return STOP_COST_STUDY
	return STOP_COST_NEW_DOOR


func is_knockable(house: House) -> bool:
	return house.state == House.State.NOT_VISITED or TerritoryManager.is_appointment(house)


func can_visit(house: House) -> bool:
	return active and is_knockable(house) and stops_left() >= stop_cost(house)


func p_answered() -> float:
	if TimeManager.current_phase == TimeManager.Phase.SATURDAY:
		return P_ANSWERED_SATURDAY
	return P_ANSWERED_WEEKDAY


## Spends the stop(s) for this house and logs the time. Returns true if
## someone is home — always true for an appointment.
func knock(house: House) -> bool:
	var cost: int = stop_cost(house)
	stops_used += cost
	ResourceManager.add_hours(cost * HOURS_PER_STOP)
	TerritoryManager.set_pending_house(house.id)
	if house.state == House.State.RETURN_VISIT_SCHEDULED and _stopped_answering(house):
		return false
	if TerritoryManager.is_appointment(house):
		return true
	return randf() < p_answered()


func _stopped_answering(house: House) -> bool:
	return house.householder != null \
		and house.householder.archetype == POLITE_REFUSER_ARCHETYPE \
		and house.visit_count >= POLITE_REFUSER_RETURN_PATIENCE


func resolve_not_home(house: House) -> void:
	TerritoryManager.set_pending_house(house.id)
	TerritoryManager.resolve_pending_house(House.State.NOT_HOME)
	tally["not_home"] += 1


## Applies a conversation's outcome (a Dialogic [signal] arg) to the house
## and the player's meters.
func resolve_outcome(house: House, outcome_key: String) -> void:
	var effects: Dictionary = OUTCOME_EFFECTS.get(outcome_key, {})
	var exposure: float = float(effects.get("exposure", 0.0))
	if house.householder != null and house.householder.doubt_delta_overrides.has(outcome_key):
		exposure = float(house.householder.doubt_delta_overrides[outcome_key])
	DoubtMeter.expose(exposure, StringName("door_" + outcome_key.to_lower()))
	DoubtMeter.apply(-int(effects.get("relief", 0)), &"door_fruitful")
	ResourceManager.add_conviction(int(effects.get("conviction", 0)))
	if outcome_key == "STUDY_CONTINUES":
		house.study_sessions += 1
	house.arc_state = &"returning"
	TerritoryManager.set_pending_house(house.id)
	TerritoryManager.resolve_pending_house(OUTCOME_STATES.get(outcome_key, House.State.REFUSED))
	_count_outcome(house, outcome_key)


func resolve_walk_away(house: House) -> void:
	DoubtMeter.apply(WALK_AWAY_DOUBT, &"walked_away")
	house.arc_state = &"returning"
	TerritoryManager.set_pending_house(house.id)
	TerritoryManager.resolve_pending_house(House.State.REFUSED)
	_count_outcome(house, "REFUSED")


## An off-script choice: the player said something true instead of the
## trained line. The weight is authored per choice in the .dtl.
func resolve_offscript(weight: float) -> void:
	DoubtMeter.expose(weight, &"offscript_choice")
	tally["offscript"] += 1


## Ends the morning. Returns the tally for the after-service report.
func end_session() -> Dictionary:
	if not active:
		return tally
	active = false
	if tally["answered"] == 0 and stops_used >= CLOSED_DOORS_MIN_STOPS:
		DoubtMeter.expose(CLOSED_DOORS_EXPOSURE, &"closed_doors")
	tally["hours"] = stops_used * HOURS_PER_STOP
	var summary: Dictionary = tally.duplicate()
	SignalBus.service_session_ended.emit(summary)
	return summary


func _count_outcome(house: House, outcome_key: String) -> void:
	tally["answered"] += 1
	var key: String = outcome_key.to_lower()
	tally[key] = int(tally.get(key, 0)) + 1
	if house.householder != null and TerritoryManager.APOSTATE_ARCHETYPES.has(house.householder.archetype):
		tally["apostate"] = true


func _empty_tally() -> Dictionary:
	return {
		"answered": 0,
		"not_home": 0,
		"refused": 0,
		"tract_left": 0,
		"return_visit_scheduled": 0,
		"bible_study_started": 0,
		"study_continues": 0,
		"offscript": 0,
		"apostate": false,
		"hours": 0.0,
	}
