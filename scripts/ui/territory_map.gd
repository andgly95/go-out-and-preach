extends Control
## Territory map: a morning of field service. Renders the painted street
## with per-house medallions and badges, shows how much of the morning is
## left, and sends knocks through FieldService (which owns the time budget
## and the answered-door roll). Appointments — return visits and studies —
## persist week to week and cost more time but are always home.
##
## House slot positions are expressed as fractional (x, y, w, h) offsets of
## the painted background so the layout tracks viewport stretch. The grid
## cells in background.png span roughly columns at 9/30/52/74% and rows at
## 9/37/63% — tuned by eye against territory_map_v1.png.

const SLOT_FRACTIONS: Array = [
	# x, y, w, h (each as fraction of CenterMap rect).
	# Eye-tuned against assets/sprites/territory/background.png.
	# Reference anchor: House #3 — x=0.498, the column we treat as
	# "correct" and tune the other three columns around. Per-column
	# delta tightened from 0.220 → 0.205 so the leftmost (#1 / #5 / #9)
	# and rightmost (#4 / #8 / #12) columns pull in toward the center.
	# Row 1 + Row 2 y also pulled up (more aggressively for Row 2) so
	# medallions sit at the actual top of each painted yard instead of
	# drifting down into the sidewalk gap.
	Vector4(0.088, 0.085, 0.205, 0.215),  # Row 0 — #1
	Vector4(0.293, 0.085, 0.205, 0.215),  # Row 0 — #2
	Vector4(0.498, 0.085, 0.205, 0.215),  # Row 0 — #3 (reference)
	Vector4(0.703, 0.085, 0.222, 0.215),  # Row 0 — #4
	Vector4(0.088, 0.340, 0.205, 0.215),  # Row 1 — #5
	Vector4(0.293, 0.340, 0.205, 0.215),  # Row 1 — #6
	Vector4(0.498, 0.340, 0.205, 0.215),  # Row 1 — #7
	Vector4(0.703, 0.340, 0.222, 0.215),  # Row 1 — #8
	Vector4(0.088, 0.600, 0.205, 0.190),  # Row 2 — #9
	Vector4(0.293, 0.600, 0.205, 0.190),  # Row 2 — #10
	Vector4(0.498, 0.600, 0.205, 0.190),  # Row 2 — #11
	Vector4(0.703, 0.600, 0.222, 0.190),  # Row 2 — #12
]

# How each house state shows on its tile and in the legend (Andrew's map
# concept): a pill in the state's color, a line icon, and the tint that
# icon takes in the legend.
const STATUS_LOOK: Dictionary = {
	House.State.TRACT_LEFT:             {"text": "Tract Left",    "icon": "tract",        "pill": Color8(52, 84, 98),    "tint": Color8(128, 176, 196), "note": "We left a tract."},
	House.State.RETURN_VISIT_SCHEDULED: {"text": "Return Visit",  "icon": "return_visit", "pill": Color8(146, 108, 46),  "tint": Color8(226, 182, 100), "note": "Follow up needed."},
	House.State.BIBLE_STUDY_STARTED:    {"text": "Study Started", "icon": "study",        "pill": Color8(60, 94, 58),    "tint": Color8(136, 186, 124), "note": "Bible study in progress."},
	House.State.REFUSED:                {"text": "Refused",       "icon": "refused",      "pill": Color8(120, 46, 38),   "tint": Color8(216, 94, 78),   "note": "Not interested."},
	House.State.NOT_HOME:               {"text": "Not Home",      "icon": "not_home",     "pill": Color8(82, 86, 94),    "tint": Color8(172, 177, 188), "note": "No one answered."},
	House.State.NOT_VISITED:            {"text": "Not Visited",   "icon": "not_visited",  "pill": Color8(226, 214, 184), "tint": Color8(226, 214, 184), "note": "No prior contact."},
}
const LEGEND_ORDER: Array = [
	House.State.TRACT_LEFT, House.State.RETURN_VISIT_SCHEDULED, House.State.BIBLE_STUDY_STARTED,
	House.State.REFUSED, House.State.NOT_HOME, House.State.NOT_VISITED,
]
# Lifetime pip (top-right of a tile): the best that ever happened here.
const PIP_TRACT: Color = Color8(128, 176, 196)
const PIP_RETURN: Color = Color8(226, 182, 100)
const PIP_STUDY: Color = Color8(136, 186, 124)

const SCRIPTURE_QUOTE: String = "\"Let your light shine before others, so that they may see the good works\""
const SCRIPTURE_REF:   String = "— MATTHEW 5:16"

@onready var _slots_root: Control          = $MainRow/CenterMap/HouseSlots
@onready var _map_area:   Control          = $MainRow/CenterMap
@onready var _end_button: Button           = $EndButton
@onready var _back_button: Button          = $BackButton

