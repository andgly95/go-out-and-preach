extends Control
## Plays the activity chosen on the day screen (Evenings.pending): its scene
## timeline over a backdrop, or a single result line when it has none. Scene
## [signal] events go to Evenings.apply_scene_signal. Ends the day through
## GameState.

const WEEK_SCENE_PATH: String = "res://scenes/week_view.tscn"

@onready var _background: TextureRect = $Background
@onready var _card: PanelContainer = $Card
@onready var _title: Label = $Card/Margin/VBox/Title
@onready var _body: Label = $Card/Margin/VBox/Body
@onready var _continue: Button = $Card/Margin/VBox/Continue

var _finished: bool = false


func _ready() -> void:
	var activity: Activity = Evenings.pending
	if activity == null:
		push_warning("[evening] No pending activity; returning to the day screen.")
		get_tree().change_scene_to_file.call_deferred(WEEK_SCENE_PATH)
		return
	var texture: Texture2D = load(Evenings.background_for(activity))
	if texture != null:
		_background.texture = texture
	_continue.pressed.connect(_finish)
	if Evenings.pending_timeline.is_empty() or not ResourceLoader.exists(Evenings.pending_timeline):
		_show_result_card(activity)
		return
	DialogicResourceUtil.update_directory(".dch")
	DialogicResourceUtil.update_directory(".dtl")
	Dialogic.signal_event.connect(_on_dialogic_signal)
	Dialogic.timeline_ended.connect(_on_timeline_ended)
	Dialogic.start(Evenings.pending_timeline)


func _show_result_card(activity: Activity) -> void:
	_card.visible = true
	_title.text = GameState.fill(tr(activity.title))
	_body.text = GameState.fill(tr(activity.result_text if not activity.result_text.is_empty() else activity.description))


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
	Evenings.finish()
	get_tree().change_scene_to_file.call_deferred(GameState.end_day())
