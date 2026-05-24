extends Control
## Territory map (M4-LF1 visual polish). Renders the painted background +
## per-slot medallion/badge overlays, drives hover selection into the right-
## hand detail panel, and aggregates Today's Progress from
## SignalBus.territory_house_visited. The top banner here replaces the
## shared hud.tscn for this scene only (week_view and door_knock still use
## the shared HUD).
##
## House slot positions are expressed as fractional (x, y, w, h) offsets of
## the painted background so the layout tracks viewport stretch. The grid
## cells in background.png span roughly columns at 9/30/52/74% and rows at
## 9/37/63% — tuned by eye against territory_map_v1.png.

const SLOT_FRACTIONS: Array = [
	# x,    y,    w,     h     (each as fraction of CenterMap rect)
	Vector4(0.060, 0.085, 0.205, 0.245),
	Vector4(0.278, 0.085, 0.205, 0.245),
	Vector4(0.498, 0.085, 0.205, 0.245),
	Vector4(0.718, 0.085, 0.222, 0.245),
	Vector4(0.060, 0.360, 0.205, 0.245),
	Vector4(0.278, 0.360, 0.205, 0.245),
	Vector4(0.498, 0.360, 0.205, 0.245),
	Vector4(0.718, 0.360, 0.222, 0.245),
	Vector4(0.060, 0.635, 0.205, 0.245),
	Vector4(0.278, 0.635, 0.205, 0.245),
	Vector4(0.498, 0.635, 0.205, 0.245),
	Vector4(0.718, 0.635, 0.222, 0.245),
]

const BADGE_GREEN: Color  = Color(0.36, 0.55, 0.36, 0.94)
const BADGE_AMBER: Color  = Color(0.78, 0.60, 0.30, 0.94)
const BADGE_RED:   Color  = Color(0.55, 0.20, 0.20, 0.94)
const BADGE_GREY:  Color  = Color(0.45, 0.45, 0.45, 0.94)
const BADGE_CREAM: Color  = Color(0.85, 0.78, 0.62, 0.88)

const GOLD: Color         = Color(0.78, 0.62, 0.28, 1.0)
const NAVY_DEEP: Color    = Color(0.09, 0.11, 0.16, 0.92)
const CREAM_TEXT: Color   = Color(0.96, 0.92, 0.79, 1.0)

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
@onready var _detail_caption: Label = $MainRow/RightDetailPanel/RightMargin/RightVBox/StateCaption
@onready var _detail_body:    Label = $MainRow/RightDetailPanel/RightMargin/RightVBox/BodyText
@onready var _legend_rows:    VBoxContainer = $MainRow/RightDetailPanel/RightMargin/RightVBox/LegendRows

var _house_slots: Dictionary = {}                # house_id -> Control (slot root)
var _selected_house_id: StringName = &""
var _hover_house_id:    StringName = &""

# Today's Progress counters. Recomputed from current territory on _ready and
# refreshed via the territory_house_visited signal — see _refresh_progress().
var _tract_left_count: int = 0
var _return_visit_count: int = 0
var _studies_started_count: int = 0


