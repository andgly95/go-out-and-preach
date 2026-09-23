extends RefCounted
## Screenshot setup: enter the Sunday meeting at the seat picker.

func setup(_tree: SceneTree) -> void:
	GameState.autosave_enabled = false
	GameState.new_game("Jordan", "Brother", "mother")
	MeetingManager.set_pending_meeting(&"sunday_meeting")
