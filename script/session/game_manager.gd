extends Node2D

const GameBall := preload("res://script/ball/game_ball.gd")
const CardManager := preload("res://script/card/card_manager.gd")
const MERGE_SETTLE_TIME := 1.0
const POST_PLAYER_DAMAGE_UI_DELAY := 0.35
const ENEMY_ATTACK_DELAY := 2.0
const PLAYER_DAMAGE_APPLY_INTERVAL := 0.1

@onready var card_manager: CardManager = get_parent().get_node("PlayerHandler/CardManager")
@onready var _ball_query := preload("res://script/ball/resolve/ball_query.gd").new()
@onready var _merge := preload("res://script/ball/resolve/merge_resolver.gd").new()
@onready var _specials := preload("res://script/ball/resolve/special_ball_resolver.gd").new()
@onready var _combat := preload("res://script/combat/combat_resolver.gd").new()

signal attack_calculated(amount: int)
signal player_healed(amount: int)
signal player_attacked(amount: int)
signal energy_changed(current: int, max: int)
signal enemy_turn_started
signal player_turn_started
signal turn_ended
signal game_over
signal game_clear

var _resolving := false
var _resolve_specials_done := false
var _combat_damage_phase := false
var _turn_attack := 0
var _attack_levels_by_id: Dictionary = {}
var _pending_player_damage: Array[int] = []
var _player_damage_apply_timer := 0.0
var mode = true
var target


func _ready() -> void:
	Global.player_energy = Global.player_energy_max
	target = get_parent().get_node("PlayerHandler/Target")
	target.z_index = 999
	#change to some constant
	#Global.player_energy = 5
	energy_changed.emit(Global.player_energy, Global.player_energy_max)


func _physics_process(_delta: float) -> void:
	_try_merge()
	var healed := _specials.resolve(get_parent() as Node2D, _template_ball() as GameBall, Callable(get_parent(), &"wire_playfield_ball"))
	if healed > 0:
		player_healed.emit(healed)
	match Global.phase:
		Global.Phase.PLAY:
			_keep_hand()
	"""
	match Global.phase:
		Global.Phase.PLAY:
			_keep_hand()
		Global.Phase.RESOLVE:
			if not _resolve_specials_done:
				var healed := _specials.resolve(get_parent() as Node2D, _template_ball() as GameBall, Callable(get_parent(), &"wire_playfield_ball"))
				if healed > 0:
					player_healed.emit(healed)
				_resolve_specials_done = true
			#if not _combat_damage_phase:
			_process_pending_player_damage(_delta)
	"""
	if Input.is_action_just_pressed("mode_switch"):
		mode = !mode
	target.position = get_local_mouse_position()
	if !mode:
		target.visible = true
		if Input.is_action_just_pressed("play_card"):
			var bodies = target.get_node("Area2D").get_overlapping_bodies()
			var enemy := get_tree().get_first_node_in_group("enemy")
			for body in bodies:
				if body.name != "Box":
					_combat.player_attack(enemy, body.level)
					body.queue_free()
			if bodies.size() > 0:
				for node in get_tree().get_nodes_in_group("ball"):
					if not is_instance_valid(node):
						continue
					var body := node as RigidBody2D
					if body != self:
						var direction = body.position - target.position
						direction.normalized()
						body.apply_central_impulse(direction * get_parent().get_node("HSlider").value)
	else:
		target.visible = false


func _keep_hand() -> void:
	if Global.currentHand.size() < Global.handSize and card_manager.cardPlay:
		card_manager.draw()


func _template_ball() -> RigidBody2D:
	return get_parent().get_node("Ball") as RigidBody2D


func _clamp_ball_in_play_pointer(template_node: Node) -> void:
	var bip: Node = Global.ballInPlay
	if bip == template_node:
		return
	if not is_instance_valid(bip):
		Global.ballInPlay = template_node
		return
	if bip is Node and bip.is_queued_for_deletion():
		Global.ballInPlay = template_node


func _active_balls() -> Array[RigidBody2D]:
	return _ball_query.active_balls(get_tree(), _template_ball())
	