@onready var _territory_title: Label = $MainRow/LeftInfoCard/LeftMargin/LeftVBox/TerritoryTitle
@onready var _tract_value:  Label = $MainRow/LeftInfoCard/LeftMargin/LeftVBox/ProgressRows/TractRow/Value
@onready var _return_value: Label = $MainRow/LeftInfoCard/LeftMargin/LeftVBox/ProgressRows/ReturnRow/Value
@onready var _study_value:  Label = $MainRow/LeftInfoCard/LeftMargin/LeftVBox/ProgressRows/StudyRow/Value
@onready var _scripture_quote_label: Label = $MainRow/LeftInfoCard/LeftMargin/LeftVBox/ScriptureQuote
@onready var _scripture_ref_label:   Label = $MainRow/LeftInfoCard/LeftMargin/LeftVBox/ScriptureRef

@onready var _detail_header:  Label = $MainRow/RightDetailPanel/RightMargin/RightVBox/HouseHeader
@onready var _detail_polaroid: TextureRect = $MainRow/RightDetailPanel/RightMargin/RightVBox/Polaroid/Image

@onready var _report_dim:    ColorRect      = $AfterServiceDim
@onready var _report_card:   PanelContainer = $AfterServiceCard
@onready var _report_hours:   Label = $AfterServiceCard/Margin/VBox/StatsGrid/HoursValue
@onready var _report_tracts:  Label = $AfterServiceCard/Margin/VBox/StatsGrid/TractValue
@onready var _report_returns: Label = $AfterServiceCard/Margin/VBox/StatsGrid/ReturnValue
@onready var _report_studies: Label = $AfterServiceCard/Margin/VBox/StatsGrid/StudyValue
@onready var _report_refused: Label = $AfterServiceCard/Margin/VBox/StatsGrid/RefusedValue
@onready var _report_nothome: Label = $AfterServiceCard/Margin/VBox/StatsGrid/NotHomeValue
@onready var _report_debrief: Label = $AfterServiceCard/Margin/VBox/Debrief
@onready var _report_inner:   RichTextLabel = $AfterServiceCard/Margin/VBox/InnerVoice
@onready var _report_submit:  Button = $AfterServiceCard/Margin/VBox/SubmitButton
@onready var _detail_caption: Label = $MainRow/RightDetailPanel/RightMargin/RightVBox/StateCaption
@onready var _detail_body:    Label = $MainRow/RightDetailPanel/RightMargin/RightVBox/BodyText
@onready var _legend_rows:    VBoxContainer = $MainRow/RightDetailPanel/RightMargin/RightVBox/LegendRows

# Per-house portrait paths live on TerritoryManager and are shared with
# door_knock (full-screen porch BG). Houses without art fall back to the
# scene's default Polaroid texture (house_painting.png placeholder).

var _default_polaroid_texture: Texture2D = null

var _house_slots: Dictionary = {}                # house_id -> Control (slot root)
var _selected_house_id: StringName = &""
var _hover_house_id:    StringName = &""

# Today's Progress counters. Recomputed from current territory on _ready and
# refreshed via the territory_house_visited signal — see _refresh_progress().
var _tract_left_count: int = 0
var _return_visit_count: int = 0
var _studies_started_count: int = 0
var _refused_count: int = 0
var _not_home_count: int = 0
var _apostate_visited_today: bool = false

var _time_label: Label = null
var _extend_button: Button = null
var _notice_label: Label = null

# Inner-voice gate for the after-service report (matches meeting-hall page-2
# beat at threshold 40).
const REPORT_INNER_VOICE_DOUBT: int = 40

# M4.5 — gate further clicks during the ~1s NOT_HOME beat so racing clicks
# don't stack tweens. Cleared by the tween.finished callback.
var _beat_active: bool = false


func _ready() -> void:
	_scripture_quote_label.text = tr(SCRIPTURE_QUOTE)
	_scripture_ref_label.text = tr(SCRIPTURE_REF)
	_territory_title.text = TerritoryManager.current_territory.display_name
	_default_polaroid_texture = _detail_polaroid.texture
	_apply_skin()
	if not FieldService.active:
		# week_view starts the session (and charges its energy); this covers
		# booting the scene directly during development.
		FieldService.start_session()
	_build_session_panel()
	_report_submit.pressed.connect(_on_report_submit_pressed)
	_build_legend()
	_build_slots()
	# CenterMap doesn't get its final rect until after the first layout pass.
	# Wait one frame, then size the slot positions to the live map area.
	await get_tree().process_frame
	_layout_slots()
	_refresh_all_slots()
	_refresh_progress()
	_show_default_detail()

	SignalBus.territory_house_visited.connect(_on_house_visited)
	SignalBus.resource_changed.connect(_on_resource_changed)
	_end_button.pressed.connect(_on_end_pressed)
	_back_button.pressed.connect(_on_back_pressed)
	_back_button.visible = false
	_map_area.resized.connect(_layout_slots)
	_refresh_session_panel()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not _report_card.visible:
		_on_end_pressed()


