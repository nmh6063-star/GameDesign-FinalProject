extends StaticBody2D

@export var cup_angle_degrees: float = 360.0
@export var duration: float = 2.4
@onready var box = get_node("/root/Node2D/Box")
var startPos
var goPos
var shakeCount = 10
var shaked = shakeCount
var balls = []

func _ready() -> void:
	startPos = box.position
	goPos = startPos

func rotate_cup() -> void:
	var end := rotation - deg_to_rad(cup_angle_degrees)
	var tween := create_tween()
	tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "rotation", end, duration)
	"""
	Global.mergeTime = false
	shaked = 0
	goPos = Vector2(startPos.x + randi_range(-50, 50), startPos.y - 50.0)
	var children = get_node("/root/Node2D").get_children()
	balls = []
	for child in children:
		if child.has_method("_shake"):
			balls.append(child)
			child.reset = true
			child.queue_redraw()
			child._update_collision()
	"""
			
func rotater():
	var end := rotation - deg_to_rad(cup_angle_degrees)
	var tween := create_tween()
	tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "rotation", end, duration)

func _physics_process(delta: float) -> void:
	if shaked < shakeCount:
		box.position = box.position.move_toward(goPos, 1000.0 * delta)
		if box.position.y < startPos.y - 45.0:
			goPos = Vector2(startPos.x + randi_range(-50, 50), startPos.y + 50.0)
			shaked += 1
			for child in balls:
				child._shake();
		elif box.position.y > startPos.y + 45.0:
			goPos = Vector2(startPos.x + randi_range(-50, 50), startPos.y - 50.0)
			shaked += 1
			for child in balls:
				child._shake();
	else:
		if !Global.mergeTime:
			rotater()
		Global.mergeTime = true
		box.position = box.position.move_toward(startPos, 500.0 * delta)


	
