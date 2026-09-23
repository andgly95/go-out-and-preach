extends RefCounted
## Base class for headless tests. Each test_* method records failures with
## check()/check_eq(); the runner reports them. reset_game_state() runs
## before every test so autoload state never leaks between tests.

var failures: Array[String] = []


func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func check_eq(actual: Variant, expected: Variant, message: String) -> void:
	if actual != expected:
		failures.append("%s (expected %s, got %s)" % [message, str(expected), str(actual)])


func reset_game_state() -> void:
	var tree: SceneTree = Engine.get_main_loop()
	var game_state: Node = tree.root.get_node_or_null("GameState")
	if game_state != null:
		game_state.new_game()
