extends StaticBody2D

@export var travel_pixels := 24.0
@export var period_seconds := 2.0

var _home_y := 0.0


func _ready() -> void:
	_home_y = position.y


func _physics_process(_delta: float) -> void:
	var t := Time.get_ticks_msec() * 0.001
	position.y = _home_y + sin(t * TAU / period_seconds) * travel_pixels
