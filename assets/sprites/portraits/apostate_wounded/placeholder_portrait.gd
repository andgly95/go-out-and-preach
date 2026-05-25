@tool
extends DialogicPortrait
## Placeholder portrait scene shared by all five Apostate (Wounded) variant
## expressions for M4.3. Real art arrives later. Different expression names
## render distinct tints so portrait swaps are visually verifiable without
## art assets. Palette skews cooler than PR/CS to read as a different person.

const TINT_BY_PORTRAIT: Dictionary = {
	"tired":               Color(0.50, 0.55, 0.60, 1.0),
	"recognition":         Color(0.55, 0.58, 0.62, 1.0),
	"grief":               Color(0.45, 0.48, 0.58, 1.0),
	"quiet_resignation":   Color(0.52, 0.52, 0.50, 1.0),
	"wounded_acceptance":  Color(0.58, 0.55, 0.50, 1.0),
}

@onready var _rect: ColorRect = $Rect
@onready var _label: Label = $Rect/Label


func _update_portrait(passed_character: DialogicCharacter, passed_portrait: String) -> void:
	apply_character_and_portrait(passed_character, passed_portrait)
	_refresh()


func _should_do_portrait_update(_character: DialogicCharacter, _portrait: String) -> bool:
	return true


func _refresh() -> void:
	if _rect == null or _label == null:
		return
	_rect.color = TINT_BY_PORTRAIT.get(portrait, Color(0.5, 0.5, 0.5, 1.0))
	_label.text = portrait if portrait else "(no portrait)"


func _get_covered_rect() -> Rect2:
	return Rect2(Vector2.ZERO, Vector2(240, 360))
