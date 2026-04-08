extends CanvasLayer
class_name BattleHud

const GameBall := preload("res://script/ball/game_ball.gd")
const ShootAmmo := preload("res://script/battle/state/ammo.gd")
const QUEUE_SIZE := 5
const DAMAGE_RISE_PX := 60.0
const DAMAGE_DURATION := 0.8
const DAMAGE_FONT_PX := 46

var _has_result := false
var _queue_keys: Array[String] = []

@onready var _top_frame: Control = $BallQueue/Center/Slots/Slot0/TopFrame
@onready var _queue_roots: Array[Node2D] = [
	$BallQueue/Center/Slots/Slot0/PreviewRoot, $BallQueue/Center/Slots/Slot1/PreviewRoot, $BallQueue/Center/Slots/Slot2/PreviewRoot, $BallQueue/Center/Slots/Slot3/PreviewRoot, $BallQueue/Center/Slots/Slot4/PreviewRoot,
]
@onready var _shoot_ammo_hud = $ShootAmmoHUD
@onready var _game_over: Control = $GameOver
@onready var _stage_clear: Control = $StageClear

func sync_ball_queue(items: Array) -> void:
	var next_keys: Array[String] = _queue_item_keys(items)
	_top_frame.visible = not items.is_empty()
	if next_keys == _queue_keys:
		return
	for i in range(QUEUE_SIZE):
		if i < next_keys.size() and i < _queue_keys.size() and next_keys[i] == _queue_keys[i]:
			continue
		var root: Node2D = _queue_roots[i]
		for child in root.get_children():
			child.queue_free()
		if i >= items.size():
			continue
		var item: Dictionary = items[i]
		var ball: GameBall = (item["scene"] as PackedScene).instantiate() as GameBall
		ball.ui_preview = true
		ball.set_preview(item["data"], item["level"])
		root.add_child(ball)
		ball.position = Vector2.ZERO
		ball.scale = Vector2.ONE * 0.72
	_queue_keys = next_keys


func _queue_item_keys(items: Array) -> Array[String]:
	var keys: Array[String] = []
	for item_value in items:
		var item: Dictionary = item_value
		keys.append("%s:%s:%d" % [(item["scene"] as PackedScene).resource_path, (item["data"] as Resource).resource_path, item["level"]])
	return keys


func sync_shoot_ammo(bullets: int, merge_progress: int) -> void:
	_shoot_ammo_hud.sync_state(bullets, merge_progress, ShootAmmo.MERGES_PER_BULLET)


func show_damage(amount: int, anchor: Marker2D, color: Color) -> void:
	if amount <= 0:
		return
	var floater := Label.new()
	add_child(floater)
	floater.global_position = anchor.global_position
	floater.text = str(amount)
	floater.modulate = color
	floater.modulate.a = 1.0
	floater.scale = Vector2.ONE
	floater.add_theme_font_size_override("font_size", DAMAGE_FONT_PX)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(floater, "position", floater.position + Vector2(0, -DAMAGE_RISE_PX), DAMAGE_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(floater, "scale", Vector2(1.48, 1.48), DAMAGE_DURATION * 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(floater, "modulate:a", 0.0, DAMAGE_DURATION).set_delay(DAMAGE_DURATION * 0.15)
	tween.set_parallel(false)
	tween.tween_callback(floater.queue_free)


func clear_result() -> void:
	_has_result = false
	_game_over.visible = false
	_stage_clear.visible = false


func show_result(text: String) -> void:
	_has_result = true
	_game_over.visible = text == "Game Over"
	_stage_clear.visible = text == "Stage Clear" or text == "Game Clear"


func has_result() -> bool:
	return _has_result
