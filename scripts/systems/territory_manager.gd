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
##
## M4.6: per-house character IDENTITY for Polite Refuser. PR's 6 houses
## now each load a unique character resource — sub-types (atheist / jewish
## / catholic / gay_couple / episcopalian) are voice categories, not
## randomized per-knock variants. DISTRIBUTION pins each PR slot to a
## specific character. The M4.5 Apostate sub-roll pattern (variant rolled
## per knock) stays in place only for Apostate; PR characters are stable.
## House.arc_state tracks per-character "you've been here before" memory
## and is NEVER reset by the per-day / per-week clickability resets below.

const HOURS_PER_KNOCK: float = 0.25
const GRID_COLS: int = 4
const GRID_ROWS: int = 3
const HOUSE_COUNT: int = GRID_COLS * GRID_ROWS

const HOUSEHOLDER_PATHS: Dictionary = {
	# Polite Refuser — per-house characters (M4.6). Each PR house has a
	# unique character belonging to one of 5 voice sub-types per cast.md
	# § 6.0. Pigeonhole: 5 sub-types across 6 houses → atheist repeats
	# (houses #1 "tired" and #12 "intellectual" — distinct voices, same
	# sub-type per cast.md § 6.0.1).
	&"polite_refuser_house01_atheist":      "res://data/householders/polite_refuser_house01_atheist.tres",
	&"polite_refuser_house03_jewish":       "res://data/householders/polite_refuser_house03_jewish.tres",
	&"polite_refuser_house05_catholic":     "res://data/householders/polite_refuser_house05_catholic.tres",
	&"polite_refuser_house08_gay_couple":   "res://data/householders/polite_refuser_house08_gay_couple.tres",
	&"polite_refuser_house10_episcopalian": "res://data/householders/polite_refuser_house10_episcopalian.tres",
	&"polite_refuser_house12_atheist":      "res://data/householders/polite_refuser_house12_atheist.tres",
	# Curious Seeker — per-house characters (M4.6+). Two CS houses; each
	# pinned to its own character + voice sub-type per cast.md § 6.2.x.
	&"curious_seeker_house04_grief":        "res://data/householders/curious_seeker_house04_grief.tres",
	&"curious_seeker_house09_inquisitive":  "res://data/householders/curious_seeker_house09_inquisitive.tres",
	# Hostile Slammer — still shared template per archetype.
	&"hostile_slammer":                     "res://data/householders/hostile_slammer.tres",
	# Apostate — three variants (M4.4). House #7 sub-rolls between these
	# on each knock via APOSTATE_SUB_WEIGHTS / APOSTATE_SUBTYPE_PATHS.
	&"apostate_wounded":                    "res://data/householders/apostate_wounded.tres",
	&"apostate_hostile":                    "res://data/householders/apostate_hostile.tres",
	&"apostate_gentle":                     "res://data/householders/apostate_gentle.tres",
}

# Fixed layout for Maple Street. 4×3 grid, indexed left-to-right then
# top-to-bottom. House #7 holds the Wounded Apostate (M4.3); the slot was
# reserved at M4.1 with polite_refuser as a placeholder and flipped at M4.3.
# M4.6: PR slots now pin specific characters per cast.md § 6.0 mapping.
const DISTRIBUTION: Array[StringName] = [
	&"polite_refuser_house01_atheist",       # House #1  — atheist (tired)
	&"hostile_slammer",                       # House #2
	&"polite_refuser_house03_jewish",         # House #3  — Jewish (empathy-bar §6.0.3)
	&"curious_seeker_house04_grief",          # House #4  — CS grief (M4.2 canonical)
	&"polite_refuser_house05_catholic",       # House #5  — Catholic (M3 canonical)
	&"hostile_slammer",                       # House #6
	&"apostate_wounded",                      # House #7  — Wounded Apostate (M4.3)
	&"polite_refuser_house08_gay_couple",     # House #8  — gay couple (empathy-bar §6.0.4)
	&"curious_seeker_house09_inquisitive",    # House #9  — CS inquisitive
	&"polite_refuser_house10_episcopalian",   # House #10 — Episcopalian
	&"hostile_slammer",                       # House #11
	&"polite_refuser_house12_atheist",        # House #12 — atheist (intellectual)
]

# Householder slug used as the fallback when a .tres fails to load. The
# M3-validated Catholic-PR content at House #5 is the safest fallback —
# tested dialogue, complete branch coverage, neutral cadence.
const FALLBACK_ARCHETYPE: StringName = &"polite_refuser_house05_catholic"

# M4.5 — §3 per-knock outcome roll. P(answered) = 1 - P(NOT_HOME)
# - P(NO_ANSWER_BUT_HOME) = 1 - 0.70 - 0.035 = 0.265. NO_ANSWER_BUT_HOME
# is folded into NOT_HOME for v1 (encounter-distribution.md §3 + M4.5
# Q1c). Single tunable, refresh after the spike playtest if cadence is off.
const P_ANSWERED: float = 0.265