func _try_merge() -> void:
	var merged := _merge.step_merge(_active_balls())
	if merged == null:
		return
	var id := merged.get_instance_id()
	var new_level: int = merged.level
	var prev: int = int(_attack_levels_by_id.get(id, 0))
	_attack_levels_by_id[id] = new_level
	var delta: int = new_level - prev
	_turn_attack += delta
	#if delta > 0:
		#_pending_player_damage.append(delta)
	var test = get_parent().get_node("HSlider")
	#print(test)
	for node in get_tree().get_nodes_in_group("ball"):
		if not is_instance_valid(node):
			continue
		var body := node as RigidBody2D
		if body != self:
			var direction = body.position - merged.position
			direction.normalized()
			body.apply_central_impulse(direction * test.value)
		#if body != _merge:
			#var jump_impulse = Vector2(100, -100 * test.value)
		#if body != template and (not body.visible or body.set_up):
			#pass
	#var jump_impulse = Vector2(100, -100 * test.value)
	#merged.apply_central_impulse(jump_impulse)


func _process_pending_player_damage(dt: float) -> void:
	if _pending_player_damage.is_empty():
		_player_damage_apply_timer = 0.0
		return
	_player_damage_apply_timer -= dt
	if _player_damage_apply_timer > 0.0:
		return
	var d := int(_pending_player_damage.pop_front())
	var enemy := get_tree().get_first_node_in_group("enemy")
	if enemy and d > 0:
		_combat.player_attack(enemy, d)
	_player_damage_apply_timer = PLAYER_DAMAGE_APPLY_INTERVAL if not _pending_player_damage.is_empty() else 0.0


func finish_turn() -> void:
	if _resolving or Global.phase != Global.Phase.PLAY:
		return
	_resolving = true
	Global.phase = Global.Phase.RESOLVE
	card_manager.cardPlay = false
	_turn_attack = 0
	_attack_levels_by_id.clear()
	_pending_player_damage.clear()
	_player_damage_apply_timer = 0.0
	_resolve_specials_done = false
	var template := _template_ball()
	for node in get_tree().get_nodes_in_group("ball"):
		if not is_instance_valid(node):
			continue
		var body := node as RigidBody2D
		if body != template and (not body.visible or body.set_up):
			pass
			#body.queue_free()
	_clamp_ball_in_play_pointer(template as Node)
	await get_tree().create_timer(MERGE_SETTLE_TIME).timeout
	await _resolve_combat()


func _resolve_combat() -> void:
	_combat_damage_phase = true
	attack_calculated.emit(_turn_attack)
	while not _pending_player_damage.is_empty():
		await get_tree().physics_frame
	var enemy := get_tree().get_first_node_in_group("enemy")
	if is_instance_valid(enemy) and enemy.current_health <= 0:
		_combat_damage_phase = false
		_resolving = false
		game_clear.emit()
		return
	await get_tree().create_timer(POST_PLAYER_DAMAGE_UI_DELAY).timeout
	enemy_turn_started.emit()
	if not is_instance_valid(enemy):
		await get_tree().create_timer(ENEMY_ATTACK_DELAY).timeout
		_end_turn()
		return
	await get_tree().create_timer(ENEMY_ATTACK_DELAY).timeout
	var enemy_atk := _combat.enemy_attack_damage(enemy)
	Global.player_health = max(Global.player_health - enemy_atk, 0)
	player_attacked.emit(enemy_atk)
	if Global.player_health <= 0:
		game_over.emit()
		_combat_damage_phase = false
		_resolving = false
		return
	await get_tree().create_timer(0.5).timeout
	_end_turn()


func _end_turn() -> void:
	var template := _template_ball()
	for node in get_tree().get_nodes_in_group("ball"):
		if not is_instance_valid(node):
			continue
		var body := node as RigidBody2D
		if body != template and _attack_levels_by_id.has(body.get_instance_id()):
			pass
			#body.queue_free()
	_clamp_ball_in_play_pointer(template as Node)
	_combat_damage_phase = false
	Global.phase = Global.Phase.PLAY
	Global.player_energy += 5
	if Global.player_energy > Global.player_energy_max:
		Global.player_energy = Global.player_energy_max
	energy_changed.emit(Global.player_energy, Global.player_energy_max)
	_resolving = false
	player_turn_started.emit()
	turn_ended.emit()
