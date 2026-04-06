extends RigidBody2D
class_name GameBall

const BallBehavior := preload("res://script/ball/behaviors/ball_behavior.gd")
const SpecialBallBehavior := preload("res://script/ball/behaviors/special_ball_behavior.gd")

signal dropped

@export var behavior: BallBehavior

var set_up: bool = false
var move_speed: float = 200.0
var direction: int = 0
var level: int = 1
var reset: bool = false
var bounce = 1

const GRAVITY_SCALE := 2.0

const OUTLINE_WIDTH := 2.0
const OUTLINE_POINTS := 64

var last_velocity = Vector2.ZERO


func special_or_null() -> SpecialBallBehavior:
	if behavior is SpecialBallBehavior:
		return behavior as SpecialBallBehavior
	return null


func has_special_effect(e: SpecialBallBehavior.Effect) -> bool:
	var s := special_or_null()
	return s != null and s.effect == e


func _radius() -> float:
	var radius := 20.0
	if behavior != null and not behavior.participates_in_level_merge():
		return radius
	if reset:
		return radius
	for i in range(1, level):
		radius += 5.0 / i
	return radius


func get_radius() -> float:
	return _radius()


func _label_color() -> Color:
	if behavior == null:
		return Color(0.3 + 0.05 * level, 0.8 - 0.06 * level, 0.3)
	return behavior.display_color(level)


func _ready() -> void:
	behavior = behavior if behavior != null else BallBehavior.from_kind(BallBehavior.Kind.NORMAL)
	add_to_group("ball")
	gravity_scale = 0.0
	_update_collision()
	queue_redraw()
	contact_monitor = true
	max_contacts_reported = 10


func _update_collision() -> void:
	var col := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if col == null or not col.shape is CircleShape2D:
		return
	var circle := (col.shape as CircleShape2D).duplicate()
	circle.radius = _radius()
	col.shape = circle


func merge_into_me() -> void:
	if not behavior.participates_in_level_merge():
		return
	level *= 2
	_update_collision()
	queue_redraw()


func reset_for_spawn() -> void:
	level = 1
	behavior = BallBehavior.from_kind(BallBehavior.Kind.NORMAL)


func _draw() -> void:
	var radius := _radius()
	var color := _label_color()
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, OUTLINE_POINTS, color, OUTLINE_WIDTH, true)
	var sprite := $Sprite2D as Sprite2D
	var tw := sprite.texture.get_width()
	sprite.scale = Vector2((radius * 2.0) / tw, (radius * 2.0) / tw)
	sprite.modulate = color
	var label: String = behavior.display_label(level)
	$RichTextLabel.text = "[b]%s[/b]" % label


func _physics_process(_delta: float) -> void:
	if linear_velocity.y <= 1:
		physics_material_override.absorbent = true
	else:
		physics_material_override.absorbent = false
	if not visible:
		gravity_scale = 0.0
		return
	sleeping = false

	if Global.phase != Global.Phase.PLAY:
		set_up = false
		gravity_scale = GRAVITY_SCALE
		return

	if not set_up:
		gravity_scale = GRAVITY_SCALE
		return
	gravity_scale = 0.0
	direction = int((get_node("/root/Main/Target").position.x - self.position.x)/abs(get_node("/root/Main/Target").position.x - self.position.x))
	if abs(get_node("/root/Main/Target").position.x - self.position.x) < 15:
		direction = 0
	linear_velocity = Vector2(clamp(abs(get_node("/root/Main/Target").position.x - self.position.x) * 25, 0, 2500) * direction, 0)
	if Input.is_action_just_pressed("play_card"):
		gravity_scale = GRAVITY_SCALE
		set_up = false
		dropped.emit()

func _shake() -> void:
	if get_colliding_bodies().size() > 0:
		apply_central_impulse(Vector2(randi_range(-1, 1), randi_range(-1, 1)) * 500.0)
