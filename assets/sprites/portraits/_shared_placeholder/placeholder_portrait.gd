@tool
extends DialogicPortrait
## M4.6 — shared placeholder portrait used by all per-house Polite Refuser
## characters. The character's .dch color drives the rect background, with a
## small per-expression brightness modifier so expression swaps stay
## visually verifiable. Replaces the M3 polite_refuser/ placeholder which
## used per-expression colors and didn't carry character distinctness.
##
## Each PR per-house .dch sets its own color (atheist=grey-blue,
## Jewish=warm tan, Catholic=beige, gay couple=teal, Episcopalian=
## lavender-grey, second atheist=olive) so the 6 PR houses render
## distinct portraits at the door without real art.
##
## Replaced by per-character art in a future polish pass.

const EXPRESSION_BRIGHTNESS: Dictionary = {
	# Polite Refuser expression set (M4.6).
	"neutral":          1.00,
	"polite_smile":     1.12,
	"awkward_pause":    0.85,
	"firm_refusal":     0.72,
	"relief":           1.08,
	# Curious Seeker expression set (M4.6+ CS work; both house04_grief and
	# house09_inquisitive use this placeholder with character-color tinting).
	"interested_lean_in": 1.14,
	"genuine_question":   0.95,
	"considering":        0.88,
	"warm_thank_you":     1.10,
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
	var base: Color = character.color if character != null else Color(0.5, 0.5, 0.5)
	var brightness: float = EXPRESSION_BRIGHTNESS.get(portrait, 1.0)
	_rect.color = Color(base.r * brightness, base.g * brightness, base.b * brightness, 1.0)
	_label.text = portrait if portrait else "(no portrait)"


func _get_covered_rect() -> Rect2:
	return Rect2(Vector2.ZERO, Vector2(240, 360))
