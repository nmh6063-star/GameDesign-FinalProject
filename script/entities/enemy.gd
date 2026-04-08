extends Node2D
class_name BattleEnemy

signal damaged(amount: int)
signal defeated
signal action_requested

@export var data: EnemyData

var current_health := 0

@onready var _base_modulate: Color = $AnimatedSprite2D.modulate
@onready var _attack_cooldown := $AttackCooldown as Timer
@onready var _cooldown_ring = $CooldownRing

const BAR_WIDTH := 98.0


func _ready() -> void:
	add_to_group("enemy")
	reset()


func setup() -> void:
	reset()


func reset() -> void:
	current_health = data.max_health
	($AnimatedSprite2D as AnimatedSprite2D).play("idle")
	_update_bar()
	_restart_attack_cooldown()


func apply_damage(amount: int) -> void:
	if amount <= 0 or current_health <= 0:
		return
	damaged.emit(amount)
	current_health = max(current_health - amount, 0)
	_update_bar()
	if current_health == 0:
		_attack_cooldown.stop()
		_cooldown_ring.visible = false
		($AnimatedSprite2D as AnimatedSprite2D).play("die")
		defeated.emit()


func _update_bar() -> void:
	($HealthBar/Fill as ColorRect).size.x = BAR_WIDTH * float(current_health) / float(data.max_health)
	($HealthBar/HPText as Label).text = "%d/%d" % [current_health, data.max_health]


func flash() -> void:
	$AnimatedSprite2D.modulate = Color(18.892, 0.0, 0.0)
	$Timer.start()


func _on_timer_timeout() -> void:
	$AnimatedSprite2D.modulate = _base_modulate


func _process(_delta: float) -> void:
	if current_health <= 0:
		return
	_update_cooldown_ring()


func _restart_attack_cooldown() -> void:
	if data.attack_interval <= 0.0:
		_attack_cooldown.stop()
		_cooldown_ring.visible = false
		return
	_attack_cooldown.wait_time = data.attack_interval
	_attack_cooldown.start()
	_update_cooldown_ring()


func _update_cooldown_ring() -> void:
	_cooldown_ring.sync(_attack_cooldown.time_left, data.attack_interval)


func _on_attack_cooldown_timeout() -> void:
	if current_health <= 0:
		return
	action_requested.emit()
	_restart_attack_cooldown()
