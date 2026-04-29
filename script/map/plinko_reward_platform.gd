extends StaticBody2D

signal reward_hit(value: int, body: Node2D, platform: Node2D)

@export var point_value: int = 1
@export var move_amplitude: float = 38.0
@export var move_speed: float = 1.35
@export var phase: float = 0.0

var _home: Vector2


func _ready() -> void:
	_home = position
	$HitZone.body_entered.connect(_on_hit_zone_body_entered)


func _physics_process(_delta: float) -> void:
	var t := Time.get_ticks_msec() * 0.001 * move_speed + phase
	position.x = _home.x + sin(t) * move_amplitude


func _on_hit_zone_body_entered(body: Node2D) -> void:
	if body != null and body.is_in_group("plinko_ball"):
		reward_hit.emit(point_value, body, self)