# --- Look (Andrew's territory-map concept) ------------------------------------

## The parts of the concept a .tscn can't express on its own: the day strip
## with its icon, ornamented dividers, icon rows, the titled house header,
## the photo's caption strip, and the Esc hint.
func _apply_skin() -> void:
	var left: VBoxContainer = $MainRow/LeftInfoCard/LeftMargin/LeftVBox
	var day_label: Label = left.get_node("DayLabel")
	day_label.text = tr("%s — Field Service") % TimeManager.current_phase_name()
	day_label.uppercase = true
	var strip: PanelContainer = PanelContainer.new()
	var strip_style: StyleBoxFlat = StyleBoxFlat.new()
	strip_style.bg_color = Color(UiStyle.SLATE_DARK, 0.85)
	strip_style.border_color = Color(UiStyle.GOLD, 0.55)
	strip_style.border_width_bottom = 1
	strip_style.content_margin_top = 8
	strip_style.content_margin_bottom = 8
	strip.add_theme_stylebox_override("panel", strip_style)
	var strip_row: HBoxContainer = HBoxContainer.new()
	strip_row.alignment = BoxContainer.ALIGNMENT_CENTER
	strip_row.add_theme_constant_override("separation", 10)
	strip.add_child(strip_row)
	left.add_child(strip)
	left.move_child(strip, day_label.get_index())
	strip_row.add_child(UiStyle.icon_rect("day", 22, UiStyle.GOLD))
	day_label.reparent(strip_row)

	for divider_path in ["MainRow/LeftInfoCard/LeftMargin/LeftVBox/Divider1",
			"MainRow/LeftInfoCard/LeftMargin/LeftVBox/Divider2",
			"MainRow/RightDetailPanel/RightMargin/RightVBox/LegendDivider"]:
		var divider: Control = get_node(divider_path)
		var ornament: HBoxContainer = UiStyle.ornament()
		divider.get_parent().add_child(ornament)
		divider.get_parent().move_child(ornament, divider.get_index())
		divider.visible = false

	var rows: VBoxContainer = left.get_node("ProgressRows")
	for pair in [["TractRow", "tract"], ["ReturnRow", "return_visit"], ["StudyRow", "study"]]:
		var row: HBoxContainer = rows.get_node(pair[0])
		var well: PanelContainer = PanelContainer.new()
		well.add_theme_stylebox_override("panel", UiStyle.inset(Vector2(12, 7)))
		rows.add_child(well)
		rows.move_child(well, row.get_index())
		row.reparent(well)
		row.add_theme_constant_override("separation", 12)
		var icon: TextureRect = UiStyle.icon_rect(pair[1], 24, UiStyle.GOLD)
		row.add_child(icon)
		row.move_child(icon, 0)

	# "— House #11 —": the header between two gold rules.
	var header_row: HBoxContainer = HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 12)
	_detail_header.get_parent().add_child(header_row)
	_detail_header.get_parent().move_child(header_row, _detail_header.get_index())
	for i in 3:
		if i == 1:
			_detail_header.reparent(header_row)
			continue
		var rule: ColorRect = ColorRect.new()
		rule.color = Color(UiStyle.GOLD, 0.6)
		rule.custom_minimum_size = Vector2(0, 1)
		rule.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		rule.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		header_row.add_child(rule)

	# The caption strip belongs to the photo's mat.
	var mat: VBoxContainer = VBoxContainer.new()
	mat.add_theme_constant_override("separation", 6)
	var polaroid: PanelContainer = _detail_polaroid.get_parent()
	polaroid.add_child(mat)
	_detail_polaroid.reparent(mat)
	_detail_caption.reparent(mat)

	var hint: HBoxContainer = HBoxContainer.new()
	hint.add_theme_constant_override("separation", 10)
	hint.anchor_top = 1.0
	hint.anchor_bottom = 1.0
	hint.offset_left = 250.0
	hint.offset_top = -64.0
	hint.offset_bottom = -28.0
	var key: Label = UiStyle.label(tr("Esc"), UiStyle.FONT_CAPS, 15, UiStyle.CREAM, HORIZONTAL_ALIGNMENT_CENTER)
	var key_style: StyleBoxFlat = StyleBoxFlat.new()
	key_style.bg_color = Color(UiStyle.SLATE_DARK, 0.9)
	key_style.border_color = Color(UiStyle.GOLD, 0.6)
	key_style.set_border_width_all(1)
	key_style.set_corner_radius_all(3)
	key_style.content_margin_left = 10
	key_style.content_margin_right = 10
	key_style.content_margin_top = 2
	key_style.content_margin_bottom = 4
	key.add_theme_stylebox_override("normal", key_style)
	hint.add_child(key)
	hint.add_child(UiStyle.label(tr("End the morning"), UiStyle.FONT_BODY, 18, UiStyle.MUTED))
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hint)
	move_child(hint, _end_button.get_index())


