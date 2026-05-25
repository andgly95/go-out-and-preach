extends Resource
class_name Speaker
## M5 — elder or visiting speaker who delivers a meeting talk. Separate from
## Householder because the role surfaces are different (no door-knock fields,
## no per-archetype doubt overrides; talk pools live on MeetingManager per
## M5 Phase 1 Decision F).

@export var id: StringName
@export var display_name: String = ""

# Cast.md cross-reference label (e.g. "Coordinator of Elders" or "Strict Elder").
# Surfaces in the speaker-panel name plate in meeting_hall.tscn. Distinct from
# display_name (which is the Dialogic speaker tag, typically short).
@export var character_name: String = ""

# Cast.md anchor (e.g. "§ 4.1"). Pure documentation hook for the M5.3 dialogue
# subagent — gives the writer a single line to find the voice profile.
@export var voice_profile_ref: String = ""

# Dialogic character resource (.dch). Untyped to avoid hard-binding the
# Speaker resource to the Dialogic plugin at load time — same pattern as
# Householder.dialogic_character.
@export var dialogic_character: Resource = null
