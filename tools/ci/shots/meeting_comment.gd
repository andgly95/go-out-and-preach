extends RefCounted
## Screenshot setup: the Lighthouse Study question, prepared, after looking
## the verse up (doubt 40+).

func setup(_tree: SceneTree) -> void:
	GameState.autosave_enabled = false
	GameState.new_game("Jordan", "Sister", "mother")
	GameState.set_flag(MeetingManager.PREPARED_FLAG, 1)
	GameState.set_flag("looked_it_up", 1)
	DoubtMeter.apply(42, &"screenshot")
	MeetingManager.set_pending_meeting(&"sunday_meeting")


func after_load(tree: SceneTree) -> void:
	tree.current_scene.call("_show_comment_moment")
