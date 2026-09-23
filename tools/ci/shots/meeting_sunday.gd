extends RefCounted
## Screenshot setup: enter the Sunday meeting at the seat picker.

func setup(_tree: SceneTree) -> void:
	MeetingManager.set_pending_meeting(&"sunday_meeting")
