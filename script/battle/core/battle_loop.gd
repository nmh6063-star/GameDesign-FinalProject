extends Node2D
class_name BattleLoop

const BallBase := preload("res://script/entities/balls/ball_base.gd")
const EnemyBase := preload("res://script/entities/enemies/enemy_base.gd")
const BattleContext := preload("res://script/battle/core/battle_context.gd")
const BattleResolver := preload("res://script/battle/core/battle_resolver.gd")
const BattleBallManager := preload("res://script/battle/controllers/battle_ball_manager.gd")
const EnemySlotController := preload("res://script/battle/controllers/enemy_slot_controller.gd")
const RewardSelectionController := preload("res://script/battle/controllers/reward_selection_controller.gd")
const BattleHudAdapter := preload("res://script/battle/ui/battle_hud_adapter.gd")
const REWARD_SELECTION_SCENE := preload("res://scenes/reward_selection.tscn")

const BURST_AREA_RADIUS := 320.0
const BURST_STRENGTH := 35.0
const DESTROYING_META := "_battle_destroying"
const PLAYER_DAMAGE_COLOR := Color(1, 0.3, 0.3)
const ENEMY_DAMAGE_COLOR := Color(0.92, 0.58, 0.06)
const HEAL_COLOR := Color(0.35, 0.92, 0.55)
const MERGE_SETTLE_TIME := 0.5
const SHOOT_BURST_STRENGTH_MULT := 10.0

var _context := BattleContext.new(self)
var _resolver := BattleResolver.new()
var _box: BattleBallManager
var _hud: BattleHudAdapter
var _turn_running := false
var _selected_enemy_index := 0
var _enemy_slots: Array = []

var _reward_overlay: RewardSelectionController

@onready var _root := get_tree().current_scene as Node2D
@onready var _ball_placeholder := _root.get_node("BallHolder/BallPlaceholder") as BallBase
@onready var _line_indicator := _root.get_node("BallHolder/LineIndicator")
@onready var _target := _root.get_node("Aim") as Node2D
@onready var _target_area := _target.get_node("Area2D") as Area2D
@onready var _player := _root.get_node("PlayerHolder/Player")
@onready var _player_bar := _root.get_node("UI/PlayerHealthBar/Background") as ColorRect
@onready var _player_fill := _root.get_node("UI/PlayerHealthBar/Fill") as ColorRect
@onready var _player_hp_label := _root.get_node("UI/PlayerHealthBar/Label") as Label
@onready var _player_damage_anchor := _root.get_node("PlayerHolder/DamageAnchorPlayer") as Marker2D
@onready var _enemy_slot_root := _root.get_node("EnemySlot") as Node2D
@onready var _ui_root := _root.get_node("UI") as CanvasLayer


func _ready() -> void:
	_hud = BattleHudAdapter.new(_ui_root)
	_enemy_slots = _build_enemy_slots()
	set_physics_process(false)
	call_deferred("_initialize")


func _initialize() -> void:
	_begin_battle()


func _begin_battle() -> void:
	randomize()
	_context.reset_for_battle()
	if _should_skip_reward_selection():
		_begin_stage()
		return
	_show_reward_selection()


func _physics_process(_delta: float) -> void:
	_step_battle_resolution()
	_handle_selection_input()
	_update_enemy_realtime_views()
	_update_target_visual()
	_handle_shoot_input()


func _step_battle_resolution() -> void:
	if _context.resolving_board:
		_resolver.resolve_frame(_context)


func _handle_selection_input() -> void:
	if Input.is_action_just_pressed("left"):
		if _step_enemy_selection(-1):
			sync_enemy_views()
	elif Input.is_action_just_pressed("right"):
		if _step_enemy_selection(1):
			sync_enemy_views()


func _update_enemy_realtime_views() -> void:
	for slot in _enemy_slots:
		slot.sync_realtime_view()


func _update_target_visual() -> void:
	_target.position = _root.get_local_mouse_position()
	_target.visible = (
		_context.phase == BattleContext.Phase.PLAY
		and Input.is_action_pressed("shoot")
		and _context.can_shoot()
	)


func _handle_shoot_input() -> void:
	if Input.is_action_just_pressed("shoot"):
		try_shoot(_target_area, _target.global_position)


func ensure_ball_in_play() -> void:
	if _context.phase != BattleContext.Phase.PLAY or is_instance_valid(_context.current_ball):
		return
	_context.current_ball = spawn_setup_ball()
	track_ball(_context.current_ball)


func try_shoot(target_area: Area2D, burst_origin: Vector2) -> void:
	if _context.phase != BattleContext.Phase.PLAY or not _context.try_consume_shot():
		return
	var target_enemy: EnemyBase = active_enemy()
	var hit_balls := _targeted_balls(target_area)
	var damage_total := 0
	var damage_multiplier := 1.0
	for ball in hit_balls:
		damage_total += ball.shot_base_damage()
		damage_multiplier *= ball.shot_damage_multiplier()
	if damage_total > 0:
		damage_enemy(int(round(float(damage_total) * damage_multiplier)), target_enemy, _context)
	for ball in hit_balls:
		ball.on_shot(_context)
	burst_knock_on_balls(burst_origin, SHOOT_BURST_STRENGTH_MULT)
	sync_shoot_ammo_hud()


