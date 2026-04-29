extends StaticBody2D

@export var travel_pixels := 16.0
@export var period_seconds := 2.4
@export var drift: Vector2 = Vector2(0.65, 0.45)

var _home: Vector2


func _ready() -> void:
	_home = position
	drift = drift.normalized()


func _physics_process(_delta: float) -> void:
	var t := Time.get_ticks_msec() * 0.001
	position = _home + drift * sin(t * TAU / period_seconds) * travel_pixels
