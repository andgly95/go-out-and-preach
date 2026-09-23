extends Node
## The run (docs/design/v01-loop.md): who the player is, where they are in
## the eight weeks, what they committed to each month, and how each month
## went. Autoloaded as GameState.
##
## Every scene ends its day through end_day(), so sleep, month close, and
## the run's end happen in one place. new_game() and SaveLoad restore every
## system to a known state.

const RUN_MONTHS: int = 2
const RUN_WEEKS: int = 8  # RUN_MONTHS × TimeManager.WEEKS_PER_MONTH
const AUX_PIONEER_HOURS: float = 30.0
const AUX_PIONEER_APPLY_ELDERS: int = 3
const AUX_PIONEER_APPLY_CONVICTION: int = 2
const EXHAUSTION_CONVICTION_COST: int = 2
const FAMILY_REPORTS_TO_ELDERS_AT: int = -10
const FAMILY_REPORT_ELDERS_COST: int = 5

const SCENE_WEEK: String = "res://scenes/week_view.tscn"
const SCENE_MONTH_REPORT: String = "res://scenes/month_report.tscn"
const SCENE_ENDING: String = "res://scenes/ending.tscn"

# Month-end verdicts and what each does on top of the elder's conversation.
const VERDICT_EFFECTS: Dictionary = {
	&"pioneer_met":    {"elders": 4, "conviction": 4, "relief": 2, "exposure": 0.0},
	&"pioneer_missed": {"elders": -3, "conviction": -2, "relief": 0, "exposure": 3.0},
	&"shepherding":    {"elders": 0, "conviction": 1, "relief": 0, "exposure": 2.0},
	&"steady":         {"elders": 1, "conviction": 1, "relief": 0, "exposure": 0.0},
}

var player_name: String = "Jordan"
## How the congregation addresses the player: "Brother" or "Sister".
var player_title: String = "Brother"
## "mother" or "father" — the parent in the Truth (cast.md § 3.1).
var parent_role: String = "mother"
## This month's record; closed into `months` at month end.
var month: Dictionary = {}
var months: Array = []
## Story beats seen and small counters, keyed by string.
var flags: Dictionary = {}
var ending_id: StringName = &""
## "Mom" / "Dad" and "Grandma" as properties, so Dialogic text can use
## {GameState.parent_word} and {GameState.grandparent_word}.
var parent_word: String:
	get:
		return parent_name()
var grandparent_word: String:
	get:
		return grandparent_name()
## The supporting cast, as properties for Dialogic text ({GameState.x}).
## Names are placeholders pending Andrew's review (docs/STATUS.md).
var sibling_name: String = "Micah"
var coworker_name: String = "Dana"
var talker_name: String = "Sister Marin"
## The recurring service partner is paired with the player, so the same title.
var partner_name: String:
	get:
		return tr("Eli") if player_title == "Brother" else tr("Naomi")
var partner_formal: String:
	get:
		return "%s %s" % [tr(player_title), partner_name]
## Off during the balance simulation so it doesn't touch user://.
var autosave_enabled: bool = true


func _ready() -> void:
	# Fill Dialogic's character/timeline identifier tables once per launch.
	# Scenes must not rescan later: any speaker Dialogic creates at runtime
	# is stored in the same table as an object, and the rescan expects paths.
	DialogicResourceUtil.update_directory(".dch")
	DialogicResourceUtil.update_directory(".dtl")
	month = _new_month_record(1)
	SignalBus.meeting_attended.connect(_on_meeting_attended)
	SignalBus.meeting_skipped.connect(_on_meeting_skipped)
	SignalBus.service_session_ended.connect(_on_service_session_ended)
	SignalBus.day_advanced.connect(_on_day_advanced)


# --- Starting a run -----------------------------------------------------------

func new_game(name: String = "Jordan", title: String = "Brother", parent: String = "mother") -> void:
	TimeManager.reset()
	ResourceManager.reset()
	DoubtMeter.reset()
	TerritoryManager.reset()
	MeetingManager.reset()
	FieldService.reset()
	player_name = name.strip_edges() if not name.strip_edges().is_empty() else "Jordan"
	player_title = title
	parent_role = parent
	month = _new_month_record(1)
	months = []
	flags = {}
	ending_id = &""


