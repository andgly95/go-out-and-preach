extends SceneTree
## Plays a whole run through the real scenes, headless: presses the day
## screen's option buttons, knocks doors on the map, clicks through Dialogic
## (a random enabled choice at each question), and follows every scene change
## until the ending. Exits 1 if the run gets stuck or never ends; script
## errors surface as engine ERROR lines, which tools/check.sh catches.
##
##   bash tools/godot.sh --headless --script res://tools/ci/autoplay.gd -- --seed=3 [--verbose]
##
## The logic lives in autoplay_driver.gd, loaded at runtime: this entry
## script is compiled before autoload names exist.


func _initialize() -> void:
	_run.call_deferred()


var _driver: RefCounted = null


func _run() -> void:
	_driver = load("res://tools/ci/autoplay_driver.gd").new()
	await _driver.run(self)
