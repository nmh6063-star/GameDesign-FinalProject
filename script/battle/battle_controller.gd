extends Node2D
class_name BattleController

const GameBall := preload("res://script/ball/game_ball.gd")
const BallData := preload("res://script/ball/ball_data.gd")
const BattleState := preload("res://script/battle/battle_state.gd")
const BattleContext := preload("res://script/battle/battle_context.gd")
const BattleRules := preload("res://script/battle/battle_rules.gd")
const ShootAmmo := preload("res://script/combat/shoot_ammo.gd")
const DAMAGE_FLOATER_SCENE := preload("res://scenes/damage_floater.tscn")

const BALL_CONTENT_DIR := "res://content/balls"
const MERGE_SETTLE_TIME := 0.5
const TURN_END_DELAY := 0.0
const BURST_AREA_RADIUS := 320.0
const SHOOT_BURST_STRENGTH_MULT := 10.0
const PLAYER_DAMAGE_COLOR := Color(1, 0.3, 0.3)
const ENEMY_DAMAGE_COLOR := Color(0.92, 0.58, 0.06)
const HEAL_COLOR := Color(0.35, 0.92, 0.55)

var _state := BattleState.new()
var _ctx := BattleContext.new(self, _state)
var _rules := BattleRules.new()
var _spawn_pool: Array[BallData] = []
var _spawn_position := Vector2.ZERO
var _initialized := false
var _turn_running := false

@onready var _root := get_parent() as Node2D
@onready var _template_ball := _root.get_node("Ball") as GameBall
@onready var _line_indicator := _root.get_node("LineIndicator")
@onready var _target := _root.get_node("Target") as Node2D
@onready var _target_area := _target.get_node("Area2D") as Area2D
@onready var _player := _root.get_node("PlayerHolder/Player")
@onready var _enemy := _root.get_node("EnemyHolder/Enemy")
@onready var _player_fill := _root.get_node("UI/PlayerHealthBar/Fill") as ColorRect
@onready var _player_hp_text := _root.get_node("UI/PlayerHealthBar/HPText") as Label
@onready var _player_hp_top := _root.get_node("UI/TopBar/PlayerHPText") as Label
@onready var _energy_label := _root.get_node("UI/EnergyLabel") as Label
@onready var _energy_badge_text := _root.get_node("UI/CostBadge/CostText") as Label
@onready var _result_label := _root.get_node("UI/ResultLabel") as Label
@onready var _shoot_ammo_hud := _root.get_node("UI/ShootAmmoHUD")
@onready var _burst_slider := _root.get_node("UI/HSlider") as HSlider
@onready var _damage_anchor_player := _root.get_node("UI/DamageAnchorPlayer")
@onready var _damage_anchor_enemy := _root.get_node("UI/DamageAnchorEnemy")


func _ready() -> void:
	call_deferred("_initialize")


func _initialize() -> void:
	randomize()
	_spawn_pool = _load_ball_pool()
	assert(not _spawn_pool.is_empty(), "No ball content found in %s" % BALL_CONTENT_DIR)
	_spawn_position = _template_ball.position
	_state.reset_for_battle()
	_target.z_index = 999
	if not _enemy.action_requested.is_connected(_on_enemy_action_requested):
		_enemy.action_requested.connect(_on_enemy_action_requested)
	_template_ball.set_runtime(_state, _target)
	_template_ball.set_collision_enabled(false)
	_enemy.setup()
	_result_label.visible = false
	_track_ball(null)
	_update_player_bar()
	_update_energy_ui()
	sync_shoot_ammo_hud()
	ensure_ball_in_play()
	_initialized = true


func _physics_process(_delta: float) -> void:
	if not _initialized:
		return
	if _state.resolving_board:
		_rules.step_merge(_ctx)
		_rules.resolve_ball_effects(_ctx)
	_target.position = _root.get_local_mouse_position()
	_target.visible = (
		_state.phase == BattleState.Phase.PLAY
		and Input.is_action_pressed("shoot")
		and _state.shoot_ammo.can_shoot()
	)
	if Input.is_action_just_pressed("shoot"):
		_shoot()


func active_balls() -> Array:
	var out: Array = []
	for node in get_tree().get_nodes_in_group("ball"):
		if not node is GameBall:
			continue
		var ball := node as GameBall
		if ball == _template_ball or ball.set_up or not ball.visible or ball.is_queued_for_deletion():
			continue
		out.append(ball)
	return out


func active_enemy():
	return _enemy


func consume_ball(ball: GameBall) -> void:
	if _state.current_ball == ball:
		_state.current_ball = null
		_track_ball(null)
	ball.visible = false
	ball.set_up = false
	ball.remove_from_group("ball")
	ball.queue_free()


func spawn_ball_copy(source: GameBall, offset: Vector2 = Vector2.ZERO) -> GameBall:
	return _spawn_ball(source.data, source.level, source.position + offset, false)


func wake_playfield() -> void:
	for node in get_tree().get_nodes_in_group("ball"):
		if node is RigidBody2D and not (node as Node).is_queued_for_deletion():
			(node as RigidBody2D).sleeping = false


func heal_player(amount: int) -> void:
	if amount <= 0:
		return
	RunState.heal_player(amount)
	_update_player_bar()
	_spawn_damage_floater_on_node(amount, _damage_anchor_player, HEAL_COLOR)


