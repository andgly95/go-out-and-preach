@tool
extends DialogicPortrait
## Placeholder portrait scene shared by all five Curious Seeker
## expressions for M4.1. Real art arrives later. Different expression
## names render distinct tints so portrait swaps are visually
## verifiable without art assets.

const TINT_BY_PORTRAIT: Dictionary = {
	"neutral":            Color(0.55, 0.60, 0.62, 1.0),
	"interested_lean_in": Color(0.65, 0.70, 0.55, 1.0),
	"genuine_question":   Color(0.60, 0.68, 0.72, 1.0),
	"considering":        Color(0.58, 0.55, 0.68, 1.0),
	"warm_thank_you":     Color(0.72, 0.65, 0.55, 1.0),
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
