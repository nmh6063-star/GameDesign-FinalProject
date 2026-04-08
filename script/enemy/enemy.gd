extends Node2D
class_name BattleEnemy

signal damaged(amount: int)
signal defeated
signal action_requested

@export var data: EnemyData

var current_health := 0

@onready var _base_modulate: Color = $AnimatedSprite2D.modulate
@onready var _attack_cooldown := $AttackCooldown as Timer

func _ready() -> void:
	add_to_group("enemy")
	reset()


func setup() -> void:
	reset()


func reset() -> void:
	current_health = data.max_health
	visible = true
	process_mode = Node.PROCESS_MODE_INHERIT
	($AnimatedSprite2D as AnimatedSprite2D).play("idle")
	_restart_attack_cooldown()


func apply_damage(amount: int) -> void:
	if amount <= 0 or current_health <= 0:
		return
	var applied := mini(amount, current_health)
	damaged.emit(applied)
	current_health -= applied
	if current_health == 0:
		_attack_cooldown.stop()
		$Timer.stop()
		($AnimatedSprite2D as AnimatedSprite2D).stop()
		visible = false
		process_mode = Node.PROCESS_MODE_DISABLED
		defeated.emit()


func cooldown_left() -> float:
	return _attack_cooldown.time_left


func flash() -> void:
	$AnimatedSprite2D.modulate = Color(18.892, 0.0, 0.0)
	$Timer.start()


func _on_timer_timeout() -> void:
	$AnimatedSprite2D.modulate = _base_modulate


func _restart_attack_cooldown() -> void:
	if data.attack_interval <= 0.0:
		_attack_cooldown.stop()
		return
	_attack_cooldown.wait_time = data.attack_interval
	_attack_cooldown.start()


func _on_attack_cooldown_timeout() -> void:
	if current_health <= 0:
		return
	action_requested.emit()
	_restart_attack_cooldown()
