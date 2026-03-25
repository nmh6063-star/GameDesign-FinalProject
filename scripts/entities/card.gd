extends StaticBody2D

const shuffleSpeed = 10.0
const rotSpeed = 10.0
var targetPos = Vector2.ZERO
var targetRot = 0.0
var sizeMulti = 1.25
@onready var baseScale = get_node("Sprite2D").scale
var scaleSpeed = 10.0
var hover = false
var raisedY = Vector2.ZERO
var index = 0
var details = null
@onready var info = $Info
@onready var timer = $Timer

func _physics_process(delta: float) -> void:
	self.position = self.position.lerp(targetPos + raisedY, delta * shuffleSpeed)
	self.rotation = lerp_angle(self.rotation, targetRot * PI / 180, delta * rotSpeed)
	if hover:
		self.z_index = 999
		raisedY = Vector2(0.0, -20.0)
		get_node("Sprite2D").scale = get_node("Sprite2D").scale.lerp(baseScale * sizeMulti, delta * scaleSpeed)
	else:
		self.z_index = 0
		raisedY = Vector2.ZERO
		get_node("Sprite2D").scale = get_node("Sprite2D").scale.lerp(baseScale, delta * scaleSpeed)
	
	var mousePos = get_global_mouse_position()
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = mousePos
	parameters.collide_with_areas = true
	parameters.collide_with_bodies = false
	var result = space_state.intersect_point(parameters)
	var colliders = []
	for i in range(result.size()):
		colliders.append(result[i].collider)
	if colliders.size() > 0 and colliders[0] == get_node("Area2D"):
		if !hover:
			timer.start()
			info.rotation = -self.rotation
		hover = true
	else:
		info.visible = false
		hover = false
	
	if hover and Input.is_action_just_pressed("play_card"):
		get_parent().discard(index)

func _on_timer_timeout() -> void:
	info.visible = true