# --- Session panel (time left, keep going) -----------------------------------

func _build_session_panel() -> void:
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	var header: HBoxContainer = HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	header.add_child(UiStyle.icon_rect("time", 24, UiStyle.GOLD))
	var header_text: VBoxContainer = VBoxContainer.new()
	header_text.add_theme_constant_override("separation", -6)
	header_text.add_child(UiStyle.label(tr("This Morning"), UiStyle.FONT_CAPS, 15, UiStyle.MUTED))
	_time_label = UiStyle.label("", UiStyle.FONT_BOLD, 30, UiStyle.CREAM)
	header_text.add_child(_time_label)
	header.add_child(header_text)
	box.add_child(header)
	_extend_button = Button.new()
	_extend_button.custom_minimum_size = Vector2(0, 44)
	UiStyle.slate_button(_extend_button, 16)
	_extend_button.pressed.connect(_on_extend_pressed)
	box.add_child(_extend_button)
	_notice_label = UiStyle.label("", UiStyle.FONT_ITALIC, 17, UiStyle.MUTED)
	_notice_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_notice_label)
	var progress_header: Control = $MainRow/LeftInfoCard/LeftMargin/LeftVBox/ProgressHeader
	var vbox: Node = progress_header.get_parent()
	vbox.add_child(box)
	vbox.move_child(box, progress_header.get_index())
	var spacer: Control = Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	vbox.add_child(spacer)
	vbox.move_child(spacer, progress_header.get_index())


@warning_ignore("integer_division")
func _refresh_session_panel() -> void:
	if _time_label == null:
		return
	var minutes: int = FieldService.minutes_left()
	if minutes >= 60:
		_time_label.text = tr("%dh %02dm left") % [minutes / 60, minutes % 60] if minutes % 60 != 0 else tr("%dh left") % (minutes / 60)
	else:
		_time_label.text = tr("%dm left") % minutes
	_extend_button.text = (tr("Keep going  ·  +1 hr  ·  −%d energy") % FieldService.extension_energy_cost()).to_upper()
	_extend_button.disabled = not FieldService.can_extend()
	if not FieldService.can_extend() and FieldService.active:
		_extend_button.text = tr("Too tired to keep going").to_upper()
	if FieldService.stops_left() <= 0:
		_notice_label.text = tr("The group is heading back to the cars.")
	elif TimeManager.current_phase != TimeManager.Phase.SATURDAY:
		_notice_label.text = tr("A weekday morning. Fewer people are home.")
	else:
		_notice_label.text = ""
	for house in TerritoryManager.current_territory.houses:
		_refresh_slot(house)


func _on_extend_pressed() -> void:
	FieldService.extend()
	_refresh_session_panel()


func _on_resource_changed(_resource_name: String, _value: float) -> void:
	_refresh_session_panel()


# --- Slot construction & layout ----------------------------------------------

func _build_slots() -> void:
	for house in TerritoryManager.current_territory.houses:
		var slot: Control = _make_slot(house)
		_slots_root.add_child(slot)
		_house_slots[house.id] = slot


