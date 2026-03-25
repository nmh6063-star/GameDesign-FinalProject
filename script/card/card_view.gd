extends StaticBody2D

const CardDefinition := preload("res://script/card/card_definition.gd")

static var _armed_card: StaticBody2D

const shuffleSpeed := 10.0
const rotSpeed := 10.0

var targetPos := Vector2.ZERO
var targetRot := 0.0
var sizeMulti := 1.25
@onready var baseScale: Vector2 = get_node("Sprite2D").scale
var scaleSpeed := 10.0
var hover := false
var raisedY := Vector2.ZERO
var index := 0
var details = null
@onready var info := $Info
@onready var timer := $Timer
@onready var baseModulate := modulate

var _armed := false
var _arm_slot_local := Vector2.ZERO


func _physics_process(delta: float) -> void:
	if not _armed:
		position = position.lerp(targetPos + raisedY, delta * shuffleSpeed)
		modulate = baseModulate
		if hover:
			z_index = 999
			raisedY = Vector2(0, -20)
			get_node("Sprite2D").scale = get_node("Sprite2D").scale.lerp(baseScale * sizeMulti, delta * scaleSpeed)
		else:
			z_index = 0
			raisedY = Vector2.ZERO
			get_node("Sprite2D").scale = get_node("Sprite2D").scale.lerp(baseScale, delta * scaleSpeed)
	else:
		z_index = 1000
		get_node("Sprite2D").scale = get_node("Sprite2D").scale.lerp(baseScale * sizeMulti * 1.1, delta * scaleSpeed)
		modulate = Color(1.25, 1.25, 1.25, 1)
	rotation = lerp_angle(rotation, targetRot * PI / 180.0, delta * rotSpeed)
	if self.position.x > 400:
		print("help")
		$Info.position.x = 400- self.position.x

	var over := _mouse_over_card()
	if not _armed:
		if over and (!Global.cardInPlay or Global.cardInPlay == self):
			if not hover:
				timer.start()
				info.rotation = -rotation
			hover = true
			Global.cardInPlay = self
		else:
			info.visible = false
			hover = false
			if Global.cardInPlay == self:
				Global.cardInPlay = null
		if hover and Input.is_action_just_pressed("play_card"):
			if _armed_card != null and is_instance_valid(_armed_card) and _armed_card != self:
				_armed_card.disarm_snap()
			_arm_slot_local = targetPos
			_armed = true
			_armed_card = self
	else:
		if Input.is_action_just_pressed("play_card"):
			if over:
				get_parent().confirm_play(self)
			else:
				disarm_snap()


func _mouse_over_card() -> bool:
	var params := PhysicsPointQueryParameters2D.new()
	params.position = get_global_mouse_position()
	params.collide_with_areas = true
	params.collide_with_bodies = false
	for r in get_world_2d().direct_space_state.intersect_point(params):
		if r.collider == get_node("Area2D"):
			return true
	return false


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
	if _armed:
		return
	var d := details as CardDefinition
	if d:
		# Keep RichTextLabel text BBCode-agnostic so "[b]...[/b]" doesn't show up as raw text.
		$Info/RichTextLabel.text = "%s\n%s" % [d.title, d.description]
	info.visible = true