func _ready() -> void:
	_scripture_quote_label.text = tr(SCRIPTURE_QUOTE)
	_scripture_ref_label.text = tr(SCRIPTURE_REF)
	_territory_title.text = TerritoryManager.current_territory.display_name
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
	_end_button.pressed.connect(_on_end_pressed)
	_back_button.pressed.connect(_on_back_pressed)
	_map_area.resized.connect(_layout_slots)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()


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

	# Selection outline. Empty-fill StyleBox so the painted background shows
	# through; the border flips to gold while this slot is selected. Pure
	# decoration — must not intercept mouse events or the root's hover/click
	# handlers below never fire.
	var hit: Panel = Panel.new()
	hit.name = "Hit"
	hit.anchor_right = 1.0
	hit.anchor_bottom = 1.0
	hit.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hit.add_theme_stylebox_override("panel", _make_slot_style(false))
	root.add_child(hit)

	# Medallion at top-center.
	var medallion: Panel = Panel.new()
	medallion.name = "Medallion"
	medallion.custom_minimum_size = Vector2(38, 38)
	medallion.anchor_left = 0.5
	medallion.anchor_right = 0.5
	medallion.offset_left = -19.0
	medallion.offset_right = 19.0
	medallion.offset_top = 6.0
	medallion.offset_bottom = 44.0
	medallion.mouse_filter = Control.MOUSE_FILTER_IGNORE
	medallion.add_theme_stylebox_override("panel", _make_medallion_style())
	root.add_child(medallion)

	var medallion_label: Label = Label.new()
	medallion_label.text = str(number)
	medallion_label.anchor_right = 1.0
	medallion_label.anchor_bottom = 1.0
	medallion_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	medallion_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	medallion_label.add_theme_color_override("font_color", CREAM_TEXT)
	medallion_label.add_theme_font_size_override("font_size", 18)
	medallion_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	medallion.add_child(medallion_label)

	# Outcome badge below medallion. Anchored to bottom-center of the slot.
	var badge: PanelContainer = PanelContainer.new()
	badge.name = "Badge"
	badge.anchor_left = 0.05
	badge.anchor_right = 0.95
	badge.anchor_top = 1.0
	badge.anchor_bottom = 1.0
	badge.offset_top = -34.0
	badge.offset_bottom = -8.0
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.add_theme_stylebox_override("panel", _make_badge_style(BADGE_CREAM))
	root.add_child(badge)

	var badge_label: Label = Label.new()
	badge_label.name = "Label"
	badge_label.text = tr("NOT VISITED")
	badge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge_label.add_theme_color_override("font_color", NAVY_DEEP)
	badge_label.add_theme_font_size_override("font_size", 12)
	badge_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.add_child(badge_label)

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
	var badge: PanelContainer = slot.get_node("Badge")
	var badge_label: Label = badge.get_node("Label")
	var info: Dictionary = _badge_info_for_state(house.state)
	badge.add_theme_stylebox_override("panel", _make_badge_style(info.get("color")))
	badge_label.text = tr(info.get("text"))
	badge_label.add_theme_color_override("font_color", info.get("text_color"))
	var hit: Panel = slot.get_node("Hit")
	hit.add_theme_stylebox_override("panel", _make_slot_style(house.id == _selected_house_id))


func _badge_info_for_state(state: int) -> Dictionary:
	match state:
		House.State.TRACT_LEFT:
			return {"color": BADGE_GREEN, "text": "TRACT LEFT", "text_color": CREAM_TEXT}
		House.State.BIBLE_STUDY_STARTED:
			return {"color": BADGE_GREEN, "text": "STUDY STARTED", "text_color": CREAM_TEXT}
		House.State.RETURN_VISIT_SCHEDULED:
			return {"color": BADGE_AMBER, "text": "RETURN VISIT", "text_color": NAVY_DEEP}
		House.State.REFUSED:
			return {"color": BADGE_RED, "text": "REFUSED", "text_color": CREAM_TEXT}
		House.State.NOT_HOME:
			return {"color": BADGE_GREY, "text": "NOT HOME", "text_color": CREAM_TEXT}
		_:
			return {"color": BADGE_CREAM, "text": "NOT VISITED", "text_color": NAVY_DEEP}


func _make_slot_style(selected: bool) -> StyleBoxFlat:
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0)
	if selected:
		sb.border_color = GOLD
		sb.set_border_width_all(3)
	else:
		sb.border_color = Color(0, 0, 0, 0)
		sb.set_border_width_all(0)
	sb.corner_radius_top_left = 4
	sb.corner_radius_top_right = 4
	sb.corner_radius_bottom_left = 4
	sb.corner_radius_bottom_right = 4
	return sb


func _make_medallion_style() -> StyleBoxFlat:
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = NAVY_DEEP
	sb.border_color = GOLD
	sb.set_border_width_all(2)
	sb.corner_radius_top_left = 19
	sb.corner_radius_top_right = 19
	sb.corner_radius_bottom_left = 19
	sb.corner_radius_bottom_right = 19
	return sb


func _make_badge_style(color: Color) -> StyleBoxFlat:
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = color
	sb.corner_radius_top_left = 3
	sb.corner_radius_top_right = 3
	sb.corner_radius_bottom_left = 3
	sb.corner_radius_bottom_right = 3
	sb.content_margin_left = 6.0
	sb.content_margin_right = 6.0
	sb.content_margin_top = 3.0
	sb.content_margin_bottom = 3.0
	return sb