# §4 Apostate sub-roll weights. Per encounter-distribution.md §4. Weights
# sum to 1.0. M4.4 lands all three variants — House #7 sub-rolls Hostile
# (40%), Wounded (35%), or Gentle (25%) on every knock. Per-knock variety
# is the M4.4 calibration lock (the single Apostate house cycles across
# variants; the M4.5 sub-roll mechanic does this each knock).
const APOSTATE_SUB_WEIGHTS: Dictionary = {
	&"hostile": 0.40,
	&"wounded": 0.35,
	&"gentle": 0.25,
}

const APOSTATE_SUBTYPE_PATHS: Dictionary = {
	&"hostile": "res://data/householders/apostate_hostile.tres",
	&"wounded": "res://data/householders/apostate_wounded.tres",
	&"gentle":  "res://data/householders/apostate_gentle.tres",
}

# Archetypes that trigger the §4 sub-roll on an answered door. Checked
# against house.householder.archetype before scene transition. v1 only
# has Wounded ever assigned via DISTRIBUTION; M4.4 adds Hostile + Gentle
# (which would land here too if DIST starts placing them).
const APOSTATE_ARCHETYPES: Array[StringName] = [
	&"apostate_wounded",
	&"apostate_hostile",
	&"apostate_gentle",
]

# Per-house portrait images. Shared between territory_map (right detail panel
# polaroid on hover) and door_knock (full-screen background when the player
# enters the porch). House numbers without an entry fall back to a placeholder
# at the call site. Add new entries as art lands per house.
const HOUSE_PORTRAIT_PATHS: Dictionary = {
	2: "res://assets/sprites/portraits/houses/house_02.png",
	3: "res://assets/sprites/portraits/houses/house_03.png",
	4: "res://assets/sprites/portraits/houses/house_04.png",
	5: "res://assets/sprites/portraits/houses/house_05.png",
	6: "res://assets/sprites/portraits/houses/house_06.png",
	7: "res://assets/sprites/portraits/houses/house_07.png",
}


func get_house_portrait(number: int) -> Texture2D:
	if not HOUSE_PORTRAIT_PATHS.has(number):
		return null
	var path: String = HOUSE_PORTRAIT_PATHS[number]
	var tex: Texture2D = load(path)
	if tex == null:
		push_warning("[TerritoryManager] House #%d portrait failed to load at %s" % [number, path])
		return null
	return tex


func house_number_for(house: House) -> int:
	if house == null:
		return 0
	return house.grid_position.y * GRID_COLS + house.grid_position.x + 1

var current_territory: Territory
var _pending_house_id: StringName = &""


func _ready() -> void:
	current_territory = _build_default_territory()
	# M4.6 — house clickability resets. arc_state is NEVER touched here;
	# character memory persists across resets.
	SignalBus.phase_changed.connect(_on_phase_changed)
	SignalBus.week_advanced.connect(_on_week_advanced)


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
		# Last-ditch: if the fallback character itself didn't load we still
		# need *something* per-house so the territory is navigable. Build a
		# minimal Householder in-code so the game runs and the warning above
		# tells the developer what to fix. Points at the M3-validated
		# Catholic-PR content (house #5) which is the safest fallback.
		var minimal: Householder = Householder.new()
		minimal.id = FALLBACK_ARCHETYPE
		minimal.archetype = &"polite_refuser"
		minimal.dialogue_timeline = "res://data/dialogues/polite_refuser_house05_catholic_v1.dtl"
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
	# M4.6+ — upgrade the persistent lifetime indicator for positive outcomes
	# only. State enum order makes TRACT_LEFT < RV < STUDY, so int compare is
	# monotonic. REFUSED (2) and NOT_HOME (1) never upgrade the lifetime
	# (they'd be < TRACT_LEFT=3 anyway since lifetime starts at 0 NOT_VISITED).
	if _is_positive_outcome(outcome_state) and outcome_state > house.lifetime_best_outcome:
		house.lifetime_best_outcome = outcome_state
	ResourceManager.add_hours(HOURS_PER_KNOCK)
	SignalBus.territory_house_visited.emit(house.id, outcome_state)
	clear_pending_house()


func _is_positive_outcome(state: int) -> bool:
	return state == House.State.TRACT_LEFT \
		or state == House.State.RETURN_VISIT_SCHEDULED \
		or state == House.State.BIBLE_STUDY_STARTED


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


# --- M4.5 encounter rollers --------------------------------------------------

func roll_door_outcome() -> bool:
	# §3 per-knock roll. True = answered, false = NOT_HOME (which absorbs
	# the folded NO_ANSWER_BUT_HOME mass for v1). Godot 4's global PRNG is
	# auto-randomized on engine boot — no explicit randomize() needed.
	return randf() < P_ANSWERED


