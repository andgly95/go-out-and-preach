extends Control
## Scene runner for the day screen. Plays either today's story beat
## (Story.pending), then returns to the same day, or the activity the player
## chose (Evenings.pending): its scene timeline over a backdrop, or a single
## result line when it has none, then ends the day through GameState.
## Scene [signal] events go to Evenings.apply_scene_signal.

const WEEK_SCENE_PATH: String = "res://scenes/week_view.tscn"

@onready var _background: TextureRect = $Background
@onready var _card: PanelContainer = $Card
@onready var _title: Label = $Card/Margin/VBox/Title
@onready var _body: Label = $Card/Margin/VBox/Body
@onready var _continue: Button = $Card/Margin/VBox/Continue

var _finished: bool = false
var _is_beat: bool = false


func _ready() -> void:
	_continue.pressed.connect(_finish)
	if Story.pending != null:
		_is_beat = true
		_set_background(Story.pending.background)
		_start_timeline(Story.pending.timeline)
		return
	var activity: Activity = Evenings.pending
	if activity == null:
		push_warning("[evening] Nothing to play; returning to the day screen.")
		get_tree().change_scene_to_file.call_deferred(WEEK_SCENE_PATH)
		return
	_set_background(activity.background)
	if Evenings.pending_timeline.is_empty() or not ResourceLoader.exists(Evenings.pending_timeline):
		_show_result_card(activity)
		return
	_start_timeline(Evenings.pending_timeline)


func _set_background(path: String) -> void:
	# Art slots may be wired before the art exists (docs/design/asset-brief.md);
	# fall back to the desk until it does.
	if path.is_empty() or not ResourceLoader.exists(path):
		path = Evenings.DEFAULT_BACKGROUND
	var texture: Texture2D = load(path)
	if texture != null:
		_background.texture = texture


func _start_timeline(path: String) -> void:
	if path.is_empty() or not ResourceLoader.exists(path):
		push_warning("[evening] Missing timeline %s." % path)
		_finish.call_deferred()
		return
	Dialogic.signal_event.connect(_on_dialogic_signal)
	Dialogic.timeline_ended.connect(_on_timeline_ended)
	Dialogic.start(path)


func _show_result_card(activity: Activity) -> void:
	_card.visible = true
	_title.text = GameState.fill(tr(activity.title))
	var text: String = activity.result_text if not activity.result_text.is_empty() else activity.description
	var variants: PackedStringArray = text.split(" || ")
	var times: int = maxi(GameState.count("activity_" + String(activity.id)), 1)
	_body.text = GameState.fill(tr(variants[(times - 1) % variants.size()]))


func _on_dialogic_signal(arg: Variant) -> void:
	if typeof(arg) == TYPE_STRING:
		Evenings.apply_scene_signal(arg)


func _on_timeline_ended() -> void:
	_finish()


func _finish() -> void:
	if _finished:
		return
	_finished = true
	if Dialogic.signal_event.is_connected(_on_dialogic_signal):
		Dialogic.signal_event.disconnect(_on_dialogic_signal)
	if Dialogic.timeline_ended.is_connected(_on_timeline_ended):
		Dialogic.timeline_ended.disconnect(_on_timeline_ended)
	if _is_beat:
		Story.finish()
		get_tree().change_scene_to_file.call_deferred(WEEK_SCENE_PATH)
		return
	Evenings.finish()
	get_tree().change_scene_to_file.call_deferred(GameState.end_day())
