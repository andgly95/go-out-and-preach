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

# Per-archetype doubt-delta overrides keyed by outcome string. Empty dict
# uses the global table in door_knock.gd. Hostile Slammer uses this to
# zero out REFUSED — the slam is too brief to land emotionally per
# dialogue-context.md § 6.
@export var doubt_delta_overrides: Dictionary = {}

# M4.6 — voice-category cross-reference into cast.md § 6.x. Sub-archetype
# distinction within an archetype (e.g. PR sub-types: atheist / catholic /
# jewish / gay_couple / episcopalian). Not used at runtime today; gives
# the dialogue subagent a single hook into the voice profile when authoring.
@export var voice_subtype: StringName = &""

# M4.6 — optional display name for STATUS / debug / future portrait labels
# (e.g. "The Patel family"). Empty string allowed. Distinct from
# display_name (which is the Dialogic speaker label, typically "Householder").
@export var character_name: String = ""