## "Mom" or "Dad" — what the player calls their parent.
func parent_name() -> String:
	return tr("Mom") if parent_role == "mother" else tr("Dad")


## "Brother Jordan" / "Sister Jordan".
func formal_name() -> String:
	return "%s %s" % [tr(player_title), player_name]


## What the player calls their grandparent (cast.md § 3.3).
func grandparent_name() -> String:
	return tr("Grandma")


## Fills {name} {title} {parent} {grandparent} tokens in screen copy.
## (Dialogic timelines use {GameState.player_name} etc. directly.)
func fill(text: String) -> String:
	return text.replace("{name}", player_name) \
		.replace("{title}", tr(player_title)) \
		.replace("{parent}", parent_name()) \
		.replace("{grandparent}", grandparent_name()) \
		.replace("{sibling}", sibling_name) \
		.replace("{coworker}", coworker_name) \
		.replace("{partner}", partner_name) \
		.replace("{talker}", talker_name)


func weeks_left() -> int:
	return RUN_WEEKS - TimeManager.current_week + 1


# --- Flags --------------------------------------------------------------------

func flag(key: String) -> Variant:
	return flags.get(key, 0)


func set_flag(key: String, value: Variant = true) -> void:
	flags[key] = value


func bump(key: String) -> int:
	flags[key] = int(flags.get(key, 0)) + 1
	return flags[key]


## Integer counter (0 if unset). For timeline conditions.
func count(key: String) -> int:
	return int(flags.get(key, 0))


# Queries for timeline conditions ([if GameState.x()]).
func skipped_this_month() -> int:
	return int(month.get("meetings_skipped", 0))


func attended_this_month() -> int:
	return int(month.get("meetings_attended", 0))


func is_pioneering() -> bool:
	return month.get("aux_pioneer", false)


# --- Monthly commitment ---------------------------------------------------------

func pioneer_decision_pending() -> bool:
	return TimeManager.week_in_month() == 1 \
		and TimeManager.current_phase == TimeManager.Phase.SUNDAY \
		and not month.get("pioneer_decided", false)


func decide_pioneer(apply: bool) -> void:
	month["pioneer_decided"] = true
	month["aux_pioneer"] = apply
	if apply:
		ResourceManager.add_standing_elders(AUX_PIONEER_APPLY_ELDERS)
		ResourceManager.add_conviction(AUX_PIONEER_APPLY_CONVICTION)


## True if the parent will have "mentioned something" to the elders this month.
func family_concern_pending() -> bool:
	return ResourceManager.standing_family <= FAMILY_REPORTS_TO_ELDERS_AT and not month.get("parent_told_elders", false)


func missed_many_meetings() -> bool:
	return int(month.get("meetings_skipped", 0)) >= 3


func no_service_this_month() -> bool:
	return int(month.get("service_mornings", 0)) == 0


func hours_target() -> float:
	return AUX_PIONEER_HOURS if month.get("aux_pioneer", false) else 0.0


# --- Ending the day -------------------------------------------------------------

## Ends the current day. Returns the scene to show next.
func end_day() -> String:
	if ResourceManager.energy <= 0:
		ResourceManager.add_conviction(-EXHAUSTION_CONVICTION_COST)
		bump("exhausted_nights")
	if TimeManager.current_phase == TimeManager.Phase.SATURDAY and TimeManager.is_last_week_of_month():
		return SCENE_MONTH_REPORT
	TimeManager.advance_phase()
	return SCENE_WEEK


## How the elders will read this month. Decides the month-end conversation.
func month_verdict() -> StringName:
	var hours: float = ResourceManager.field_service_hours
	if month.get("aux_pioneer", false):
		return &"pioneer_met" if hours >= AUX_PIONEER_HOURS else &"pioneer_missed"
	if ResourceManager.standing_elders <= -10 \
			or int(month.get("meetings_skipped", 0)) >= 3 \
			or int(month.get("service_mornings", 0)) == 0:
		return &"shepherding"
	return &"steady"


