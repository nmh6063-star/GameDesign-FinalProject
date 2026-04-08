extends Node2D
class_name BattleController

const BattleBox := preload("res://script/battle/field/box.gd")
const GameBall := preload("res://script/ball/game_ball.gd")
const BattleEnemy := preload("res://script/enemy/enemy.gd")
const EnemyHolderSlot := preload("res://script/enemy/holder.gd")
const BattleHud := preload("res://script/battle/ui/hud.gd")
const BattleState := preload("res://script/battle/state/state.gd")
const BattleContext := preload("res://script/battle/flow/context.gd")
const BattleRules := preload("res://script/battle/flow/rules.gd")

const BALL_SCENE_DIR := "res://scenes/balls"
const MERGE_SETTLE_TIME := 0.5
const BURST_AREA_RADIUS := 320.0
const SHOOT_BURST_STRENGTH_MULT := 10.0
const BURST_STRENGTH := 35.0
const AMPLIFIER_SHOT_MULT := 1.5
const PLAYER_DAMAGE_COLOR := Color(1, 0.3, 0.3)
const ENEMY_DAMAGE_COLOR := Color(0.92, 0.58, 0.06)
const HEAL_COLOR := Color(0.35, 0.92, 0.55)

var _state := BattleState.new()
var _ctx := BattleContext.new(self, _state)
var _rules := BattleRules.new()
var _box: BattleBox
var _selected_enemy_index := 0
var _turn_running := false

@onready var _root := get_tree().current_scene as Node2D
@onready var _ball_placeholder := _root.get_node("BallHolder/BallPlaceholder") as GameBall
@onready var _line_indicator := _root.get_node("BallHolder/LineIndicator")
@onready var _target := _root.get_node("Aim") as Node2D
@onready var _target_area := _target.get_node("Area2D") as Area2D
@onready var _player := _root.get_node("PlayerHolder/Player")
@onready var _player_bar := _root.get_node("PlayerHolder/PlayerHealthBar/Background") as ColorRect
@onready var _player_fill := _root.get_node("PlayerHolder/PlayerHealthBar/Fill") as ColorRect
@onready var _player_hp_label := _root.get_node("PlayerHolder/PlayerHealthBar/Label") as Label
@onready var _player_damage_anchor := _root.get_node("PlayerHolder/DamageAnchorPlayer") as Marker2D
@onready var _hud := _root.get_node("UI") as BattleHud
@onready var _enemy_holders := _find_enemy_holders()

func _ready() -> void:
	set_physics_process(false)
	call_deferred("_initialize")

func _initialize() -> void:
	randomize()
	_state.reset_for_battle()
	_box = BattleBox.new(_root, _ball_placeholder, _state, _target, _on_ball_dropped, BALL_SCENE_DIR)
	_spawn_enemies()
	_target.z_index = 999
	_hud.clear_result()
	_track_ball(null)
	_sync_player_bar()
	_sync_enemy_views()
	sync_shoot_ammo_hud()
	ensure_ball_in_play()
	set_physics_process(true)

func _physics_process(_delta: float) -> void:
	if _state.resolving_board:
		_rules.step_merge(_ctx)
		_rules.resolve_ball_effects(_ctx)
	if Input.is_action_just_pressed("left"):
		_step_enemy_selection(-1)
	elif Input.is_action_just_pressed("right"):
		_step_enemy_selection(1)
	_sync_enemy_views()
	_target.position = _root.get_local_mouse_position()
	_target.visible = (
		_state.phase == BattleState.Phase.PLAY
		and Input.is_action_pressed("shoot")
		and _state.shoot_ammo.can_shoot()
	)
	if Input.is_action_just_pressed("shoot"):
		_shoot()

func active_balls() -> Array: return _box.active()
func effect_balls() -> Array:
	var balls := active_balls()
	var current := _state.current_ball as GameBall
	if is_instance_valid(current) and current.visible and not current.is_queued_for_deletion():
		balls.append(current)
	return balls
func active_enemy() -> BattleEnemy:
	var holder: EnemyHolderSlot = _selected_enemy_holder()
	return holder.enemy if holder != null else null

func consume_ball(ball: GameBall) -> void:
	if _state.current_ball == ball:
		_state.current_ball = null
		_track_ball(null)
	_box.consume(ball)

func spawn_ball_copy(source: GameBall, offset: Vector2 = Vector2.ZERO) -> GameBall: return _box.spawn_copy(source, offset)
func wake_playfield() -> void: _box.wake()

func heal_player(amount: int) -> void:
	if amount <= 0:
		return
	RunState.heal_player(amount)
	_sync_player_bar()
	_hud.show_damage(amount, _player_damage_anchor, HEAL_COLOR)

