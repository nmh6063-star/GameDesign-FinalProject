extends Node2D

## Expanding green ring that plays at a ball's position when it is upgraded (e.g. Convert).
## Spawned programmatically; frees itself when done.

const RING_COLOR   := Color(0.2, 1.0, 0.35, 0.85)
const RING_WIDTH   := 3.5
const RING_POINTS  := 64
const START_RADIUS := 14.0
const END_RADIUS   := 52.0
const DURATION     := 0.45

var _radius: float = START_RADIUS
var _alpha: float  = 1.0


func play() -> void:
	var tween := create_tween()
	tween.tween_method(_set_radius, START_RADIUS, END_RADIUS, DURATION)
	tween.parallel().tween_method(_set_alpha, 1.0, 0.0, DURATION)
	tween.tween_callback(queue_free)


func _set_radius(v: float) -> void:
	_radius = v
	queue_redraw()


func _set_alpha(v: float) -> void:
	_alpha = v
	queue_redraw()


func _draw() -> void:
	draw_arc(Vector2.ZERO, _radius, 0.0, TAU, RING_POINTS,
			Color(RING_COLOR.r, RING_COLOR.g, RING_COLOR.b, _alpha),
			RING_WIDTH, true)