func _make_slot(house: House) -> Control:
	var number: int = house.grid_position.y * TerritoryManager.GRID_COLS + house.grid_position.x + 1

	var root: Control = Control.new()
	root.name = "Slot%d" % number
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	root.set_meta(&"house_id", house.id)
	root.set_meta(&"number", number)

	# Tile frame: a soft dark edge, gold when this tile is selected. Pure
	# decoration — must not intercept mouse events or the root's hover/click
	# handlers below never fire.
	var hit: Panel = Panel.new()
	hit.name = "Hit"
	hit.anchor_right = 1.0
	hit.anchor_bottom = 1.0
	hit.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hit.add_theme_stylebox_override("panel", _make_slot_style(false))
	root.add_child(hit)

	# Numbered medallion at top-center.
	var medallion: Panel = Panel.new()
	medallion.name = "Medallion"
	medallion.custom_minimum_size = Vector2(46, 46)
	medallion.anchor_left = 0.5
	medallion.anchor_right = 0.5
	medallion.offset_left = -23.0
	medallion.offset_right = 23.0
	medallion.offset_top = 4.0
	medallion.offset_bottom = 50.0
	medallion.mouse_filter = Control.MOUSE_FILTER_IGNORE
	medallion.add_theme_stylebox_override("panel", _make_medallion_style())
	root.add_child(medallion)

	var medallion_label: Label = UiStyle.label(str(number), UiStyle.FONT_BOLD, 26, UiStyle.CREAM, HORIZONTAL_ALIGNMENT_CENTER)
	medallion_label.anchor_right = 1.0
	medallion_label.anchor_bottom = 1.0
	medallion_label.offset_top = -2.0
	medallion_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	medallion.add_child(medallion_label)

	# Status pill, centered along the bottom of the tile: icon and label.
	var badge_row: CenterContainer = CenterContainer.new()
	badge_row.name = "BadgeRow"
	badge_row.anchor_right = 1.0
	badge_row.anchor_top = 1.0
	badge_row.anchor_bottom = 1.0
	badge_row.offset_top = -46.0
	badge_row.offset_bottom = -8.0
	badge_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(badge_row)
	var badge: PanelContainer = PanelContainer.new()
	badge.name = "Badge"
	badge.custom_minimum_size = Vector2(150, 0)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge_row.add_child(badge)
	var badge_content: HBoxContainer = HBoxContainer.new()
	badge_content.name = "Row"
	badge_content.alignment = BoxContainer.ALIGNMENT_CENTER
	badge_content.add_theme_constant_override("separation", 8)
	badge_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.add_child(badge_content)
	var badge_icon: TextureRect = UiStyle.icon_rect("not_visited", 20, UiStyle.INK)
	badge_icon.name = "Icon"
	badge_content.add_child(badge_icon)
	var badge_label: Label = UiStyle.label(tr("Not Visited"), UiStyle.FONT_CAPS, 17, UiStyle.INK, HORIZONTAL_ALIGNMENT_CENTER)
	badge_label.name = "Label"
	badge_content.add_child(badge_label)

	# M4.6+ — lifetime indicator pip at top-right of the slot. Visible only
	# when the house has a prior positive outcome (TRACT_LEFT / RV / STUDY).
	# Persists across the weekly clickability reset so the player sees
	# "I've made progress here before" even when the badge shows NOT VISITED.
	var pip: Panel = Panel.new()
	pip.name = "LifetimePip"
	pip.anchor_left = 1.0
	pip.anchor_right = 1.0
	pip.anchor_top = 0.0
	pip.anchor_bottom = 0.0
	pip.offset_left = -24.0
	pip.offset_right = -8.0
	pip.offset_top = 8.0
	pip.offset_bottom = 24.0
	pip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pip.visible = false  # _refresh_slot toggles based on lifetime_best_outcome
	pip.add_theme_stylebox_override("panel", _make_pip_style(PIP_TRACT))
	root.add_child(pip)

	# Top-level click + hover wiring lives on `root` so the medallion and
	# badge can pass mouse through to the same target.
	root.mouse_entered.connect(_on_slot_hover.bind(house.id))
	root.mouse_exited.connect(_on_slot_exit.bind(house.id))
	root.gui_input.connect(_on_slot_gui_input.bind(house.id))

	return root


func _layout_slots() -> void:
	var area_size: Vector2 = _map_area.size
	if area_size.x <= 0.0 or area_size.y <= 0.0:
		return
	for i in TerritoryManager.HOUSE_COUNT:
		var house: House = TerritoryManager.current_territory.houses[i]
		var slot: Control = _house_slots.get(house.id)
		if slot == null:
			continue
		var frac: Vector4 = SLOT_FRACTIONS[i]
		slot.position = Vector2(frac.x * area_size.x, frac.y * area_size.y)
		slot.size     = Vector2(frac.z * area_size.x, frac.w * area_size.y)


# --- Slot visuals ------------------------------------------------------------

func _refresh_all_slots() -> void:
	for house in TerritoryManager.current_territory.houses:
		_refresh_slot(house)


