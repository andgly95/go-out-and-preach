@tool
extends DialogicPortrait
## Placeholder portrait scene shared by all five Polite Refuser
## expressions for M3. Real art arrives post-M3 once the loop gates.
## Different expression names render distinct tints so portrait swaps
## are visually verifiable without art assets.

const TINT_BY_PORTRAIT: Dictionary = {
	"neutral":        Color(0.55, 0.55, 0.58, 1.0),
	"polite_smile":   Color(0.68, 0.60, 0.50, 1.0),
	"awkward_pause":  Color(0.50, 0.46, 0.42, 1.0),
	"firm_refusal":   Color(0.62, 0.42, 0.38, 1.0),
	"relief":         Color(0.58, 0.62, 0.55, 1.0),
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
