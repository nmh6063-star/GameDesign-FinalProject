extends Node2D

var indicator = preload("res://scenes/indicator_sprite.tscn")
var _ball

func _ready() -> void:
	var count = 0
	while count < 6:
		var inst = indicator.instantiate()
		inst.position.y = count * 56
		count += 1
		add_child(inst)


func track_ball(ball) -> void:
	_ball = ball


func _physics_process(_delta: float) -> void:
	if is_instance_valid(_ball) and _ball.set_up:
		visible = true
		position.x = _ball.position.x
	else:
		visible = false
