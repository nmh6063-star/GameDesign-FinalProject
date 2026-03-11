extends Node2D

@export var max_health: int = 10
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
		var anim := get_node_or_null("AnimatedSprite2D")
		if anim:
			anim.play("die")

func _update_bar() -> void:
	var fill := get_node_or_null("HealthBar/Fill") as ColorRect
	if fill == null:
		return
	var ratio: float = 1.0
	if max_health > 0:
		ratio = float(current_health) / float(max_health)
	fill.size.x = BAR_WIDTH * ratio