func damage_enemy(amount: int, enemy: BattleEnemy = null) -> void:
	var target: BattleEnemy = enemy if enemy != null else active_enemy()
	if amount <= 0 or target == null or target.current_health <= 0:
		return
	var applied := mini(amount, target.current_health)
	var holder: EnemyHolderSlot = _enemy_holder(target)
	target.flash()
	target.apply_damage(applied)
	holder.show_damage(applied, ENEMY_DAMAGE_COLOR)
	if _alive_enemy_holders().is_empty():
		_finish_battle("Stage Clear")

func damage_player(amount: int) -> void:
	if amount <= 0 or RunState.player_health <= 0:
		return
	RunState.damage_player(amount)
	_player.flash()
	_sync_player_bar()
	_hud.show_damage(amount, _player_damage_anchor, PLAYER_DAMAGE_COLOR)
	if RunState.player_health == 0:
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

func sync_shoot_ammo_hud() -> void: _hud.sync_shoot_ammo(_state.shoot_ammo.bullets, _state.shoot_ammo.merge_progress)
func ensure_ball_in_play() -> void:
	if _state.phase != BattleState.Phase.PLAY or is_instance_valid(_state.current_ball):
		return
	_state.current_ball = _box.spawn_setup_ball()
	_track_ball(_state.current_ball)

func _shoot() -> void:
	if _state.phase != BattleState.Phase.PLAY or not _state.shoot_ammo.try_consume_shot():
		return
	var target_enemy: BattleEnemy = active_enemy()
	var hit_balls: Array[GameBall] = []
	var damage_total := 0
	var damage_mult := 1.0
	for body in _target_area.get_overlapping_bodies():
		if not body is GameBall:
			continue
		var ball: GameBall = body as GameBall
		hit_balls.append(ball)
		damage_total += ball.level
		if ball.has_tag("amplifier"):
			damage_mult *= AMPLIFIER_SHOT_MULT
	if damage_total > 0:
		damage_enemy(int(round(float(damage_total) * damage_mult)), target_enemy)
	for ball in hit_balls:
		consume_ball(ball)
	burst_knock_on_balls(_target.global_position, SHOOT_BURST_STRENGTH_MULT)
	sync_shoot_ammo_hud()

func _on_ball_dropped() -> void:
	if _turn_running or _state.phase != BattleState.Phase.PLAY:
		return
	_turn_running = true
	_state.current_ball = null
	_track_ball(null)
	_state.begin_resolution()
	await get_tree().create_timer(MERGE_SETTLE_TIME).timeout
	_state.lock_resolution()
	if _hud.has_result():
		_turn_running = false
		return
	_state.start_turn()
	sync_shoot_ammo_hud()
	ensure_ball_in_play()
	_turn_running = false

func _track_ball(ball) -> void: _line_indicator.track_ball(ball); _hud.sync_ball_queue(_box.preview())

func _find_enemy_holders() -> Array:
	var holders: Array = []
	for node in _root.find_children("EnemyHolder*", "", true, false):
		if node is EnemyHolderSlot: holders.append(node)
	return holders

func _enemy_holder(enemy: BattleEnemy):
	for holder in _enemy_holders:
		if holder.enemy == enemy:
			return holder
	return null

func _alive_enemy_holders() -> Array:
	var holders: Array = []
	for holder in _enemy_holders:
		if holder.enemy != null and holder.enemy.current_health > 0:
			holders.append(holder)
	return holders

func _selected_enemy_holder() -> EnemyHolderSlot:
	var holders := _alive_enemy_holders()
	if holders.is_empty():
		return null
	_selected_enemy_index = wrapi(_selected_enemy_index, 0, holders.size())
	return holders[_selected_enemy_index] as EnemyHolderSlot

func _step_enemy_selection(step: int) -> void:
	var count := _alive_enemy_holders().size()
	if count > 1:
		_selected_enemy_index = wrapi(_selected_enemy_index + step, 0, count)

func _spawn_enemies() -> void:
	for holder in _enemy_holders:
		var enemy: BattleEnemy = holder.spawn_enemy()
		if enemy != null: enemy.action_requested.connect(_on_enemy_action_requested.bind(enemy))

func _sync_player_bar() -> void:
	_player_fill.size.x = _player_bar.size.x * float(RunState.player_health) / float(RunState.player_max_health)
	_player_hp_label.text = "%d/%d" % [RunState.player_health, RunState.player_max_health]
func _sync_enemy_views() -> void:
	if _alive_enemy_holders().is_empty():
		_selected_enemy_index = 0
	var selected: EnemyHolderSlot = _selected_enemy_holder()
	for holder in _enemy_holders:
		holder.set_selected(holder == selected)
		holder.sync_view()
func _finish_battle(text: String) -> void:
	_state.phase = BattleState.Phase.RESOLVE
	_state.lock_resolution()
	_state.current_ball = null
	_turn_running = false
	_track_ball(null)
	_target.visible = false
	_hud.show_result(text)

func _on_enemy_action_requested(enemy: BattleEnemy) -> void:
	if _hud.has_result():
		return
	_rules.resolve_enemy_turn(_ctx, enemy)
