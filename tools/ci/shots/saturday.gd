extends RefCounted
## Screenshot setup: advance the calendar to Saturday of week 1.

func setup(_tree: SceneTree) -> void:
	for i in 6:
		TimeManager.advance_phase()