func _refresh_slot(house: House) -> void:
	var slot: Control = _house_slots.get(house.id)
	if slot == null:
		return
	var look: Dictionary = STATUS_LOOK.get(house.state, STATUS_LOOK[House.State.NOT_VISITED])
	var text: String = tr(look["text"])
	if house.state == House.State.BIBLE_STUDY_STARTED:
		text = tr("Study")
	if TerritoryManager.is_appointment(house) and house.householder != null and not house.householder.character_name.is_empty():
		text = "%s · %s" % [text, _short_name(house.householder.character_name)]
	var pill_color: Color = look["pill"]
	var ink: Color = UiStyle.INK if pill_color.get_luminance() > 0.5 else UiStyle.CREAM
	var badge: PanelContainer = slot.get_node("BadgeRow/Badge")
	badge.add_theme_stylebox_override("panel", UiStyle.pill(pill_color, Vector2(12, 3)))
	var badge_label: Label = badge.get_node("Row/Label")
	badge_label.text = text
	badge_label.add_theme_color_override("font_color", ink)
	var badge_icon: TextureRect = badge.get_node("Row/Icon")
	badge_icon.visible = house.state != House.State.NOT_VISITED
	badge_icon.texture = UiStyle.icon(look["icon"])
	badge_icon.self_modulate = ink
	var hit: Panel = slot.get_node("Hit")
	hit.add_theme_stylebox_override("panel", _make_slot_style(house.id == _selected_house_id))
	# M4.6+ — lifetime pip (top-right, persists across resets).
	var pip: Panel = slot.get_node("LifetimePip")
	var pip_color: Variant = _pip_color_for_lifetime(house.lifetime_best_outcome)
	if pip_color == null:
		pip.visible = false
	else:
		pip.visible = true
		pip.add_theme_stylebox_override("panel", _make_pip_style(pip_color))
	# M4.6+ — disabled-click cursor cue. A house with state != NOT_VISITED
	# is locked until the next reset hook fires (next service day for
	# NOT_HOME, next Sunday rollover for resolved outcomes). Hover-select
	# still works (detail panel shows what happened).
	if FieldService.can_visit(house):
		slot.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		slot.modulate = Color(1, 1, 1, 1)
	else:
		slot.mouse_default_cursor_shape = Control.CURSOR_FORBIDDEN
		# Dim houses there's no time left for, so the choice reads at a glance.
		var out_of_time: bool = FieldService.is_knockable(house) and not FieldService.can_visit(house)
		slot.modulate = Color(1, 1, 1, 0.55) if out_of_time else Color(1, 1, 1, 1)


func _short_name(full_name: String) -> String:
	# "The Patel family" stays whole; "Daniel Reyes" → "Daniel".
	if full_name.begins_with("The "):
		return full_name
	return full_name.get_slice(" ", 0)


func _pip_color_for_lifetime(lifetime: int) -> Variant:
	# Returns Color or null. null = don't show the pip.
	match lifetime:
		House.State.TRACT_LEFT:
			return PIP_TRACT
		House.State.RETURN_VISIT_SCHEDULED:
			return PIP_RETURN
		House.State.BIBLE_STUDY_STARTED:
			return PIP_STUDY
		_:
			return null


func _make_pip_style(color: Color) -> StyleBoxFlat:
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = color
	sb.border_color = UiStyle.SLATE_DARK
	sb.set_border_width_all(2)
	# 16x16 pip → corner radius 8 = full circle.
	sb.corner_radius_top_left = 8
	sb.corner_radius_top_right = 8
	sb.corner_radius_bottom_left = 8
	sb.corner_radius_bottom_right = 8
	return sb


func _make_slot_style(selected: bool) -> StyleBoxFlat:
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0)
	sb.set_corner_radius_all(12)
	if selected:
		sb.bg_color = Color(UiStyle.GOLD_LIGHT, 0.08)
		sb.border_color = UiStyle.GOLD_LIGHT
		sb.set_border_width_all(4)
		sb.set_expand_margin_all(2)
	else:
		sb.border_color = Color(0.1, 0.08, 0.05, 0.4)
		sb.set_border_width_all(2)
	return sb


func _make_medallion_style() -> StyleBoxFlat:
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = UiStyle.SLATE_DARK
	sb.border_color = UiStyle.GOLD
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(23)
	sb.shadow_color = Color(0, 0, 0, 0.45)
	sb.shadow_size = 4
	sb.shadow_offset = Vector2(0, 2)
	return sb


# --- Interaction -------------------------------------------------------------

func _on_slot_hover(house_id: StringName) -> void:
	_hover_house_id = house_id
	_select(house_id)


func _on_slot_exit(house_id: StringName) -> void:
	if _hover_house_id == house_id:
		_hover_house_id = &""


func _on_slot_gui_input(event: InputEvent, house_id: StringName) -> void:
	if _beat_active:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Debug bypass: Shift+click skips the §3 roll and treats the door
		# as answered. M4.5 spike playtests need to target the Apostate
		# slot directly when the roller rolls cold. Also bypasses the M4.6+
		# clickability gate below so resolved slots can be re-visited for
		# arc-state branch testing. OS.is_debug_build only.
		if event.shift_pressed and OS.is_debug_build():
			_force_answered_visit(house_id)
			return
		# Visited-today houses and ones there's no time left for don't take
		# clicks; the cursor and dimming set in _refresh_slot are the cue.
		var house: House = TerritoryManager.get_house(house_id)
		if house == null or not FieldService.can_visit(house):
			return
		_commit_visit(house_id)


