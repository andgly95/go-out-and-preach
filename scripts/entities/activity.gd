extends Resource
class_name Activity
## Something the player can do with a day or an evening instead of (or
## besides) meetings and field service: family worship, personal study, a
## visit, rest. Authored as .tres in data/activities/ and offered by the
## Evenings autoload on the days listed.

@export var id: StringName
@export var title: String = ""
@export var description: String = ""
@export var icon: String = "✦"
## TimeManager.Phase values this activity is offered on.
@export var days: Array[int] = []
## Position among the day's options (lower first).
@export var order: int = 50
## Energy spent; negative restores (rest).
@export var energy_cost: int = 0

@export_group("Effects")
@export var conviction: int = 0
@export var standing_elders: int = 0
@export var standing_congregation: int = 0
@export var standing_family: int = 0
## Unscaled doubt removed (belonging, warmth).
@export var doubt_relief: int = 0
## Conviction-scaled doubt added (see DoubtMeter.expose).
@export var exposure: float = 0.0
## GameState flag set to 1 when chosen (e.g. prepared for Sunday).
@export var sets_flag: String = ""

@export_group("Scenes")
## Full-screen backdrop while the scene plays. Empty = the desk at home.
@export var background: String = ""
## Timelines played in order, one per time the activity is chosen.
@export var scenes: Array[String] = []
## Played once `scenes` are used up. Empty = show `result_text` instead.
@export var repeat_scene: String = ""
## One line shown when there's no scene to play.
@export var result_text: String = ""

@export_group("Availability")
## Minimum congregation standing to be offered (e.g. an invitation).
@export var min_congregation: int = -1000
## Only offered while a GameState flag is unset (e.g. a one-time beat).
@export var hide_if_flag: String = ""