func damage_enemy(amount: int) -> void:
	if amount <= 0 or _enemy.current_health <= 0:
		return
	_enemy.flash()
	_enemy.apply_damage(amount)
	_spawn_damage_floater_on_node(amount, _damage_anchor_enemy, ENEMY_DAMAGE_COLOR)
	if _enemy.current_health == 0:
		_finish_battle("Game Clear")


func damage_player(amount: int) -> void:
	if amount <= 0 or RunState.player_health <= 0:
		return
	RunState.damage_player(amount)
	_player.flash()
	_update_player_bar()
	_spawn_damage_floater_on_node(amount, _damage_anchor_player, PLAYER_DAMAGE_COLOR)
	if RunState.player_health == 0:
		_finish_battle("Game Over")


func burst_knock_on_balls(origin_global: Vector2, strength_scale: float = 1.0) -> void:
	var strength := _burst_slider.value * strength_scale
	var radius_squared := BURST_AREA_RADIUS * BURST_AREA_RADIUS
	for node in get_tree().get_nodes_in_group("ball"):
		if not node is RigidBody2D:
			continue
		var body := node as RigidBody2D
		if body == _template_ball or body.is_queued_for_deletion():
			continue
		var offset := body.global_position - origin_global
		var distance_squared := offset.length_squared()
		if distance_squared == 0.0 or distance_squared > radius_squared:
			continue
		body.apply_central_impulse(offset.normalized() * strength)


func sync_shoot_ammo_hud() -> void:
	_shoot_ammo_hud.sync_state(
		_state.shoot_ammo.bullets,
		_state.shoot_ammo.merge_progress,
		ShootAmmo.MERGES_PER_BULLET,
	)


func ensure_ball_in_play() -> void:
	if _state.phase != BattleState.Phase.PLAY or is_instance_valid(_state.current_ball):
		return
	var data := _roll_ball_data()
	var ball := _spawn_ball(data, data.random_spawn_level(), _spawn_position, true)
	_state.current_ball = ball
	_track_ball(ball)


func _spawn_ball(data: BallData, level: int, position: Vector2, is_set_up: bool) -> GameBall:
	var ball := _template_ball.duplicate() as GameBall
	_root.add_child(ball)
	ball.position = position
	ball.visible = true
	ball.configure(data, level, _state, _target)
	ball.set_collision_enabled(true)
	ball.set_playfield_state(is_set_up)
	if is_set_up:
		ball.dropped.connect(_on_ball_dropped)
	return ball


func _shoot() -> void:
	if _state.phase != BattleState.Phase.PLAY or not _state.shoot_ammo.try_consume_shot():
		return
	for body in _target_area.get_overlapping_bodies():
		if not body is GameBall:
			continue
		damage_enemy((body as GameBall).level)
		consume_ball(body as GameBall)
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
	if _result_label.visible:
		_turn_running = false
		return
	await get_tree().create_timer(TURN_END_DELAY).timeout
	if _result_label.visible:
		_turn_running = false
		return
	_state.start_turn()
	_update_energy_ui()
	sync_shoot_ammo_hud()
	ensure_ball_in_play()
	_turn_running = false


func _load_ball_pool() -> Array[BallData]:
	var pool: Array[BallData] = []
	for file_name in DirAccess.get_files_at(BALL_CONTENT_DIR):
		if not file_name.ends_with(".tres"):
			continue
		var data := load("%s/%s" % [BALL_CONTENT_DIR, file_name]) as BallData
		if data.spawn_weight > 0:
			pool.append(data)
	return pool


func _roll_ball_data() -> BallData:
	var total_weight := 0
	for data in _spawn_pool:
		total_weight += data.spawn_weight
	var roll := randi_range(1, total_weight)
	for data in _spawn_pool:
		roll -= data.spawn_weight
		if roll <= 0:
			return data
	return _spawn_pool[0]


func _track_ball(ball) -> void:
	_line_indicator.track_ball(ball)


func _update_player_bar() -> void:
	_player_fill.size.x = 100.0 * float(RunState.player_health) / float(RunState.player_max_health)
	_player_hp_text.text = "%d/%d" % [RunState.player_health, RunState.player_max_health]
	_player_hp_top.text = "%d/%d" % [RunState.player_health, RunState.player_max_health]


func _update_energy_ui() -> void:
	_energy_label.visible = true
	_energy_label.text = "Energy"
	_energy_badge_text.text = "%d/%d" % [_state.player_energy, _state.player_energy_max]


func _spawn_damage_floater_on_node(amount: int, target, color: Color) -> void:
	if amount <= 0:
		return
	var floater := DAMAGE_FLOATER_SCENE.instantiate()
	_root.get_node("UI").add_child(floater)
	if target is Node2D:
		(floater as Label).global_position = (target as Node2D).global_position
	elif target is Control:
		(floater as Label).global_position = (target as Control).global_position
	floater.play(amount, color)


func _finish_battle(text: String) -> void:
	_state.phase = BattleState.Phase.RESOLVE
	_state.lock_resolution()
	_state.current_ball = null
	_turn_running = false
	_track_ball(null)
	_target.visible = false
	_result_label.text = text
	_result_label.visible = true


func _on_enemy_action_requested() -> void:
	if not _initialized or _result_label.visible:
		return
	_rules.resolve_enemy_turn(_ctx)
