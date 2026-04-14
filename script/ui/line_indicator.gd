extends Node2D

var _ball

func track_ball(ball) -> void:
	_ball = ball


func _physics_process(_delta: float) -> void:
	if is_instance_valid(_ball) and _ball.set_up:
		visible = true
		position.x = _ball.position.x
	else:
		visible = false
