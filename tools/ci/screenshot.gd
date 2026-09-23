extends SceneTree
## Renders a scene and saves a PNG. Needs a display (use xvfb-run), not --headless:
##   xvfb-run -a -s "-screen 0 1920x1080x24" godot --rendering-driver opengl3 \
##     --script res://tools/ci/screenshot.gd -- <scene.tscn> <out.png> [setup.gd] [frames]
## The optional setup script (extends RefCounted, func setup(tree) -> void,
## may await) runs before the scene loads so tests can stage game state —
## e.g. advance to Saturday or queue a pending house. It may also define
## func after_load(tree) -> void to drive the loaded scene (press buttons).

func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() < 2:
		push_error("usage: -- <scene.tscn> <out.png> [setup.gd] [frames]")
		quit(2)
		return
	var scene_path: String = args[0]
	var out_path: String = args[1]
	var setup: Object = null
	if args.size() >= 3 and not args[2].is_empty() and args[2] != "-":
		setup = load(args[2]).new()
	var frames: int = int(args[3]) if args.size() >= 4 else 30
	if setup != null and setup.has_method("setup"):
		await setup.setup(self)
	change_scene_to_file(scene_path)
	for i in 3:
		await process_frame
	if setup != null and setup.has_method("after_load"):
		await setup.after_load(self)
	for i in frames:
		await process_frame
	var image: Image = root.get_texture().get_image()
	image.save_png(out_path)
	print("saved %s (%dx%d)" % [out_path, image.get_width(), image.get_height()])
	quit(0)
