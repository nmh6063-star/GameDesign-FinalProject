extends Node2D

@export var max_health: int = 100
@export var attack_damage: int = 10
var current_health: int

const BAR_WIDTH := 98.0
const BAR_HEIGHT := 10.0

func _ready() -> void:
	add_to_group("enemy")
	current_health = max_health
	_update_bar()

func apply_attack(amount: int) -> void:
	current_health = max(current_health - amount, 0)
	_update_bar()
	if current_health <= 0:
		(get_node("AnimatedSprite2D") as AnimatedSprite2D).play("die")

func _update_bar() -> void:
	(get_node("HealthBar/Fill") as ColorRect).size.x = BAR_WIDTH * float(current_health) / float(max_health)

