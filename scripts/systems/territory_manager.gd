extends Node
## Owns the player's current field-service territory and the in-memory
## visit state. Autoloaded as TerritoryManager. Door-knock outcomes flow
## through here so resource ticks and signal emission stay in one place.
## No save yet — M7.
##
## M4.1: per-house archetype variety. Distribution is fixed across the
## project (no per-session shuffle) so playtest is stable and Apostate
## placement (M4.3, House #7) carries author intent. Householder resources
## live in data/householders/*.tres; the same loaded Resource is shared
## by every house of an archetype (Householders are stateless templates;
## per-instance state lives on House).

const HOURS_PER_KNOCK: float = 0.25
const GRID_COLS: int = 4
const GRID_ROWS: int = 3
const HOUSE_COUNT: int = GRID_COLS * GRID_ROWS

const HOUSEHOLDER_PATHS: Dictionary = {
	&"polite_refuser":  "res://data/householders/polite_refuser.tres",
	&"hostile_slammer": "res://data/householders/hostile_slammer.tres",
	&"curious_seeker":  "res://data/householders/curious_seeker.tres",
}

# Fixed layout for Maple Street. 4×3 grid, indexed left-to-right then
# top-to-bottom. House #7 is the Apostate slot (M4.3); for M4.1 it uses
# polite_refuser as a placeholder so the slot is reserved without
# changing the mix mid-development.
const DISTRIBUTION: Array[StringName] = [
	&"polite_refuser",   # House #1
	&"hostile_slammer",  # House #2
	&"polite_refuser",   # House #3
	&"curious_seeker",   # House #4
	&"polite_refuser",   # House #5
	&"hostile_slammer",  # House #6
	&"polite_refuser",   # House #7  — Apostate slot (M4.3 placeholder)
	&"polite_refuser",   # House #8
	&"curious_seeker",   # House #9
	&"polite_refuser",   # House #10
	&"hostile_slammer",  # House #11
	&"polite_refuser",   # House #12
]

# Archetype slug used as the fallback when a .tres fails to load. Picked
# because every territory in M4.1 has at least one polite_refuser already
# so the fallback resource is guaranteed to be loaded.
const FALLBACK_ARCHETYPE: StringName = &"polite_refuser"

var current_territory: Territory
var _pending_house_id: StringName = &""


func _ready() -> void:
	current_territory = _build_default_territory()


func _build_default_territory() -> Territory:
	var territory: Territory = Territory.new()
	territory.id = &"territory_default"
	territory.display_name = tr("Maple Street")
	var cache: Dictionary = _load_householder_cache()
	for i in HOUSE_COUNT:
		var number: int = i + 1
		var archetype: StringName = DISTRIBUTION[i]
		var householder: Householder = cache.get(archetype, cache.get(FALLBACK_ARCHETYPE))
		var house: House = House.new()
		house.id = StringName("house_%d" % number)
		house.grid_position = Vector2i(i % GRID_COLS, i / GRID_COLS)
		house.householder = householder
		house.state = House.State.NOT_VISITED
		house.last_outcome_label = ""
		territory.houses.append(house)
	return territory


func _load_householder_cache() -> Dictionary:
	# Load each unique archetype .tres exactly once. Householders are
	# stateless templates so sharing across houses is intentional.
	var cache: Dictionary = {}
	for archetype in HOUSEHOLDER_PATHS:
		var path: String = HOUSEHOLDER_PATHS[archetype]
		if not ResourceLoader.exists(path):
			push_warning("[TerritoryManager] Householder .tres missing at %s; archetype %s will fall back." % [path, archetype])
			continue
		var resource: Resource = load(path)
		if resource == null:
			push_warning("[TerritoryManager] Householder .tres at %s failed to load; archetype %s will fall back." % [path, archetype])
			continue
		cache[archetype] = resource
	if not cache.has(FALLBACK_ARCHETYPE):
		# Last-ditch: if the fallback archetype itself didn't load we still
		# need *something* per-house so the territory is navigable. Build a
		# minimal Householder in-code so the game runs and the warning above
		# tells the developer what to fix.
		var minimal: Householder = Householder.new()
		minimal.id = FALLBACK_ARCHETYPE
		minimal.archetype = FALLBACK_ARCHETYPE
		minimal.dialogue_timeline = "res://data/dialogues/polite_refuser_v1.dtl"
		cache[FALLBACK_ARCHETYPE] = minimal
	return cache


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
		House.State.BIBLE_STUDY_STARTED:
			return tr("STUDY STARTED")
	return ""
