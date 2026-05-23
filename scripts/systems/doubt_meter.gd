extends Node
## Hidden 0-100 doubt meter (M4). Autoloaded as DoubtMeter.
## GDD § 5.2: not shown in UI until threshold 40; fully visible at 70.
## CLAUDE.md § Common Pitfalls: "there's a debug flag for that" — no
## production HUD readout. The threshold-70 full-visibility behavior is
## deferred to a later milestone; M4 ships only the 40 reveal.
##
## All mutations go through apply() so the event log records reason and
## delta. The log is a small ring buffer for the debug panel; it is not
## persisted and is not authoritative state.

const VALUE_MIN: int = 0
const VALUE_MAX: int = 100
const THRESHOLD_AMBIGUOUS: int = 40
const THRESHOLD_VISIBLE: int = 70
const EVENT_LOG_MAX: int = 10

# T4 (Saturday-zero-RV) trigger value. +2 chosen to mirror T2/walk-away;
# documented in the plan and STATUS.md trigger table.
const SATURDAY_ZERO_RV_DELTA: int = 2

var value: int = 0

var _pending_reveal_40: bool = false
var _event_log: Array = []


func _ready() -> void:
	SignalBus.day_advanced.connect(_on_day_advanced)


func apply(delta: int, reason: StringName) -> void:
	if delta == 0:
		return
	var previous: int = value
	value = clampi(value + delta, VALUE_MIN, VALUE_MAX)
	var actual_delta: int = value - previous
	if actual_delta == 0:
		# Already at clamp; nothing happened. Skip logging the noise.
		return
	_log_event(actual_delta, reason)
	if previous < THRESHOLD_AMBIGUOUS and value >= THRESHOLD_AMBIGUOUS:
		_pending_reveal_40 = true
		SignalBus.doubt_threshold_crossed.emit(THRESHOLD_AMBIGUOUS)
	if previous < THRESHOLD_VISIBLE and value >= THRESHOLD_VISIBLE:
		SignalBus.doubt_threshold_crossed.emit(THRESHOLD_VISIBLE)


func get_value() -> int:
	return value


func consume_reveal_40() -> bool:
	if not _pending_reveal_40:
		return false
	_pending_reveal_40 = false
	return true


func get_event_log() -> Array:
	return _event_log.duplicate()


func _log_event(actual_delta: int, reason: StringName) -> void:
	_event_log.push_back({
		"delta": actual_delta,
		"reason": reason,
		"value": value,
		"ts": Time.get_ticks_msec(),
	})
	while _event_log.size() > EVENT_LOG_MAX:
		_event_log.pop_front()


func _on_day_advanced(new_phase: int) -> void:
	# T4 fires on the SAT → SUN edge. With TimeManager's linear week order,
	# reaching SUNDAY only happens via wrap from SATURDAY, so checking the
	# new phase is sufficient — no need to track the previous day.
	# Edge case: this also fires on the very first SUN → MON → ... → SUN
	# cycle, which is correct because the player has just completed their
	# first Saturday. The autoload starts at value=0, so the +2 is real
	# but quiet (4 sessions to 40 if every Saturday is empty).
	if new_phase != TimeManager.Phase.SUNDAY:
		return
	if _territory_had_return_visit_this_week():
		return
	apply(SATURDAY_ZERO_RV_DELTA, &"saturday_zero_rv")


func _territory_had_return_visit_this_week() -> bool:
	# M4 has no week-level territory reset (M7 save/load brings that in).
	# Scan the current territory for any house in RETURN_VISIT_SCHEDULED
	# state. Good enough for the one-Saturday-then-test loop. STATUS flags
	# this for refinement when multi-week state lands.
	if TerritoryManager.current_territory == null:
		return false
	for house in TerritoryManager.current_territory.houses:
		if house.state == House.State.RETURN_VISIT_SCHEDULED:
			return true
	return false
