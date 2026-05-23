extends Resource
class_name Householder
## Person behind a door. M3 layers archetype, dialogue timeline reference,
## and a Dialogic character resource onto the M2 id + display_name stub.

@export var id: StringName
@export var display_name: String = ""

# Archetype slug, e.g. &"polite_refuser". Drives which dialogue file plays
# at the door and (later) which doubt-event tables apply.
@export var archetype: StringName = &""

# Path to the Dialogic timeline (.dtl) for this householder's conversation.
@export var dialogue_timeline: String = ""

# Dialogic character resource (.dch). Untyped to avoid hard-binding the
# Householder resource to the Dialogic plugin at load time — if the plugin
# is uninstalled, the .tres still loads.
@export var dialogic_character: Resource = null
