extends Node
## Tracks the in-game clock. Autoloaded as TimeManager.
## Emits progression signals through SignalBus so listeners stay decoupled.

enum Phase {
	SUNDAY,
	MONDAY,
	TUESDAY,
	WEDNESDAY,
	THURSDAY,
	FRIDAY,
	SATURDAY,
}

const PHASE_COUNT: int = 7

var current_week: int = 1
var current_phase: Phase = Phase.SUNDAY


func advance_phase() -> void:
	current_phase = (current_phase + 1) % PHASE_COUNT
	var week_wrapped: bool = current_phase == Phase.SUNDAY
	if week_wrapped:
		current_week += 1
	SignalBus.phase_changed.emit(current_phase)
	SignalBus.day_advanced.emit(current_phase)
	if week_wrapped:
		SignalBus.week_advanced.emit(current_week)


func phase_name(p: Phase) -> String:
	match p:
		Phase.SUNDAY:
			return tr("Sunday")
		Phase.MONDAY:
			return tr("Monday")
		Phase.TUESDAY:
			return tr("Tuesday")
		Phase.WEDNESDAY:
			return tr("Wednesday")
		Phase.THURSDAY:
			return tr("Thursday")
		Phase.FRIDAY:
			return tr("Friday")
		Phase.SATURDAY:
			return tr("Saturday")
	return ""


func current_phase_name() -> String:
	return phase_name(current_phase)