func _force_answered_visit(house_id: StringName) -> void:
	print_debug("[debug] Shift+click: forcing an answered door at %s" % house_id)
	TerritoryManager.set_pending_house(house_id)
	TerritoryManager.resolve_householder_for_pending_house()
	get_tree().change_scene_to_file("res://scenes/door_knock.tscn")


func _select(house_id: StringName) -> void:
	if _selected_house_id == house_id:
		return
	var previous: StringName = _selected_house_id
	_selected_house_id = house_id
	if previous != &"":
		var prev_house: House = TerritoryManager.get_house(previous)
		if prev_house != null:
			_refresh_slot(prev_house)
	var house: House = TerritoryManager.get_house(house_id)
	if house != null:
		_refresh_slot(house)
		_populate_detail(house)


func _commit_visit(house_id: StringName) -> void:
	if _beat_active:
		return
	var house: House = TerritoryManager.get_house(house_id)
	if FieldService.knock(house):
		# Someone's home. Apostate houses re-roll which apostate answers.
		TerritoryManager.resolve_householder_for_pending_house()
		get_tree().change_scene_to_file("res://scenes/door_knock.tscn")
		return
	# Not home. Resolve in-place with a brief on-map beat; no scene change.
	_resolve_not_home(house)


func _resolve_not_home(house: House) -> void:
	# State first: the badge flips to grey "NOT HOME" via the
	# territory_house_visited → _on_house_visited chain. The beat label then
	# layers on top as a "registered" feedback beat.
	_beat_active = true
	var house_id: StringName = house.id
	FieldService.resolve_not_home(house)
	_refresh_session_panel()
	var slot: Control = _house_slots.get(house_id)
	if slot == null:
		_beat_active = false
		return
	var label: Label = Label.new()
	label.text = tr("No one came to the door.")
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.anchor_right = 1.0
	label.anchor_bottom = 1.0
	UiStyle.style_label(label, UiStyle.FONT_ITALIC, 20, UiStyle.CREAM)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	label.add_theme_constant_override("outline_size", 6)
	label.modulate.a = 0.0
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(label)
	var tween: Tween = create_tween()
	tween.tween_property(label, "modulate:a", 0.92, 0.2)
	tween.tween_interval(0.5)
	tween.tween_property(label, "modulate:a", 0.0, 0.3)
	tween.finished.connect(func() -> void:
		if is_instance_valid(label):
			label.queue_free()
		_beat_active = false
	)


# --- Detail panel ------------------------------------------------------------

func _show_default_detail() -> void:
	_detail_header.text = tr("House")
	_detail_polaroid.texture = _default_polaroid_texture
	_detail_caption.text = tr("Hover a house to inspect.")
	_detail_body.text = tr("Move over a slot in the territory grid to see what's known about that household.")


func _populate_detail(house: House) -> void:
	var number: int = house.grid_position.y * TerritoryManager.GRID_COLS + house.grid_position.x + 1
	_detail_header.text = tr("House #%d") % number
	_detail_polaroid.texture = _portrait_for_house_number(number)
	_detail_caption.text = tr(_caption_for_state(house.state))
	var body: String = tr(_body_for_state(house.state))
	var who: String = house.householder.character_name if house.householder != null else ""
	if house.visit_count > 0 and not who.is_empty():
		body = "%s\n\n%s" % [who, body]
	if FieldService.is_knockable(house):
		body += "\n\n" + tr("Takes about %d minutes.") % (FieldService.stop_cost(house) * 15)
	_detail_body.text = body


func _portrait_for_house_number(number: int) -> Texture2D:
	var tex: Texture2D = TerritoryManager.get_house_portrait(number)
	if tex == null:
		return _default_polaroid_texture
	return tex


func _caption_for_state(state: int) -> String:
	match state:
		House.State.TRACT_LEFT:
			return "Tract left. May return."
		House.State.BIBLE_STUDY_STARTED:
			return "Study in progress."
		House.State.RETURN_VISIT_SCHEDULED:
			return "Return visit scheduled."
		House.State.REFUSED:
			return "Declined the message."
		House.State.NOT_HOME:
			return "No one home. Tried once."
		_:
			return "No prior contact."


func _body_for_state(state: int) -> String:
	match state:
		House.State.TRACT_LEFT:
			return "Literature was accepted at the door. Worth a follow-up next Saturday."
		House.State.BIBLE_STUDY_STARTED:
			return "A weekly study is on the schedule here. Bring the next lesson. They'll be expecting you."
		House.State.RETURN_VISIT_SCHEDULED:
			return "The householder agreed to talk again. They'll be home."
		House.State.REFUSED:
			return "The conversation ended without an opening. Leave it for now."
		House.State.NOT_HOME:
			return "No one came to the door. Try again at a different hour."
		_:
			return "This household has not been visited yet. A good opportunity to introduce the message."