## Called by the month report once the conversation is over. Applies the
## verdict, files the month, and moves on. Returns the next scene.
func close_month() -> String:
	var verdict: StringName = month_verdict()
	var effects: Dictionary = VERDICT_EFFECTS[verdict]
	ResourceManager.add_standing_elders(int(effects["elders"]))
	ResourceManager.add_conviction(int(effects["conviction"]))
	DoubtMeter.apply(-int(effects["relief"]), &"month_affirmation")
	DoubtMeter.expose(float(effects["exposure"]), StringName("month_" + String(verdict)))
	if ResourceManager.standing_family <= FAMILY_REPORTS_TO_ELDERS_AT and not month.get("parent_told_elders", false):
		month["parent_told_elders"] = true
		ResourceManager.add_standing_elders(-FAMILY_REPORT_ELDERS_COST)
	month["verdict"] = String(verdict)
	month["hours"] = ResourceManager.field_service_hours
	months.append(month)
	SignalBus.month_closed.emit(month)
	ResourceManager.set_hours(0.0)
	if TimeManager.current_week >= RUN_WEEKS:
		ending_id = resolve_ending()
		SaveLoad.clear_autosave()
		return SCENE_ENDING
	month = _new_month_record(TimeManager.current_month() + 1)
	TimeManager.advance_phase()
	return SCENE_WEEK


# --- Endings ----------------------------------------------------------------------

## First match wins (docs/design/v01-loop.md § Endings).
func resolve_ending() -> StringName:
	var doubt: int = DoubtMeter.value
	var pioneered_every_month: bool = not months.is_empty()
	for record in months:
		if record.get("verdict", "") != "pioneer_met":
			pioneered_every_month = false
	var last: Dictionary = months.back() if not months.is_empty() else month
	var last_month_attendance: float = _attendance(last)
	if pioneered_every_month and ResourceManager.conviction >= 60 and doubt < 40:
		return &"regular_pioneer"
	if doubt < 40 and last_month_attendance >= 0.75:
		return &"in_fold"
	if doubt >= 55 and last_month_attendance >= 0.75 and ResourceManager.standing_elders >= 0:
		return &"keeping_up_appearances"
	if doubt >= 70 and last_month_attendance < 0.75:
		return &"walking_away"
	return &"quiet_fade"


func _attendance(record: Dictionary) -> float:
	var attended: int = int(record.get("meetings_attended", 0))
	var total: int = attended + int(record.get("meetings_skipped", 0))
	if total == 0:
		return 0.0
	return float(attended) / float(total)


# --- Records ------------------------------------------------------------------------

func _new_month_record(number: int) -> Dictionary:
	return {
		"month": number,
		"pioneer_decided": false,
		"aux_pioneer": false,
		"meetings_attended": 0,
		"meetings_skipped": 0,
		"service_mornings": 0,
		"conversations": 0,
		"hours": 0.0,
	}


func _on_meeting_attended(_meeting_type: StringName) -> void:
	month["meetings_attended"] = int(month.get("meetings_attended", 0)) + 1


func _on_meeting_skipped(_meeting_type: StringName) -> void:
	month["meetings_skipped"] = int(month.get("meetings_skipped", 0)) + 1


func _on_service_session_ended(summary: Dictionary) -> void:
	month["service_mornings"] = int(month.get("service_mornings", 0)) + 1
	month["conversations"] = int(month.get("conversations", 0)) + int(summary.get("answered", 0))
	month["placements"] = int(month.get("placements", 0)) + int(summary.get("tract_left", 0))
	month["return_visits"] = int(month.get("return_visits", 0)) + int(summary.get("return_visit_scheduled", 0))
	month["study_sessions"] = int(month.get("study_sessions", 0)) + int(summary.get("study_continues", 0)) + int(summary.get("bible_study_started", 0))


func _on_day_advanced(_day: int) -> void:
	# Autosave at the start of every day, so Continue never loses more than
	# the day in progress. (GDD § 10 asks for week boundaries; daily is the
	# same one-slot mechanism, triggered more often.)
	if autosave_enabled:
		SaveLoad.autosave()


# --- Save ------------------------------------------------------------------------------

func to_save() -> Dictionary:
	return {
		"player_name": player_name,
		"player_title": player_title,
		"parent_role": parent_role,
		"month": month,
		"months": months,
		"flags": flags,
	}


func from_save(data: Dictionary) -> void:
	player_name = data.get("player_name", "Jordan")
	player_title = data.get("player_title", "Brother")
	parent_role = data.get("parent_role", "mother")
	month = data.get("month", _new_month_record(1))
	months = data.get("months", [])
	flags = data.get("flags", {})
	ending_id = &""
