extends SceneTree
## One-shot bootstrap: constructs the Polite Refuser DialogicCharacter
## resource in code and saves it as a properly-formatted .dch file using
## Dialogic's own ResourceSaver. Run once during M3 setup:
##   godot --headless --script res://tools/bootstrap_polite_refuser_dch.gd
##
## Safe to re-run; overwrites the existing .dch idempotently.
## Delete this file after the .dch is generated and committed.

const OUTPUT_PATH: String = "res://data/dialogues/characters/polite_refuser.dch"
const PORTRAIT_SCENE: String = "res://assets/sprites/portraits/polite_refuser/placeholder_portrait.tscn"
const EXPRESSIONS: Array[String] = [
	"neutral",
	"polite_smile",
	"awkward_pause",
	"firm_refusal",
	"relief",
]


func _initialize() -> void:
	print("[bootstrap] start")
	var character: DialogicCharacter = DialogicCharacter.new()
	character.display_name = "Householder"
	character.color = Color(0.78, 0.74, 0.66, 1.0)
	character.description = "Polite Refuser archetype. M3 placeholder — every door in the default territory uses this character until per-house variants ship."
	character.scale = 1.0
	character.offset = Vector2.ZERO
	character.mirror = false
	character.default_portrait = "neutral"
	character.portraits = {}
	for expression in EXPRESSIONS:
		character.portraits[expression] = {
			"image": "",
			"offset": Vector2.ZERO,
			"scene": PORTRAIT_SCENE,
		}
	character.custom_info = {
		"sound_mood_default": "",
		"sound_moods": {},
		"style": "",
	}
	var err: int = ResourceSaver.save(character, OUTPUT_PATH)
	if err != OK:
		printerr("[bootstrap] ResourceSaver.save failed with err=", err)
	else:
		print("[bootstrap] Wrote ", OUTPUT_PATH)
	quit(0 if err == OK else 1)


func _process(_delta: float) -> bool:
	return true
