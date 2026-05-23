extends Node
## Owns the player's current field-service territory and the in-memory
## visit state. Autoloaded as TerritoryManager. Door-knock outcomes flow
## through here so resource ticks and signal emission stay in one place.
## No save yet — M7.

const HOURS_PER_KNOCK: float = 0.25
const GRID_COLS: int = 4
const GRID_ROWS: int = 3
const HOUSE_COUNT: int = GRID_COLS * GRID_ROWS

# M3: every house in the default territory uses the Polite Refuser archetype.
# Per-house variants and other archetypes (Curious Seeker, Apostate, etc.)
# arrive in later content milestones.
const POLITE_REFUSER_ARCHETYPE: StringName = &"polite_refuser"
const POLITE_REFUSER_TIMELINE: String = "res://data/dialogues/polite_refuser_v1.dtl"
const POLITE_REFUSER_CHARACTER_PATH: String = "res://data/dialogues/characters/polite_refuser.dch"

var current_territory: Territory
var _pending_house_id: StringName = &""


func _ready() -> void:
	current_territory = _build_default_territory()


func _build_default_territory() -> Territory:
	var territory: Territory = Territory.new()
	territory.id = &"territory_default"
	territory.display_name = tr("Maple Street")
	var polite_refuser_character: Resource = null
	if ResourceLoader.exists(POLITE_REFUSER_CHARACTER_PATH):
		polite_refuser_character = load(POLITE_REFUSER_CHARACTER_PATH)
	else:
		push_warning("[TerritoryManager] Polite Refuser .dch missing at %s; householders will have null dialogic_character. Run tools/bootstrap_polite_refuser_dch.gd to generate it." % POLITE_REFUSER_CHARACTER_PATH)
	for i in HOUSE_COUNT:
		var number: int = i + 1
		var householder: Householder = Householder.new()
		householder.id = StringName("householder_%d" % number)
		householder.display_name = tr("House #%d") % number
		householder.archetype = POLITE_REFUSER_ARCHETYPE
		householder.dialogue_timeline = POLITE_REFUSER_TIMELINE
		householder.dialogic_character = polite_refuser_character
		var house: House = House.new()
		house.id = StringName("house_%d" % number)
		house.grid_position = Vector2i(i % GRID_COLS, i / GRID_COLS)
		house.householder = householder
		house.state = House.State.NOT_VISITED
		house.last_outcome_label = ""
		territory.houses.append(house)
	return territory


func get_house(house_id: StringName) -> House:
	for house in current_territory.houses:
		if house.id == house_id:
			return house
	return null


func set_pending_house(house_id: StringName) -> void:
	_pending_house_id = house_id


func get_pending_house() -> House:
	if _pending_house_id == &"":
		return null
	return get_house(_pending_house_id)


func clear_pending_house() -> void:
	_pending_house_id = &""


func resolve_pending_house(outcome_state: int) -> void:
	var house: House = get_pending_house()
	if house == null:
		push_warning("[TerritoryManager] resolve_pending_house called with no pending house")
		return
	house.state = outcome_state
	house.last_outcome_label = outcome_label(outcome_state)
	ResourceManager.add_hours(HOURS_PER_KNOCK)
	SignalBus.territory_house_visited.emit(house.id, outcome_state)
	clear_pending_house()


func outcome_label(state: int) -> String:
	match state:
		House.State.NOT_VISITED:
			return ""
		House.State.NOT_HOME:
			return tr("NOT HOME")
		House.State.REFUSED:
			return tr("REFUSED")
		House.State.TRACT_LEFT:
			return tr("TRACT LEFT")
		House.State.RETURN_VISIT_SCHEDULED:
			return tr("RETURN VISIT")
	return ""
