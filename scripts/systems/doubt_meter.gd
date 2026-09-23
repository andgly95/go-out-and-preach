extends Node
## Hidden 0–100 doubt meter. Autoloaded as DoubtMeter.
## GDD § 5.2: nothing in the UI until 40; fully visible at 70. There is no
## production readout — the F9 debug panel (debug builds only) is the view.
##
## Two ways in (docs/design/v01-loop.md § Conviction and doubt):
##  - expose(base, reason): something heard or seen that doesn't fit. Scaled
##    by conviction — ×1.5 at 0, ×1.0 at 50, ×0.5 at 100 — so faith buffers
##    exposure but never blocks it. Exposure also wears conviction down by
##    half as much: the visible meter is the hidden one's shadow.
##  - apply(delta, reason): an unscaled change — relief from belonging,
##    walking away from a door, debug nudges.
## Fractions accumulate in `exact`; `value` (read by .dtl conditions) is the
## whole part, so small exposures still add up.

const VALUE_MIN: int = 0
const VALUE_MAX: int = 100
const THRESHOLD_AMBIGUOUS: int = 40
const THRESHOLD_VISIBLE: int = 70
const EVENT_LOG_MAX: int = 12
const EXPOSURE_SCALE_AT_ZERO_CONVICTION: float = 1.5
const EXPOSURE_SCALE_MIN: float = 0.5
# Once the inner voice has started (doubt >= 40 gates those lines), each
# time it speaks adds a little: noticing is how you keep noticing.
const INNER_VOICE_EXPOSURE: float = 0.5
const CONVICTION_COST_PER_EXPOSURE: float = 0.5

var value: int = 0
var exact: float = 0.0
## What greyed-out choices check (`[if DoubtMeter.noticing >= N]`): doubt,
## plus habits that make you notice sooner. The inner voice and the reveal
## still read `value`.
var noticing: int:
	get:
		return value + int(Habits.modifier("gate_offset"))

var _pending_reveal_40: bool = false
var _event_log: Array = []
var _conviction_wear: float = 0.0


func reset() -> void:
	value = 0
	exact = 0.0
	_pending_reveal_40 = false
	_conviction_wear = 0.0
	_event_log.clear()


func to_save() -> Dictionary:
	return {"exact": exact, "pending_reveal_40": _pending_reveal_40}


func from_save(data: Dictionary) -> void:
	exact = float(data.get("exact", 0.0))
	value = int(floor(exact + 0.0001))
	_pending_reveal_40 = bool(data.get("pending_reveal_40", false))
	_event_log.clear()


func exposure_scale() -> float:
	var scale: float = EXPOSURE_SCALE_AT_ZERO_CONVICTION - ResourceManager.conviction / 100.0
	return clampf(scale, EXPOSURE_SCALE_MIN, EXPOSURE_SCALE_AT_ZERO_CONVICTION)


func expose(base: float, reason: StringName) -> void:
	if base <= 0.0:
		return
	var scaled: float = base * exposure_scale()
	_change(scaled, reason)
	var wear_scale: float = maxf(0.0, 1.0 + Habits.modifier("conviction_wear_scale"))
	_conviction_wear += scaled * CONVICTION_COST_PER_EXPOSURE * wear_scale
	if _conviction_wear >= 1.0:
		var whole: int = int(floor(_conviction_wear))
		_conviction_wear -= whole
		ResourceManager.add_conviction(-whole)


func inner_voice() -> void:
	expose(INNER_VOICE_EXPOSURE, &"inner_voice")


func apply(delta: int, reason: StringName) -> void:
	if delta == 0:
		return
	_change(float(delta), reason)


func get_value() -> int:
	return value


func consume_reveal_40() -> bool:
	if not _pending_reveal_40:
		return false
	_pending_reveal_40 = false
	return true


func get_event_log() -> Array:
	return _event_log.duplicate()


func _change(delta: float, reason: StringName) -> void:
	var previous_exact: float = exact
	var previous: int = value
	exact = clampf(exact + delta, VALUE_MIN, VALUE_MAX)
	value = int(floor(exact + 0.0001))
	if is_equal_approx(exact, previous_exact):
		return
	_log_event(exact - previous_exact, reason)
	if previous < THRESHOLD_AMBIGUOUS and value >= THRESHOLD_AMBIGUOUS:
		_pending_reveal_40 = true
		SignalBus.doubt_threshold_crossed.emit(THRESHOLD_AMBIGUOUS)
	if previous < THRESHOLD_VISIBLE and value >= THRESHOLD_VISIBLE:
		SignalBus.doubt_threshold_crossed.emit(THRESHOLD_VISIBLE)


func _log_event(actual_delta: float, reason: StringName) -> void:
	_event_log.push_back({
		"delta": actual_delta,
		"reason": reason,
		"value": exact,
		"ts": Time.get_ticks_msec(),
	})
	while _event_log.size() > EVENT_LOG_MAX:
		_event_log.pop_front()