func _complete_turn_after_drop() -> void:
	if _turn_running or _context.phase != BattleContext.Phase.PLAY:
		return
	_turn_running = true
	_clear_current_ball()
	_context.begin_resolution()
	await get_tree().create_timer(MERGE_SETTLE_TIME).timeout
	_end_turn()
	_turn_running = false


func resolve_enemy_turn(enemy: EnemyBase = null) -> void:
	var acting_enemy: EnemyBase = active_enemy() if enemy == null else enemy
	if acting_enemy == null or not acting_enemy.is_alive():
		return
	acting_enemy.on_turn(_context)


func active_balls() -> Array:
	return _box.active() if _box != null else []


func effect_balls() -> Array:
	var balls := active_balls()
	var current := _context.current_ball as BallBase
	if is_instance_valid(current) and current.is_active_for_effects():
		balls.append(current)
	return balls


func active_enemy() -> EnemyBase:
	var slot: EnemySlotController = _selected_enemy_slot()
	return slot.enemy if slot != null else null


func consume_ball(ball: BallBase, ctx: BattleContext = null) -> void:
	if not is_instance_valid(ball) or ball.is_queued_for_deletion():
		return
	if _context.current_ball == ball:
		_clear_current_ball()
	if ctx != null and not bool(ball.get_meta(DESTROYING_META, false)):
		ball.set_meta(DESTROYING_META, true)
		ball.on_destroy(ctx)
		ball.remove_meta(DESTROYING_META)
		if ball.is_queued_for_deletion():
			return
	if _box != null:
		_box.consume(ball)


func spawn_ball_copy(source: BallBase, offset: Vector2 = Vector2.ZERO) -> BallBase:
	return _box.spawn_copy(source, offset) if _box != null else null


func spawn_ball(ball_id: String, origin_global: Vector2, impulse: Vector2 = Vector2.ZERO, level: int = 1) -> BallBase:
	return _box.spawn_ball(ball_id, level, origin_global, impulse) if _box != null else null


func drop_ball_in_box(ball_id: String, level: int = 1) -> BallBase:
	return _box.drop_ball(ball_id, level) if _box != null else null


func spawn_setup_ball() -> BallBase:
	return _box.spawn_setup_ball() if _box != null else null


func heal_player(amount: int) -> void:
	if amount <= 0:
		return
	PlayerState.heal(amount)
	_sync_player_bar()
	_hud.show_damage(amount, _player_damage_anchor, HEAL_COLOR)


func damage_enemy(amount: int, enemy: EnemyBase = null, ctx: BattleContext = null) -> void:
	var target: EnemyBase = enemy if enemy != null else active_enemy()
	if amount <= 0 or target == null or not target.is_alive():
		return
	var slot: EnemySlotController = _enemy_slot(target)
	target.flash()
	var applied := target.take_damage_with_context(amount, ctx)
	if applied <= 0:
		return
	if slot != null:
		slot.sync_realtime_view()
		slot.show_damage(applied, ENEMY_DAMAGE_COLOR)
	if _alive_enemy_slots().is_empty():
		_finish_battle("Stage Clear")


func damage_player(amount: int) -> void:
	if amount <= 0 or PlayerState.player_health <= 0:
		return
	PlayerState.damage(amount)
	_player.flash()
	_sync_player_bar()
	_hud.show_damage(amount, _player_damage_anchor, PLAYER_DAMAGE_COLOR)
	if PlayerState.player_health == 0:
		_finish_battle("Game Over")


func burst_knock_on_balls(origin_global: Vector2, strength_scale: float = 1.0) -> void:
	var strength := BURST_STRENGTH * strength_scale
	var radius_squared := BURST_AREA_RADIUS * BURST_AREA_RADIUS
	for node in get_tree().get_nodes_in_group("ball"):
		if not node is RigidBody2D:
			continue
		var body := node as RigidBody2D
		if body == _ball_placeholder or body.is_queued_for_deletion():
			continue
		var offset := body.global_position - origin_global
		var distance_squared := offset.length_squared()
		if distance_squared == 0.0 or distance_squared > radius_squared:
			continue
		body.apply_central_impulse(offset.normalized() * strength)


func sync_shoot_ammo_hud() -> void:
	_hud.sync_shoot_ammo(_context.bullets, _context.merge_progress)


func track_ball(ball) -> void:
	_line_indicator.call("track_ball", ball)
	if _box != null:
		_hud.sync_ball_queue(_box.preview())


func has_battle_result() -> bool:
	return _context.has_battle_result()


func sync_enemy_views() -> void:
	if _alive_enemy_slots().is_empty():
		_selected_enemy_index = 0
	var selected: EnemySlotController = _selected_enemy_slot()
	for slot in _enemy_slots:
		slot.set_selected(slot == selected)
		slot.sync_view()


