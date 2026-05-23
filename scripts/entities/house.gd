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
