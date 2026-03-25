extends Node

const MERGE_SETTLE_TIME := 2.0

@onready var card_manager = get_node("/root/Node2D/CardManager")
@onready var _ball_query := preload("res://scripts/queries/ball_query.gd").new()
@onready var _merge := preload("res://scripts/services/merge_resolver.gd").new()
@onready var _combat := preload("res://scripts/services/combat_resolver.gd").new()

signal attack_calculated(amount: int)
signal player_attacked(amount: int)
signal turn_ended
signal game_over
signal game_clear

var _resolving := false
var _turn_attack := 0
var _attack_levels_by_id := {}

func _physics_process(_delta: float) -> void:
	match Global.phase:
		Global.Phase.PLAY:
			_keep_hand()
		Global.Phase.RESOLVE:
			_try_merge()

func _keep_hand() -> void:
	if Global.currentHand.size() < Global.handSize and card_manager.cardPlay:
		card_manager.draw()

func _template_ball() -> RigidBody2D:
	return get_parent().get_node("Ball") as RigidBody2D

func _active_balls() -> Array[RigidBody2D]:
	return _ball_query.active_balls(get_tree(), _template_ball())

func _note_attack_ball(body: RigidBody2D) -> void:
	var id := body.get_instance_id()
	var new_level: int = body.level
	var prev: int = int(_attack_levels_by_id.get(id, 0))
	_attack_levels_by_id[id] = new_level
	_turn_attack += (new_level - prev)

func _try_merge() -> void:
	var merged := _merge.step_merge(_active_balls())
	if merged:
		_note_attack_ball(merged)

func finish_turn() -> void:
	if _resolving or Global.phase != Global.Phase.PLAY:
		return
	_resolving = true
	Global.phase = Global.Phase.RESOLVE
	card_manager.cardPlay = false
	_turn_attack = 0
	_attack_levels_by_id.clear()

	var template := _template_ball()
	for node in get_tree().get_nodes_in_group("ball"):
		var body := node as RigidBody2D
		if body and body != template and (not body.visible or body.set_up):
			body.queue_free()

	await get_tree().create_timer(MERGE_SETTLE_TIME).timeout
	_resolve_combat()

func _resolve_combat() -> void:
	attack_calculated.emit(_turn_attack)

	var enemy := get_tree().get_first_node_in_group("enemy")
	if _combat.player_attack(enemy, _turn_attack):
		game_clear.emit()
		return

	await get_tree().create_timer(0.5).timeout

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
	_resolving = false
	turn_ended.emit()