func _show_reward_selection() -> void:
	_reward_overlay = REWARD_SELECTION_SCENE.instantiate() as RewardSelectionController
	_reward_overlay.selection_completed.connect(_on_reward_selection_completed)
	_root.add_child(_reward_overlay)


func _on_reward_selection_completed(ball_ids: Array[String]) -> void:
	for ball_id in ball_ids:
		BattleLoadout.add_ball_to_pool(ball_id)
	_reward_overlay = null
	_begin_stage()


func _begin_stage() -> void:
	_context.clear_battle_result()
	_box = BattleBallManager.new(
		_root,
		_ball_placeholder,
		_context,
		_target,
		_on_ball_dropped,
		BattleLoadout.ball_pool_ids()
	)
	_spawn_enemies()
	_target.z_index = 999
	_hud.clear_result()
	track_ball(null)
	_sync_player_bar()
	set_physics_process(true)
	_begin_turn()


func _on_ball_dropped() -> void:
	_complete_turn_after_drop()


func _begin_turn() -> void:
	_context.start_turn()
	sync_enemy_views()
	sync_shoot_ammo_hud()
	ensure_ball_in_play()


func _end_turn() -> void:
	_context.lock_resolution()
	sync_enemy_views()
	if has_battle_result():
		return
	_begin_turn()


func _clear_current_ball() -> void:
	_context.current_ball = null
	track_ball(null)


func _enemy_slot(enemy: EnemyBase) -> EnemySlotController:
	for slot in _enemy_slots:
		if slot.enemy == enemy:
			return slot
	return null


func _alive_enemy_slots() -> Array:
	var slots: Array = []
	for slot in _enemy_slots:
		if slot.is_alive():
			slots.append(slot)
	return slots


func _selected_enemy_slot() -> EnemySlotController:
	var slots := _alive_enemy_slots()
	if slots.is_empty():
		return null
	_selected_enemy_index = wrapi(_selected_enemy_index, 0, slots.size())
	return slots[_selected_enemy_index] as EnemySlotController


func _step_enemy_selection(step: int) -> bool:
	var count := _alive_enemy_slots().size()
	if count <= 1:
		return false
	var next_index := wrapi(_selected_enemy_index + step, 0, count)
	if next_index == _selected_enemy_index:
		return false
	_selected_enemy_index = next_index
	return true


func _spawn_enemies() -> void:
	for slot in _enemy_slots:
		var enemy: EnemyBase = slot.spawn_enemy()
		if enemy != null:
			enemy.action_requested.connect(_on_enemy_action_requested.bind(enemy))


func _sync_player_bar() -> void:
	_player_fill.size.x = _player_bar.size.x * float(PlayerState.player_health) / float(PlayerState.player_max_health)
	_player_hp_label.text = "%d/%d" % [PlayerState.player_health, PlayerState.player_max_health]


func _finish_battle(text: String) -> void:
	if _context.has_battle_result():
		return
	_context.finish_battle(text)
	_context.phase = BattleContext.Phase.RESOLVE
	_context.lock_resolution()
	_clear_current_ball()
	_target.visible = false
	set_physics_process(false)
	_hud.show_result(text)
	var game_manager := _game_manager()
	if game_manager == null:
		return
	await get_tree().create_timer(1.1).timeout
	if not is_inside_tree():
		return
	if text == "Game Over":
		game_manager.call("restart_run")
		return
	game_manager.call("complete_current_room")


func _on_enemy_action_requested(enemy: EnemyBase) -> void:
	if has_battle_result():
		return
	resolve_enemy_turn(enemy)


func _targeted_balls(target_area: Area2D) -> Array:
	var hit_balls: Array = []
	for body in target_area.get_overlapping_bodies():
		if not body is BallBase:
			continue
		var ball := body as BallBase
		if ball.can_be_hit_by_shot():
			hit_balls.append(ball)
	return hit_balls


func _build_enemy_slots() -> Array:
	var slots: Array = []
	for child in _enemy_slot_root.get_children():
		if not child is Node2D:
			continue
		var slot := child as Node2D
		var spawn := _spawn_marker_for_slot(slot)
		slots.append(EnemySlotController.new(slot, spawn, _enemy_id_for_slot(spawn)))
	return slots


func _spawn_marker_for_slot(slot: Node2D) -> Marker2D:
	for child in slot.get_children():
		if child is Marker2D and child.name.begins_with("EnemySpawn"):
			return child as Marker2D
	return null


func _enemy_id_for_slot(spawn: Marker2D) -> String:
	if spawn == null or not spawn.name.begins_with("EnemySpawn_"):
		return ""
	return spawn.name.trim_prefix("EnemySpawn_")


func _game_manager() -> Node:
	return get_node_or_null("/root/GameManager")


func _should_skip_reward_selection() -> bool:
	var game_manager := _game_manager()
	if game_manager == null:
		return false
	if not game_manager.has_method("should_skip_battle_rewards"):
		return false
	return bool(game_manager.call("should_skip_battle_rewards"))
