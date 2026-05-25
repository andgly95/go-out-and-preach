extends Resource
class_name House
## One clickable house on a territory map. Holds its own visit state so
## outcomes persist across navigation within a session. M7 adds saving.

enum State {
	NOT_VISITED,
	NOT_HOME,
	REFUSED,
	TRACT_LEFT,
	RETURN_VISIT_SCHEDULED,
	BIBLE_STUDY_STARTED,
}

@export var id: StringName
@export var grid_position: Vector2i
@export var householder: Householder
@export var state: int = State.NOT_VISITED
# Cached display string set when state transitions, so the map doesn't
# re-translate every redraw.
@export var last_outcome_label: String = ""

# M4.6 — character's memory of prior visits. Orthogonal to `state` (which
# is click-state / last outcome and gets reset by service-day / week-rollover
# hooks). arc_state is NEVER reset — the family at this door remembers being
# knocked. .dtl files branch at E0 on this value via Dialogic.VAR.arc_state.
# v1 values: &"first_visit" (default; no prior conversation OR only NOT_HOME),
# &"returning" (any prior terminal outcome). Finer-grained per-outcome values
# deferred to M4.7+.
@export var arc_state: StringName = &"first_visit"

# M4.6+ — best positive outcome ever achieved at this house. Persists across
# the per-day / per-week clickability resets so the territory map can show a
# "you've made progress here" indicator alongside the (resettable) badge.
# Only positive outcomes are tracked here (TRACT_LEFT / RETURN_VISIT_SCHEDULED
# / BIBLE_STUDY_STARTED); REFUSED and NOT_HOME do not upgrade this field.
# Compared via int(state) > int(lifetime_best_outcome) on resolve —
# State enum ordering happens to match the positive-outcome ranking
# (TRACT_LEFT=3 < RV=4 < STUDY=5) so the comparator is monotonic.
@export var lifetime_best_outcome: int = State.NOT_VISITED
