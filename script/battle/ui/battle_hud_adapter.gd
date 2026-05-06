extends RefCounted
class_name BattleHudAdapter

const BallBase := preload("res://script/entities/balls/ball_base.gd")
const BattleContext := preload("res://script/battle/core/battle_context.gd")
const DOGICA_FONT := preload("res://assets/dogica/TTF/dogicabold.ttf")
const DAMAGE_RISE_PX := 60.0
const DAMAGE_DURATION := 0.8
const DAMAGE_FONT_PX := 46
const DAMAGE_JITTER_X := 0.0
const DAMAGE_JITTER_Y := 0.0
const DAMAGE_RISE_JITTER_X := 0.0

var _root: CanvasLayer

var _next_root: Node2D
var _hold_root: Node2D
var _queue_roots: Array[Node2D] = []
var _stats_hud: Control
var _cursor_mana_pipes: Control
var _mana_meter_fill: ColorRect
var _mana_meter_bg: ColorRect
var _mana_pipes_parent: HBoxContainer
var _combo_hud: Control
var _game_over: Control
var _stage_clear: Control
var _status_label: Label


func _init(root: CanvasLayer) -> void:
	_root = root
	_bind_nodes()


func sync_ball_queue(next_item: Dictionary, queue_items: Array, hold_item: Dictionary) -> void:
	_render_preview(_next_root, next_item, 0.78)
	_render_preview(_hold_root, hold_item, 0.78)
	for i in range(_queue_roots.size()):
		var item: Dictionary = {} if i >= queue_items.size() else queue_items[i]
		_render_preview(_queue_roots[i], item, 0.72)


func sync_mana(current: int, merge_progress: int) -> void:
	var merges := BattleContext.MERGES_PER_MANA_PIPE
	var used_scripts := false
	if _stats_hud != null and _stats_hud.has_method("sync_mana_meter"):
		_stats_hud.call("sync_mana_meter", merge_progress, merges)
		used_scripts = true
	if _cursor_mana_pipes != null and _cursor_mana_pipes.has_method("sync_pipes"):
		_cursor_mana_pipes.call("sync_pipes", current)
		used_scripts = true
	if used_scripts:
		return
	if _mana_meter_bg == null or _mana_meter_fill == null or _mana_pipes_parent == null:
		return
	var meter_inner_width := maxf(_mana_meter_bg.size.x - 4.0, 0.0)
	_mana_meter_fill.size.x = maxf(
		0.0,
		meter_inner_width * float(merge_progress) / float(max(BattleContext.MERGES_PER_MANA_PIPE, 1))
	)
	var i := 0
	for p in _mana_pipes_parent.get_children():
		if not p is Panel:
			continue
		if not p.visible:
			continue
		var pipe := p as Panel
		var sb := StyleBoxFlat.new()
		sb.set_corner_radius_all(8)
		sb.bg_color = Color(0.33, 0.66, 1.0, 1.0) if i < current else Color(0.62, 0.62, 0.68, 0.55)
		pipe.add_theme_stylebox_override("panel", sb)
		i += 1


func sync_combo(combo: int, multiplier: float, timer_ratio: float) -> void:
	if _combo_hud != null and _combo_hud.has_method("sync_state"):
		_combo_hud.call("sync_state", combo, multiplier, timer_ratio)

func show_damage(amount: int, anchor: Marker2D, color: Color) -> void:
	if amount <= 0:
		return
	var floater := Label.new()
	_root.add_child(floater)
	var jitter := Vector2(
		randf_range(-DAMAGE_JITTER_X, DAMAGE_JITTER_X),
		randf_range(-DAMAGE_JITTER_Y, DAMAGE_JITTER_Y)
	)
	floater.global_position = anchor.global_position + jitter
	floater.text = str(amount)
	floater.modulate = color
	floater.modulate.a = 1.0
	floater.scale = Vector2.ONE
	floater.add_theme_font_override("font", DOGICA_FONT)
	floater.add_theme_font_size_override("font_size", DAMAGE_FONT_PX)
	var rise_target := floater.position + Vector2(randf_range(-DAMAGE_RISE_JITTER_X, DAMAGE_RISE_JITTER_X), -DAMAGE_RISE_PX)
	var tween := _root.create_tween()
	tween.set_parallel(true)
	tween.tween_property(floater, "position", rise_target, DAMAGE_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(floater, "scale", Vector2(1.48, 1.48), DAMAGE_DURATION * 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(floater, "modulate:a", 0.0, DAMAGE_DURATION).set_delay(DAMAGE_DURATION * 0.15)
	tween.set_parallel(false)
	tween.tween_callback(floater.queue_free)


func sync_player_statuses(burn: int, freeze: int) -> void:
	if _status_label == null:
		return
	var parts: Array[String] = []
	if burn > 0:
		parts.append("Burn: %d" % burn)
	if freeze > 0:
		parts.append("Freeze: %d" % freeze)
	_status_label.text = "  |  ".join(parts)
	_status_label.visible = not parts.is_empty()


func clear_result() -> void:
	_game_over.visible = false
	_stage_clear.visible = false


func show_result(text: String) -> void:
	_game_over.visible = text == "Game Over"
	_stage_clear.visible = text == "Stage Clear" or text == "Game Clear"
	if _game_over.visible:
		_game_over.move_to_front()
	if _stage_clear.visible:
		_stage_clear.move_to_front()


func _bind_nodes() -> void:
	_next_root = _root.get_node("BallQueue/NextBox/Slot0/PreviewRoot") as Node2D
	_hold_root = _root.get_node("BallQueue/HoldBox/HoldSlot/PreviewRoot") as Node2D

	_queue_roots.clear()
	for i in range(1, 5):
		_queue_roots.append(_root.get_node("BallQueue/QueueBox/Center/Slots/Slot%d/PreviewRoot" % i) as Node2D)

	_stats_hud = _root.get_node_or_null("StatsHUD") as Control
	_cursor_mana_pipes = _root.get_node_or_null("CursorManaPipes") as Control
	_mana_meter_bg = _root.get_node_or_null("StatsHUD/Row/Meter/Background") as ColorRect
	_mana_meter_fill = _root.get_node_or_null("StatsHUD/Row/Meter/Fill") as ColorRect
	_mana_pipes_parent = _root.get_node_or_null("CursorManaPipes/ManaPipes") as HBoxContainer
	_combo_hud = _root.get_node_or_null("ComboHUD") as Control

	_game_over = _root.get_node("GameOver") as Control
	_stage_clear = _root.get_node("StageClear") as Control
	_status_label = _root.get_node_or_null("PlayerHealthBar/SpecialEffectBox/SpecialEffect") as Label


func _render_preview(root: Node2D, item: Dictionary, scale: float) -> void:
	for child in root.get_children():
		child.queue_free()
	if item.is_empty():
		return
	var ball: BallBase = (item["scene"] as PackedScene).instantiate() as BallBase
	ball.ui_preview = true
	print(item["scene"])
	root.add_child(ball)
	ball.set_preview(item["data"], int(item.get("rank", 1)))
	ball.position = Vector2.ZERO
	ball.scale = Vector2.ONE * scale
