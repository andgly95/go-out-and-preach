extends RefCounted
class_name UiStyle
## The game's shared look, after Andrew's territory-map concept: slate-blue
## panels framed in gold, EB Garamond throughout (small caps for labels),
## Lucide line icons tinted gold. The default font comes from the project
## theme (ui/themes/main_theme.tres); the frame and button textures are
## drawn by tools/make_ui_textures.py, which uses the same colors.

const SLATE: Color = Color8(40, 54, 72)
const SLATE_DARK: Color = Color8(25, 33, 45)
const GOLD: Color = Color8(190, 154, 88)
const GOLD_LIGHT: Color = Color8(236, 206, 138)
const CREAM: Color = Color8(239, 227, 198)
const MUTED: Color = Color8(203, 189, 156)
const INK: Color = Color8(30, 30, 34)

const FONT_BODY: FontVariation = preload("res://ui/themes/font_body.tres")
const FONT_BOLD: FontVariation = preload("res://ui/themes/font_bold.tres")
const FONT_ITALIC: FontVariation = preload("res://ui/themes/font_italic.tres")
## Title Case renders as classic small caps: "Go Out and Preach".
const FONT_DISPLAY: FontVariation = preload("res://ui/themes/font_display.tres")
## Capitals, lightly tracked: labels, tags and buttons. Labels made by
## label() in this font are set uppercase; button text is written in capitals.
const FONT_CAPS: FontVariation = preload("res://ui/themes/font_caps.tres")

const ICON_DIR: String = "res://ui/icons/"
const THEME_DIR: String = "res://ui/themes/"


# --- Text ------------------------------------------------------------------------

static func label(text: String, font: Font, size: int, color: Color,
		align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l: Label = Label.new()
	l.text = text
	l.horizontal_alignment = align
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.uppercase = font == FONT_CAPS
	style_label(l, font, size, color)
	return l


static func style_label(l: Label, font: Font, size: int, color: Color) -> void:
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)


## A thin gold rule with a diamond in the middle.
static func ornament(width: float = 0.0) -> HBoxContainer:
	var row: HBoxContainer = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if width > 0.0:
		row.custom_minimum_size = Vector2(width, 0)
	for i in 3:
		if i == 1:
			row.add_child(label("◆", FONT_BODY, 11, GOLD))
			continue
		var line: ColorRect = ColorRect.new()
		line.color = Color(GOLD, 0.55)
		line.custom_minimum_size = Vector2(0, 1)
		line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(line)
	return row


# --- Icons -----------------------------------------------------------------------

static func icon(name: String) -> Texture2D:
	return load(ICON_DIR + name + ".svg")


static func icon_rect(name: String, size: float, color: Color) -> TextureRect:
	var rect: TextureRect = TextureRect.new()
	rect.texture = icon(name)
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.custom_minimum_size = Vector2(size, size)
	rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	rect.self_modulate = color
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect


# --- Boxes -----------------------------------------------------------------------

static func texture_box(file: String, margin: float, content: Vector2, draw_center: bool = true) -> StyleBoxTexture:
	var box: StyleBoxTexture = StyleBoxTexture.new()
	box.texture = load(THEME_DIR + file)
	box.set_texture_margin_all(margin)
	box.content_margin_left = content.x
	box.content_margin_right = content.x
	box.content_margin_top = content.y
	box.content_margin_bottom = content.y
	box.draw_center = draw_center
	return box


## Slate panel, double gold rule, corner brackets.
static func panel(content: Vector2 = Vector2(22, 20)) -> StyleBoxTexture:
	return texture_box("panel_frame.png", 20, content)


## The frame around the painted map. Hollow.
static func board() -> StyleBoxTexture:
	return texture_box("board_frame.png", 28, Vector2.ZERO, false)


## Chamfered dark plate for headings that sit on an edge.
static func plate(content: Vector2 = Vector2(26, 6)) -> StyleBoxTexture:
	return texture_box("plate.png", 12, content)


## Recessed row, for counts and list items.
static func inset(content: Vector2 = Vector2(12, 6)) -> StyleBoxTexture:
	return texture_box("inset.png", 8, content)


static func banner() -> StyleBoxTexture:
	var box: StyleBoxTexture = texture_box("banner.png", 4, Vector2.ZERO)
	box.texture_margin_bottom = 10
	return box


## A rounded status tag in a flat color.
static func pill(color: Color, content: Vector2 = Vector2(10, 3)) -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = color
	box.border_color = color.lightened(0.28)
	box.set_border_width_all(1)
	box.set_corner_radius_all(5)
	box.shadow_color = Color(0, 0, 0, 0.35)
	box.shadow_size = 2
	box.shadow_offset = Vector2(0, 1)
	box.content_margin_left = content.x
	box.content_margin_right = content.x
	box.content_margin_top = content.y
	box.content_margin_bottom = content.y
	return box


# --- Buttons ---------------------------------------------------------------------

## The primary action: bevelled gold, dark small caps.
static func gold_button(button: Button, size: int = 22) -> void:
	var normal: StyleBoxTexture = texture_box("button_gold.png", 12, Vector2(22, 8))
	var hover: StyleBoxTexture = texture_box("button_gold_hover.png", 12, Vector2(22, 8))
	_apply_button(button, normal, hover, FONT_CAPS, size, INK, INK)


## A secondary action: slate with a gold edge, cream small caps.
static func slate_button(button: Button, size: int = 16) -> void:
	var normal: StyleBoxTexture = texture_box("button_slate.png", 8, Vector2(16, 6))
	var hover: StyleBoxTexture = texture_box("button_slate_hover.png", 8, Vector2(16, 6))
	_apply_button(button, normal, hover, FONT_CAPS, size, CREAM, GOLD_LIGHT)


static func _apply_button(button: Button, normal: StyleBox, hover: StyleBox, font: Font, size: int,
		color: Color, hover_color: Color) -> void:
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.add_theme_stylebox_override("disabled", normal)
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.add_theme_font_override("font", font)
	button.add_theme_font_size_override("font_size", size)
	button.add_theme_color_override("font_color", color)
	button.add_theme_color_override("font_hover_color", hover_color)
	button.add_theme_color_override("font_pressed_color", hover_color)
	button.add_theme_color_override("font_disabled_color", Color(color, 0.45))
	button.add_theme_color_override("icon_normal_color", color)
	button.add_theme_color_override("icon_hover_color", hover_color)
	button.add_theme_color_override("icon_pressed_color", hover_color)
	button.add_theme_constant_override("h_separation", 12)
