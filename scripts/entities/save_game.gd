extends Resource
class_name SaveGame
## One saved run. Each system contributes a plain Dictionary via to_save();
## SaveLoad writes this resource with ResourceSaver (GDD § 10).

const CURRENT_VERSION: int = 1

@export var version: int = CURRENT_VERSION
@export var saved_at: String = ""
@export var label: String = ""
@export var data: Dictionary = {}
