extends Resource
class_name StoryBeat
## A short scene that finds the player on a particular day — a text from
## their sibling, coffee with their parent, the Sister Who Talks in the lobby.
## Authored as .tres in data/beats/ (with a timeline in
## data/dialogues/beats/). The Story autoload plays at most one per day, on
## the day screen, before the day's choice.

@export var id: StringName
@export var week: int = 1
## TimeManager.Phase value.
@export var day: int = 0
@export var timeline: String = ""
## Full-screen backdrop. Empty = the desk at home.
@export var background: String = ""

@export_group("Conditions")
@export var requires_flag: String = ""
@export var hide_if_flag: String = ""
@export var min_doubt: int = -1
@export var max_doubt: int = 101
## Meetings missed so far this month.
@export var min_meetings_skipped: int = 0
## GameState counter (e.g. "activity_visit_grandparent") that must be ≥ 1.
@export var requires_count: String = ""

@export_group("Effects")
## Applied when the beat plays, whatever the player chooses. Choice-specific
## effects live in the timeline's [signal] events and should stay small.
@export var conviction: int = 0
@export var standing_elders: int = 0
@export var standing_congregation: int = 0
@export var standing_family: int = 0
@export var doubt_relief: int = 0
@export var exposure: float = 0.0
@export var sets_flag: String = ""