# --- Today's Progress aggregator --------------------------------------------

func _refresh_progress() -> void:
	# This morning's counts come from FieldService's tally; house states
	# include appointments carried over from earlier weeks.
	var tally: Dictionary = FieldService.tally
	_tract_left_count = int(tally.get("tract_left", 0))
	_return_visit_count = int(tally.get("return_visit_scheduled", 0))
	_studies_started_count = int(tally.get("bible_study_started", 0)) + int(tally.get("study_continues", 0))
	_refused_count = int(tally.get("refused", 0))
	_not_home_count = int(tally.get("not_home", 0))
	_apostate_visited_today = bool(tally.get("apostate", false))
	_tract_value.text = str(_tract_left_count)
	_return_value.text = str(_return_visit_count)
	_study_value.text = str(_studies_started_count)


# --- Legend ------------------------------------------------------------------

func _build_legend() -> void:
	for state in LEGEND_ORDER:
		var look: Dictionary = STATUS_LOOK[state]
		var row: HBoxContainer = HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		row.add_child(UiStyle.icon_rect(look["icon"], 22, look["tint"]))
		var name: Label = UiStyle.label(tr(look["text"]), UiStyle.FONT_BODY, 18, UiStyle.CREAM)
		name.custom_minimum_size = Vector2(112, 0)
		row.add_child(name)
		var note: Label = UiStyle.label(tr(look["note"]), UiStyle.FONT_ITALIC, 15, UiStyle.MUTED)
		note.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.add_child(note)
		_legend_rows.add_child(row)


# --- External events ---------------------------------------------------------

func _on_house_visited(house_id: StringName, _outcome: int) -> void:
	var house: House = TerritoryManager.get_house(house_id)
	if house != null:
		_refresh_slot(house)
		if house_id == _selected_house_id:
			_populate_detail(house)
	_refresh_progress()


func _on_end_pressed() -> void:
	if _report_card.visible:
		return
	var summary: Dictionary = FieldService.end_session()
	_populate_after_service_report(summary)
	_report_dim.visible = true
	_report_card.visible = true


func _on_report_submit_pressed() -> void:
	get_tree().change_scene_to_file(GameState.end_day())


# --- After-service report ----------------------------------------------------

func _populate_after_service_report(summary: Dictionary) -> void:
	_refresh_progress()
	_report_hours.text = "%.1f" % float(summary.get("hours", 0.0))
	_report_tracts.text = str(_tract_left_count)
	_report_returns.text = str(_return_visit_count)
	_report_studies.text = str(_studies_started_count)
	_report_refused.text = str(_refused_count)
	_report_nothome.text = str(_not_home_count)
	_report_debrief.text = tr(_pick_debrief_line())
	if DoubtMeter.value >= REPORT_INNER_VOICE_DOUBT:
		_report_inner.text = "[center]%s[/center]" % tr(_pick_inner_voice_line())
		_report_inner.visible = true
		DoubtMeter.inner_voice()
	else:
		_report_inner.visible = false


func _pick_debrief_line() -> String:
	# Tier from best-outcome of the morning. Apostate-visit overrides into its
	# own beat (the Apostate encounter colors the whole walk back to the car).
	if _apostate_visited_today:
		return "You sit in the car a minute before turning the key. Brother Phillips lets the silence sit."
	if _studies_started_count > 0:
		return "A study, by the end. Brother Phillips lifts his coffee. \"That's what we're out here for,\" he says — like he believes it again."
	if _return_visit_count > 0:
		return "An appointment in your notebook, your own handwriting. You'll read it twice before you go."
	if _tract_left_count > 0:
		return "A few tracts placed. \"It's the witness that matters,\" Brother Phillips says. \"You bring them what you can.\""
	if _refused_count + _not_home_count > 0:
		return "Long morning. The houses didn't open. Brother Phillips claps your shoulder anyway — \"Same time Saturday.\""
	return "You didn't make it to a door. The bag is still zipped. Brother Phillips says nothing about it."


func _pick_inner_voice_line() -> String:
	# Italic-register inner voice at doubt >= 40. Mirrors the meeting-hall
	# page-2 beat — observation, not verdict.
	if _studies_started_count > 0:
		return "[i]You wrote down the hours. The hours don't say what happened.[/i]"
	if _return_visit_count > 0:
		return "[i]Tuesday at ten. You wonder what you'll bring back to her.[/i]"
	if _tract_left_count > 0:
		return "[i]A few tracts placed. The number is correct.[/i]"
	if _refused_count + _not_home_count > 0:
		return "[i]The numbers add up. They always do.[/i]"
	return "[i]You didn't go to a door today. The hours are still zero.[/i]"


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/week_view.tscn")
