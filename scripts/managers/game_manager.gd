extends Node

const MERGE_SETTLE_TIME := 1.0
const POST_PLAYER_DAMAGE_UI_DELAY := 0.35
const ENEMY_ATTACK_DELAY := 2.0
const PLAYER_DAMAGE_APPLY_INTERVAL := 0.1

@onready var card_manager = get_node("/root/Node2D/CardManager")
@onready var _ball_query := preload("res://scripts/queries/ball_query.gd").new()
@onready var _merge := preload("res://scripts/services/merge_resolver.gd").new()
@onready var _combat := preload("res://scripts/services/combat_resolver.gd").new()

signal attack_calculated(amount: int)
signal player_attacked(amount: int)
signal energy_changed(current: int, max: int)
signal enemy_turn_started
signal player_turn_started
signal turn_ended
signal game_over
signal game_clear

var _resolving := false
var _turn_attack := 0
var _attack_levels_by_id := {}
var _pending_player_damage: Array[int] = []
var _player_damage_apply_timer: float = 0.0

func _ready() -> void:
	Global.player_energy = Global.player_energy_max
	energy_changed.emit(Global.player_energy, Global.player_energy_max)

func _physics_process(_delta: float) -> void:
	match Global.phase:
		Global.Phase.PLAY:
			_keep_hand()
		Global.Phase.RESOLVE:
			_try_merge()
			_process_pending_player_damage(_delta)

func _keep_hand() -> void:
	if Global.currentHand.size() < Global.handSize and card_manager.cardPlay:
		card_manager.draw()

func _template_ball() -> RigidBody2D:
	return get_parent().get_node("Ball") as RigidBody2D

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
	if delta > 0:
		_pending_player_damage.append(delta)

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

	var template := _template_ball()
	for node in get_tree().get_nodes_in_group("ball"):
		var body := node as RigidBody2D
		if body and body != template and (not body.visible or body.set_up):
			body.queue_free()

	await get_tree().create_timer(MERGE_SETTLE_TIME).timeout
	_resolve_combat()

func _resolve_combat() -> void:
	attack_calculated.emit(_turn_attack)

	while not _pending_player_damage.is_empty():
		await get_tree().physics_frame

	var enemy := get_tree().get_first_node_in_group("enemy")
	if enemy != null and enemy.current_health <= 0:
		_resolving = false
		game_clear.emit()
		return

	await get_tree().create_timer(POST_PLAYER_DAMAGE_UI_DELAY).timeout
	enemy_turn_started.emit()

	if enemy == null:
		await get_tree().create_timer(ENEMY_ATTACK_DELAY).timeout
		_end_turn()
		return

	await get_tree().create_timer(ENEMY_ATTACK_DELAY).timeout

	var enemy_atk := _combat.enemy_attack_damage(enemy)
	Global.player_health = max(Global.player_health - enemy_atk, 0)
	player_attacked.emit(enemy_atk)

	if Global.player_health <= 0:
		game_over.emit()
		return

	await get_tree().create_timer(0.5).timeout
	_end_turn()

func _end_turn() -> void:
	var template := _template_ball()
	for node in get_tree().get_nodes_in_group("ball"):
		var body := node as RigidBody2D
		if body and body != template and _attack_levels_by_id.has(body.get_instance_id()):
			body.queue_free()
	Global.phase = Global.Phase.PLAY
	Global.player_energy = Global.player_energy_max
	energy_changed.emit(Global.player_energy, Global.player_energy_max)
	_resolving = false
	player_turn_started.emit()
	turn_ended.emit()

