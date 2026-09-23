extends RefCounted
## Screenshot setup: open House #5's door (Catholic polite refuser).

func setup(_tree: SceneTree) -> void:
	TerritoryManager.set_pending_house(&"house_5")
