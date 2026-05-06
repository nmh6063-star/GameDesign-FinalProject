extends Node2D

signal landed

@export var arc_height: float = 120.0
@export var duration: float = 0.7
@export var tumble_cycles: int = 4

var _ball_radius: float = 20.0
var _ball_tint: Color = Color(0.55, 0.55, 0.55)
var _outline_color: Color = Color(0.3, 0.3, 0.3)


func setup(data: BallData, rank: int) -> void:
	if data == null:
		queue_redraw()
		return
	_ball_radius = data.radius_for_rank(rank)
	_ball_tint = data.tint
	_outline_color = data.display_outline_color(rank)
	queue_redraw()


func setup_raw(radius: float, ball_tint: Color, ball_outline: Color) -> void:
	_ball_radius = radius
	_ball_tint = ball_tint
	_outline_color = ball_outline
	queue_redraw()


func launch(from: Vector2, to: Vector2) -> void:
	global_position = from
	var tween := create_tween()
	tween.tween_method(func(t: float) -> void:
		var p := from.lerp(to, t)
		global_position = Vector2(p.x, p.y - arc_height * sin(t * PI))
		scale = Vector2.ONE * lerpf(0.5, 1.0, abs(sin(t * PI * tumble_cycles)))
		queue_redraw()
	, 0.0, 1.0, duration)
	tween.tween_callback(func() -> void:
		landed.emit()
		queue_free()
	)


func _draw() -> void:
	draw_circle(Vector2.ZERO, _ball_radius, _ball_tint)
	draw_arc(Vector2.ZERO, _ball_radius, 0.0, TAU, 64, _outline_color, 2.5, true)