func roll_apostate_subtype() -> StringName:
	# §4 sub-roll. Weighted pick across APOSTATE_SUB_WEIGHTS. Returns one
	# of "hostile" / "wounded" / "gentle". v1 maps all three to
	# apostate_wounded.tres via APOSTATE_SUBTYPE_PATHS.
	var r: float = randf()
	var cumulative: float = 0.0
	for variant in APOSTATE_SUB_WEIGHTS:
		cumulative += APOSTATE_SUB_WEIGHTS[variant]
		if r < cumulative:
			return variant
	return &"wounded"  # floating-point drift fallback


func resolve_householder_for_pending_house() -> void:
	# §4 integration point. Called by territory_map._commit_visit on the
	# answered-door path before scene transition. No-op for non-Apostate
	# houses. For Apostate houses, sub-rolls the variant and swaps the
	# house instance's householder reference. M4.4 lands real Hostile +
	# Gentle .tres files and updates APOSTATE_SUBTYPE_PATHS — no call-site
	# changes required.
	var house: House = get_pending_house()
	if house == null or house.householder == null:
		return
	if not APOSTATE_ARCHETYPES.has(house.householder.archetype):
		return
	var variant: StringName = roll_apostate_subtype()
	var path: String = APOSTATE_SUBTYPE_PATHS.get(variant, "")
	if path.is_empty() or not ResourceLoader.exists(path):
		push_warning("[TerritoryManager] Apostate sub-roll path missing for variant %s; keeping current householder." % variant)
		return
	var resource: Resource = load(path)
	if resource == null:
		push_warning("[TerritoryManager] Apostate sub-roll .tres failed to load for variant %s; keeping current householder." % variant)
		return
	house.householder = resource
	print_debug("[M4.5] Apostate sub-roll: %s" % variant)


# --- M4.6 clickability resets -----------------------------------------------
#
# Two reset hooks govern when a house becomes re-clickable. arc_state is
# orthogonal — never reset by either hook, so the character behind the door
# remembers prior visits even after the door's clickability resets.
#
# Rules per the M4.6 plan (Andrew's clarification):
#  - NOT_HOME clears on the next field service day in the SAME week
#    (Thursday NOT_HOME → re-knockable Saturday same week).
#  - All other resolved outcomes (TRACT_LEFT, REFUSED, RV_SCHEDULED,
#    BIBLE_STUDY_STARTED) clear on the Sunday rollover into next week
#    (Thursday TRACT_LEFT stays locked through Saturday, fresh next week).
#  - Per-week reset also catches stragglers in NOT_HOME (week boundary
#    clears everything).
#
# Per-resolved-house re-emit of territory_house_visited with NOT_VISITED
# keeps the territory_map badges in sync without adding a new signal.

# House.State is class_name'd so it parses at const-init time; TimeManager
# is an autoload (no class_name), so its enum is read inline at call time
# below rather than baked into a const here.
const RESOLVED_STATES_FOR_WEEK_RESET: Array[int] = [
	House.State.NOT_HOME,
	House.State.REFUSED,
	House.State.TRACT_LEFT,
	House.State.RETURN_VISIT_SCHEDULED,
	House.State.BIBLE_STUDY_STARTED,
]


func _on_phase_changed(phase: int) -> void:
	# Per-service-day reset. Only NOT_HOME clears here — resolved outcomes
	# wait for the week boundary.
	if phase != TimeManager.Phase.THURSDAY and phase != TimeManager.Phase.SATURDAY:
		return
	if current_territory == null:
		return
	for house in current_territory.houses:
		if house.state == House.State.NOT_HOME:
			_reset_house_to_not_visited(house)


func _on_week_advanced(_new_week: int) -> void:
	# Per-week reset on SUN entry. All resolved clickability state clears;
	# arc_state untouched (character memory persists across the week).
	if current_territory == null:
		return
	for house in current_territory.houses:
		if RESOLVED_STATES_FOR_WEEK_RESET.has(house.state):
			_reset_house_to_not_visited(house)


func _reset_house_to_not_visited(house: House) -> void:
	house.state = House.State.NOT_VISITED
	house.last_outcome_label = ""
	# Re-emit so territory_map badges refresh without a new signal type.
	SignalBus.territory_house_visited.emit(house.id, House.State.NOT_VISITED)


# M4.6 — accessor used by .dtl inline [if] modifiers to branch at E0 on the
# character's arc memory. Mirrors the M3/M4 pattern of `DoubtMeter.value`
# access from Dialogic expressions. Returns the v1 default for safety if no
# pending house is set (e.g. headless boot, scene-edit preview).
#
# Usage in .dtl:
#   [if TerritoryManager.pending_arc_state() == "first_visit"]
#     ... first visit branch ...
#   [else]
#     ... returning branch ...
#   [end]
func pending_arc_state() -> StringName:
	var house: House = get_pending_house()
	if house == null:
		return &"first_visit"
	return house.arc_state
