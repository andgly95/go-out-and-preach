extends SceneTree
## Minimal headless test runner. Usage:
##   godot --headless --script res://tools/ci/run_tests.gd [-- --only=<file_substring>]
## Loads every res://tools/ci/tests/test_*.gd, calls each test_* method in
## file order, and quits with exit code 1 if any check failed.
## Test files extend res://tools/ci/test_case.gd.

const TEST_DIR: String = "res://tools/ci/tests"


func _initialize() -> void:
	# Deferred so every autoload's _ready has run before the first test.
	_run.call_deferred()


func _run() -> void:
	var only: String = ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--only="):
			only = arg.trim_prefix("--only=")
	var files: PackedStringArray = DirAccess.get_files_at(TEST_DIR)
	files.sort()
	var total: int = 0
	var failed: int = 0
	for file in files:
		if not file.begins_with("test_") or not file.ends_with(".gd"):
			continue
		if not only.is_empty() and not file.contains(only):
			continue
		var suite: Object = load("%s/%s" % [TEST_DIR, file]).new()
		for method in suite.get_method_list():
			var name: String = method["name"]
			if not name.begins_with("test_"):
				continue
			total += 1
			suite.failures.clear()
			suite.reset_game_state()
			await suite.call(name)
			if suite.failures.is_empty():
				print("  pass  %s::%s" % [file, name])
			else:
				failed += 1
				print("  FAILED %s::%s" % [file, name])
				for failure in suite.failures:
					print("         - %s" % failure)
	print("%d tests, %d failed" % [total, failed])
	quit(1 if failed > 0 else 0)
