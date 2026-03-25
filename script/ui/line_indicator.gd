extends Node2D

const GameBall := preload("res://script/ball/game_ball.gd")

var indicator = preload("res://scenes/indicator_sprite.tscn")

func _ready() -> void:
	var count = 0
	while count < 6:
		var inst = indicator.instantiate()
		inst.position.y = count * 56
		count += 1
		add_child(inst)

func _physics_process(_delta: float) -> void:
	if not is_instance_valid(Global.ballInPlay):
		visible = false
		return
	var b: Node = Global.ballInPlay
	if b is GameBall and (b as GameBall).set_up:
		visible = true
		if b is Node2D:
			position.x = (b as Node2D).position.x
	else:
		visible = false
		
