extends Node2D

var indicator = preload("res://scenes/indicator_sprite.tscn")

func _ready() -> void:
	var count = 0
	while count < 6:
		var inst = indicator.instantiate()
		inst.position.y = count * 56
		count += 1
		add_child(inst)

func _physics_process(delta: float) -> void:
	if Global.ballInPlay and Global.ballInPlay.set_up:
		self.visible = true
		self.position.x = Global.ballInPlay.position.x
	else:
		self.visible = false
		
