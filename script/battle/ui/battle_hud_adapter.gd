extends RefCounted
class_name BattleHudAdapter

const BallBase := preload("res://script/entities/balls/ball_base.gd")
const BallCatalog := preload("res://script/entities/balls/ball_catalog.gd")
const BattleContext := preload("res://script/battle/core/battle_context.gd")
const DOGICA_FONT := preload("res://assets/dogica/TTF/dogicabold.ttf")
const DAMAGE_RISE_PX := 60.0
const DAMAGE_DURATION := 0.8
const DAMAGE_FONT_PX := 46
const DAMAGE_JITTER_X := 0.0
const DAMAGE_JITTER_Y := 0.0
const DAMAGE_RISE_JITTER_X := 0.0
const SPECIAL_SLOT_COUNT := 4
const ATTACK_READY_COLOR := Color(0.98, 0.58, 0.13, 1.0)
const ATTACK_LOCKED_COLOR := Color(0.34, 0.3, 0.3, 1.0)
const ATTACK_BORDER_COLOR := Color(1.0, 0.91, 0.32, 1.0)

var _root: CanvasLayer

var _next_root: Node2D
var _hold_root: Node2D
var _queue_roots: Array[Node2D] = []
var _mana_hud: Control
var _mana_meter_fill: ColorRect
var _mana_meter_bg: ColorRect
var _mana_pipes_parent: HBoxContainer
var _combo_hud: Control
var _special_panels: Array[Panel] = []
var _special_roots: Array[Node2D] = []
var _special_names: Array[Label] = []
var _special_costs: Array[Label] = []
var _special_keys: Array[Label] = []
var _attack_panel: Panel
var _attack_cost_badge: Panel
var _attack_title: Label
var _attack_key: Label
var _attack_style_base: StyleBoxFlat
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


func sync_special_bar(slot_items: Array, mana: int, action_mode_active: bool, can_attack: bool) -> void:
	for i in range(SPECIAL_SLOT_COUNT):
		var panel := _special_panels[i]
		var name_label := _special_names[i]
		var cost_label := _special_costs[i]
		var key_label := _special_keys[i]
		var item: Dictionary = {} if i >= slot_items.size() else slot_items[i]
		key_label.text = str(i + 1)
		if item.is_empty():
			panel.modulate = Color(1, 1, 1, 0.18)
			name_label.text = ""
			cost_label.text = ""
			_render_preview(_special_roots[i], {}, 0.84)
			continue
		var cost := BallCatalog.special_cost(item["id"])
		var affordable := mana >= cost
		panel.modulate = Color.WHITE if affordable else Color(1, 1, 1, 0.4)
		name_label.text = _compact_name(item["data"].display_name)
		cost_label.text = str(cost)
		_render_preview(_special_roots[i], item, 0.84)
	_set_attack_slot_state(can_attack, action_mode_active)
	_attack_title.text = "ATTACK" if can_attack else "LOCKED"
	_attack_key.text = "X"


func sync_mana(current: int, merge_progress: int) -> void:
	if _mana_hud != null and _mana_hud.has_method("sync_state"):
		_mana_hud.call("sync_state", current, merge_progress, BattleContext.MERGES_PER_MANA_PIPE)
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
		sb.set_corner_radius_all(11)
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

	_mana_hud = _root.get_node_or_null("ManaHUD") as Control
	_mana_meter_bg = _root.get_node_or_null("ManaHUD/Row/Meter/Background") as ColorRect
	_mana_meter_fill = _root.get_node_or_null("ManaHUD/Row/Meter/Fill") as ColorRect
	_mana_pipes_parent = _root.get_node_or_null("ManaHUD/Row/ManaPipes") as HBoxContainer
	_combo_hud = _root.get_node_or_null("ComboHUD") as Control

	_special_panels.clear()
	_special_roots.clear()
	_special_names.clear()
	_special_costs.clear()
	_special_keys.clear()
	for i in range(SPECIAL_SLOT_COUNT):
		var slot_path := "SpecialBar/Slots/Slot%d" % i
		_special_panels.append(_root.get_node(slot_path) as Panel)
		_special_roots.append(_root.get_node("%s/PreviewRoot" % slot_path) as Node2D)
		_special_names.append(_root.get_node("%s/Name" % slot_path) as Label)
		_special_costs.append(_root.get_node("%s/CostBadge/Cost" % slot_path) as Label)
		_special_keys.append(_root.get_node("%s/Key" % slot_path) as Label)

	_attack_panel = _root.get_node("SpecialBar/Slots/AttackSlot") as Panel
	_attack_cost_badge = _root.get_node_or_null("SpecialBar/Slots/AttackSlot/CostBadge") as Panel
	_attack_title = _root.get_node("SpecialBar/Slots/AttackSlot/Title") as Label
	_attack_key = _root.get_node("SpecialBar/Slots/AttackSlot/Key") as Label
	var attack_style := _attack_panel.get_theme_stylebox("panel")
	if attack_style is StyleBoxFlat:
		_attack_style_base = (attack_style as StyleBoxFlat).duplicate() as StyleBoxFlat

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
	ball.set_preview(item["data"], int(item.get("rank", 1)))
	root.add_child(ball)
	ball.position = Vector2.ZERO
	ball.scale = Vector2.ONE * scale


func _set_attack_slot_state(can_attack: bool, action_mode_active: bool) -> void:
	_attack_panel.modulate = Color.WHITE if can_attack else Color(1, 1, 1, 0.4)
	if _attack_cost_badge != null:
		_attack_cost_badge.modulate = Color.WHITE if can_attack else Color(1, 1, 1, 0.4)
	if _attack_style_base != null:
		var style := _attack_style_base.duplicate() as StyleBoxFlat
		style.bg_color = ATTACK_READY_COLOR if can_attack else ATTACK_LOCKED_COLOR
		var highlighted := can_attack and action_mode_active
		style.border_width_left = 3 if highlighted else 0
		style.border_width_top = 3 if highlighted else 0
		style.border_width_right = 3 if highlighted else 0
		style.border_width_bottom = 3 if highlighted else 0
		style.border_color = ATTACK_BORDER_COLOR
		_attack_panel.add_theme_stylebox_override("panel", style)


func _compact_name(name: String) -> String:
	return name.replace(" Ball", "\nBall")
