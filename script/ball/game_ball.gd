extends RigidBody2D
class_name GameBall

const BallBehavior := preload("res://script/ball/behaviors/ball_behavior.gd")

signal dropped

@export var behavior: BallBehavior

var set_up: bool = false
var move_speed: float = 200.0
var direction: int = 0
var level: int = 1
var reset: bool = false

const GRAVITY_SCALE := 2.0

const OUTLINE_WIDTH := 2.0
const OUTLINE_POINTS := 64


func _radius() -> float:
	var radius := 20.0
	if behavior != null and not behavior.participates_in_level_merge():
		return radius
	if reset:
		return radius
	for i in range(1, level):
		radius += 10.0 / i
	return radius


func get_radius() -> float:
	return _radius()


func _label_color() -> Color:
	var base := Color(0.3 + 0.05 * level, 0.8 - 0.06 * level, 0.3)
	if behavior == null:
		return base
	match behavior.kind:
		BallBehavior.Kind.DUPLICATION:
			return Color(0.75, 0.35, 0.95)
		BallBehavior.Kind.MULTIPLICATION:
			return Color(0.25, 0.55, 1.0)
		BallBehavior.Kind.HEAL:
			return Color(0.35, 0.92, 0.55)
		_:
			return base


func _ready() -> void:
	behavior = behavior if behavior != null else BallBehavior.from_kind(BallBehavior.Kind.NORMAL)
	add_to_group("ball")
	gravity_scale = 0.0
	_update_collision()
	queue_redraw()


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
	level += 1
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
	# Keep spare (hidden) balls from falling.
	if not visible:
		gravity_scale = 0.0
		return
	# Never allow visible balls to enter a sleeping physics state.
	# This prevents them from staying "stuck" when supports disappear.
	sleeping = false

	# Always enable gravity during resolve/other phases.
	if Global.phase != Global.Phase.PLAY:
		set_up = false
		gravity_scale = GRAVITY_SCALE
		return

	# PLAY phase: only control the ball while the player is aiming.
	if not set_up:
		gravity_scale = GRAVITY_SCALE
		return

	gravity_scale = 0.0
	direction = int(Input.is_action_pressed("right")) - int(Input.is_action_pressed("left"))
	linear_velocity = Vector2(move_speed * direction, 0.0)
	if Input.is_action_just_pressed("space"):
		gravity_scale = GRAVITY_SCALE
		set_up = false
		dropped.emit()


func _shake() -> void:
	if get_colliding_bodies().size() > 0:
		apply_central_impulse(Vector2(randi_range(-1, 1), randi_range(-1, 1)) * 500.0)
