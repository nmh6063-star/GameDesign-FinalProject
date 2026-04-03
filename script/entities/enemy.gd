extends Node2D

signal damaged(amount: int)

@export var max_health: int = 50
@export var attack_damage: int = 10
var current_health: int
@onready var base = $AnimatedSprite2D.modulate
@onready var timer2 = $Timer2
@onready var startPos = self.position
@onready var player = get_node("/root/Main/PlayerHolder/Player")
var time = 0.0
signal player_attacked(amount: int)


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

func _physics_process(delta: float) -> void:
	time += delta
	var weight = time / 5.0
	position = startPos.lerp(Vector2(player.position.x * 5, self.position.y), weight)
	
func _on_timer_2_timeout() -> void:
	player_attacked.emit(10)
	Global.player_health = max(Global.player_health - 10, 0)
	self.position = startPos
	time = 0
	timer2.start()
