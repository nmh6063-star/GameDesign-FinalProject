extends Node2D

signal damaged(amount: int)

@export var max_health: int = 100
@export var attack_damage: int = 10
var current_health: int
@onready var base = $AnimatedSprite2D.modulate


const BAR_WIDTH := 98.0
const BAR_HEIGHT := 10.0

func _ready() -> void:
	add_to_group("enemy")
	current_health = max_health
	_update_bar()

func apply_attack(amount: int) -> void:
	damaged.emit(amount)
	current_health = max(current_health - amount, 0)
	_update_bar()
	if current_health <= 0:
		(get_node("AnimatedSprite2D") as AnimatedSprite2D).play("die")

func _update_bar() -> void:
	(get_node("HealthBar/Fill") as ColorRect).size.x = BAR_WIDTH * float(current_health) / float(max_health)
	var hp_text := get_node_or_null("HealthBar/HPText") as Label
	if hp_text:
		hp_text.text = "%d/%d" % [current_health, max_health]

func _flash():
	$AnimatedSprite2D.modulate = Color(18.892, 0.0, 0.0)
	$Timer.start()


func _on_timer_timeout() -> void:
	$AnimatedSprite2D.modulate = base
