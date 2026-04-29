extends StaticBody2D

## Horizontal sweep; tune in the inspector to change difficulty.
@export var travel_pixels := 88.0
@export var period_seconds := 2.6

var _home_x := 0.0


func _ready() -> void:
	_home_x = position.x


func _physics_process(_delta: float) -> void:
	var t := Time.get_ticks_msec() * 0.001
	position.x = _home_x + cos(t * TAU / period_seconds) * travel_pixels
