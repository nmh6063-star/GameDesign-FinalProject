extends Node2D
class_name BattleController

const BattleBox := preload("res://script/battle/field/box.gd")
const GameBall := preload("res://script/ball/game_ball.gd")
const BattleHud := preload("res://script/battle/ui/hud.gd")
const BattleState := preload("res://script/battle/state/state.gd")
const BattleContext := preload("res://script/battle/flow/context.gd")
const BattleRules := preload("res://script/battle/flow/rules.gd")

const BALL_CONTENT_DIR := "res://content/balls"
const MERGE_SETTLE_TIME := 0.5
const BURST_AREA_RADIUS := 320.0
const SHOOT_BURST_STRENGTH_MULT := 10.0

var _state := BattleState.new()
var _ctx := BattleContext.new(self, _state)
var _rules := BattleRules.new()
var _box: BattleBox
var _turn_running := false
var ball_pulls = []

@onready var _root := get_parent() as Node2D
@onready var _template_ball := preload("res://scenes/ball.tscn")
@onready var _line_indicator := _root.get_node("LineIndicator")
@onready var _target := _root.get_node("Target") as Node2D
@onready var _target_area := _target.get_node("Area2D") as Area2D
@onready var _player := _root.get_node("PlayerHolder/Player")
@onready var _enemy := _root.get_node("EnemyHolder/Enemy")
@onready var _hud := _root.get_node("UI") as BattleHud
@onready var _burst_slider := _root.get_node("UI/HSlider") as HSlider


func _ready() -> void:
	set_physics_process(false)
	call_deferred("_initialize")


func _initialize() -> void:
	randomize()
	_state.reset_for_battle()
	_box = BattleBox.new(_root, _state, _target, _on_ball_dropped, BALL_CONTENT_DIR)
	_target.z_index = 999
	if not _enemy.action_requested.is_connected(_on_enemy_action_requested):
		_enemy.action_requested.connect(_on_enemy_action_requested)
	_enemy.setup()
	_hud.clear_result()
	_track_ball(null)
	_hud.sync_player(RunState.player_health, RunState.player_max_health)
	_hud.sync_energy(_state.player_energy, _state.player_energy_max)
	sync_shoot_ammo_hud()
	ensure_ball_in_play()
	set_physics_process(true)


func _physics_process(_delta: float) -> void:
	print("start")
	if _state.resolving_board:
		_rules.step_merge(_ctx)
		_rules.resolve_ball_effects(_ctx)
	print("end")
	_target.position = _root.get_local_mouse_position()
	_target.visible = (
		_state.phase == BattleState.Phase.PLAY
		and Input.is_action_pressed("shoot")
		and _state.shoot_ammo.can_shoot()
	)
	if Input.is_action_just_pressed("shoot"):
		_shoot()
	if ball_pulls.size() > 0:
		print("start")
		print(ball_pulls)
		for ball in ball_pulls:
			var direction = (ball[1].global_position - ball[0].global_position).normalized()
			ball[0].apply_central_force(direction * 4000.0)	
		ball_pulls = []
		print(ball_pulls)


func active_balls() -> Array:
	return _box.active()


func active_enemy():
	return _enemy


func consume_ball(ball: GameBall) -> void:
	if _state.current_ball == ball:
		_state.current_ball = null
		_track_ball(null)
	get_viewport().get_camera_2d().shake(ball.level/25)
	_box.consume(ball)


func spawn_ball_copy(source: GameBall, offset: Vector2 = Vector2.ZERO) -> GameBall:
	return _box.spawn_copy(source, offset)

func _magnetize(ball, source):
	ball_pulls.append([ball, source])
	
func _default_spawn(position: Vector2, offset) -> GameBall:
	print("reach")
	return _box._spawn(_box._spawn_pool[0], randi_range(1, 2), position + offset, false)


func wake_playfield() -> void:
	_box.wake()


func heal_player(amount: int) -> void:
	if amount <= 0:
		return
	RunState.heal_player(amount)
	_hud.sync_player(RunState.player_health, RunState.player_max_health)
	_hud.show_heal(amount)


func damage_enemy(amount: int) -> void:
	if amount <= 0 or _enemy.current_health <= 0:
		return
	_enemy.flash()
	_enemy.apply_damage(amount)
	_hud.show_enemy_damage(amount)
	if _enemy.current_health == 0:
		_finish_battle("Game Clear")


func damage_player(amount: int) -> void:
	if amount <= 0 or RunState.player_health <= 0:
		return
	RunState.damage_player(amount)
	_player.flash()
	_hud.sync_player(RunState.player_health, RunState.player_max_health)
	_hud.show_player_damage(amount)
	if RunState.player_health == 0:
		_finish_battle("Game Over")


func burst_knock_on_balls(origin_global: Vector2, strength_scale: float = 1.0) -> void:
	var strength := 100.0 * strength_scale
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
	_hud.sync_shoot_ammo(_state.shoot_ammo.bullets, _state.shoot_ammo.merge_progress)


func ensure_ball_in_play() -> void:
	if _state.phase != BattleState.Phase.PLAY or is_instance_valid(_state.current_ball):
		return
	_state.current_ball = _box.spawn_setup_ball()
	_track_ball(_state.current_ball)


func _shoot() -> void:
	if _state.phase != BattleState.Phase.PLAY or not _state.shoot_ammo.try_consume_shot():
		return
	for body in _target_area.get_overlapping_bodies():
		if not body is GameBall:
			continue
		burst_knock_on_balls((body as GameBall).position, (body as GameBall).level)
		if body.has_tag("explode"):
			body.exploded = true
			continue
		damage_enemy((body as GameBall).level)
		consume_ball(body as GameBall)
	burst_knock_on_balls(_target.global_position, SHOOT_BURST_STRENGTH_MULT)
	sync_shoot_ammo_hud()
	get_viewport().get_camera_2d().shake(SHOOT_BURST_STRENGTH_MULT)
	


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
	_hud.sync_energy(_state.player_energy, _state.player_energy_max)
	sync_shoot_ammo_hud()
	ensure_ball_in_play()
	_turn_running = false


func _track_ball(ball) -> void:
	_line_indicator.track_ball(ball)

func _finish_battle(text: String) -> void:
	_state.phase = BattleState.Phase.RESOLVE
	_state.lock_resolution()
	_state.current_ball = null
	_turn_running = false
	_track_ball(null)
	_target.visible = false
	_hud.show_result(text)


func _on_enemy_action_requested() -> void:
	if _hud.has_result():
		return
	_rules.resolve_enemy_turn(_ctx)
