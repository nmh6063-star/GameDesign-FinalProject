extends StaticBody2D

static var _armed_card: StaticBody2D

const shuffleSpeed := 10.0
const rotSpeed := 10.0
const DRAG_CONFIRM_DISTANCE_PX := 90.0

var targetPos := Vector2.ZERO
var targetRot := 0.0
var sizeMulti := 1.25
@onready var baseScale = get_node("Sprite2D").scale
var scaleSpeed := 10.0
var hover := false
var raisedY := Vector2.ZERO
var index := 0
var details = null
@onready var info = $Info
@onready var timer = $Timer

var _armed := false
var _arm_mouse_start := Vector2.ZERO
var _arm_slot_local := Vector2.ZERO


func _physics_process(delta: float) -> void:
	if not _armed:
		position = position.lerp(targetPos + raisedY, delta * shuffleSpeed)
		rotation = lerp_angle(rotation, targetRot * PI / 180.0, delta * rotSpeed)
	else:
		global_position = get_global_mouse_position()
		rotation = lerp_angle(rotation, targetRot * PI / 180.0, delta * rotSpeed)

	if not _armed:
		if hover:
			z_index = 999
			raisedY = Vector2(0.0, -20.0)
			get_node("Sprite2D").scale = get_node("Sprite2D").scale.lerp(baseScale * sizeMulti, delta * scaleSpeed)
		else:
			z_index = 0
			raisedY = Vector2.ZERO
			get_node("Sprite2D").scale = get_node("Sprite2D").scale.lerp(baseScale, delta * scaleSpeed)
	else:
		z_index = 1000
		get_node("Sprite2D").scale = get_node("Sprite2D").scale.lerp(baseScale * sizeMulti, delta * scaleSpeed)

	var mouse_pos := get_global_mouse_position()
	var space_state := get_world_2d().direct_space_state
	var parameters := PhysicsPointQueryParameters2D.new()
	parameters.position = mouse_pos
	parameters.collide_with_areas = true
	parameters.collide_with_bodies = false
	var result := space_state.intersect_point(parameters)
	var over_self := false
	for r in result:
		if r.collider == get_node("Area2D"):
			over_self = true
			break

	if not _armed:
		if over_self:
			if not hover:
				timer.start()
				info.rotation = -rotation
			hover = true
		else:
			info.visible = false
			hover = false

		if hover and Input.is_action_just_pressed("play_card"):
			if _armed_card != null and is_instance_valid(_armed_card) and _armed_card != self:
				if _armed_card.has_method("disarm_snap"):
					_armed_card.disarm_snap()
			_arm_mouse_start = get_global_mouse_position()
			_arm_slot_local = targetPos
			_armed = true
			_armed_card = self
			info.visible = false
	else:
		if Input.is_action_just_pressed("play_card"):
			var drag := get_global_mouse_position().distance_to(_arm_mouse_start)
			if drag >= DRAG_CONFIRM_DISTANCE_PX:
				var cm := get_parent()
				if cm != null and cm.has_method("confirm_play"):
					cm.confirm_play(self)
				else:
					disarm_snap()
			else:
				disarm_snap()


func disarm_snap() -> void:
	_armed = false
	if _armed_card == self:
		_armed_card = null
	position = _arm_slot_local


func clear_arm_state() -> void:
	_armed = false
	if _armed_card == self:
		_armed_card = null


func _on_timer_timeout() -> void:
	if not _armed:
		info.visible = true