# --- Interaction -------------------------------------------------------------

func _on_slot_hover(house_id: StringName) -> void:
	_hover_house_id = house_id
	_select(house_id)


func _on_slot_exit(house_id: StringName) -> void:
	if _hover_house_id == house_id:
		_hover_house_id = &""


func _on_slot_gui_input(event: InputEvent, house_id: StringName) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_commit_visit(house_id)


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
	TerritoryManager.set_pending_house(house_id)
	get_tree().change_scene_to_file("res://scenes/door_knock.tscn")


# --- Detail panel ------------------------------------------------------------

func _show_default_detail() -> void:
	_detail_header.text = tr("✦ HOUSE #—— ✦")
	_detail_caption.text = tr("Hover a house to inspect.")
	_detail_body.text = tr("Move over a slot in the territory grid to see what's known about that household.")


func _populate_detail(house: House) -> void:
	var number: int = house.grid_position.y * TerritoryManager.GRID_COLS + house.grid_position.x + 1
	_detail_header.text = tr("✦ HOUSE #%d ✦") % number
	_detail_caption.text = tr(_caption_for_state(house.state))
	_detail_body.text = tr(_body_for_state(house.state))


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
			return "A weekly study is on the schedule here. Bring the next lesson."
		House.State.RETURN_VISIT_SCHEDULED:
			return "The householder agreed to talk again. Keep the appointment."
		House.State.REFUSED:
			return "The conversation ended without an opening. Leave it for now."
		House.State.NOT_HOME:
			return "No one came to the door. Try again at a different hour."
		_:
			return "This household has not been visited yet. A good opportunity to introduce the message."


# --- Today's Progress aggregator --------------------------------------------

func _refresh_progress() -> void:
	_tract_left_count = 0
	_return_visit_count = 0
	_studies_started_count = 0
	for house in TerritoryManager.current_territory.houses:
		match house.state:
			House.State.TRACT_LEFT:
				_tract_left_count += 1
			House.State.RETURN_VISIT_SCHEDULED:
				_return_visit_count += 1
			House.State.BIBLE_STUDY_STARTED:
				_studies_started_count += 1
	_tract_value.text = str(_tract_left_count)
	_return_value.text = str(_return_visit_count)
	_study_value.text = str(_studies_started_count)


# --- Legend ------------------------------------------------------------------

func _build_legend() -> void:
	var entries: Array = [
		{"color": BADGE_GREEN, "label": "Tract Left",   "note": "Literature accepted."},
		{"color": BADGE_AMBER, "label": "Return Visit", "note": "Conversation will continue."},
		{"color": BADGE_GREEN, "label": "Study Started","note": "Weekly study in progress."},
		{"color": BADGE_RED,   "label": "Refused",      "note": "Door closed politely or otherwise."},
		{"color": BADGE_CREAM, "label": "Not Visited",  "note": "No prior contact."},
	]
	for entry in entries:
		var row: HBoxContainer = HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var swatch: Panel = Panel.new()
		swatch.custom_minimum_size = Vector2(12, 12)
		var sb: StyleBoxFlat = StyleBoxFlat.new()
		sb.bg_color = entry.get("color")
		sb.corner_radius_top_left = 2
		sb.corner_radius_top_right = 2
		sb.corner_radius_bottom_left = 2
		sb.corner_radius_bottom_right = 2
		swatch.add_theme_stylebox_override("panel", sb)
		swatch.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(swatch)
		var label: Label = Label.new()
		label.text = tr(entry.get("label"))
		label.add_theme_color_override("font_color", CREAM_TEXT)
		label.add_theme_font_size_override("font_size", 12)
		label.custom_minimum_size = Vector2(96, 0)
		row.add_child(label)
		var note: Label = Label.new()
		note.text = tr(entry.get("note"))
		note.add_theme_color_override("font_color", Color(0.78, 0.7, 0.52, 0.9))
		note.add_theme_font_size_override("font_size", 11)
		note.size_flags_horizontal = Control.SIZE_EXPAND_FILL
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
	TimeManager.advance_phase()
	get_tree().change_scene_to_file("res://scenes/week_view.tscn")


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/week_view.tscn")
