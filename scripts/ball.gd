extends RigidBody2D

signal dropped

var set_up: bool = false
var move_speed: float = 200.0
var direction: int = 0
var level: int = 1
var reset = false

const LABEL_FONT_SIZE := 24

func _radius() -> float:
	var radius = 20.0
	if !reset:
		for i in range(1, level):
			radius += 10.0/i
	return radius

func get_radius() -> float:
	return _radius()

func _ready() -> void:
	add_to_group("ball")
	gravity_scale = 0.0
	_update_collision()
	queue_redraw()

func _update_collision() -> void:
	var col := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if col and col.shape is CircleShape2D:
		var circle := (col.shape as CircleShape2D).duplicate()
		circle.radius = _radius()
		col.shape = circle

func merge_into_me() -> void:
	level += 1
	_update_collision()
	queue_redraw()

func _draw() -> void:
	var radius := _radius()
	var color := Color(0.3 + 0.05 * level, 0.8 - 0.06 * level, 0.3)
	#draw_circle(Vector2.ZERO, radius, color)
	var sprite = $Sprite2D
	var texture_width = sprite.texture.get_width()
	var scale_factor = (radius * 2) / texture_width
	sprite.scale = Vector2(scale_factor, scale_factor)
	sprite.modulate = color
	var font := ThemeDB.fallback_font
	var num := str(level)
	var sz := font.get_string_size(num, HORIZONTAL_ALIGNMENT_LEFT, -1, LABEL_FONT_SIZE)
	$RichTextLabel.text = num
	#draw_string(font, Vector2(-sz.x / 2.0, sz.y / 2.0), num, HORIZONTAL_ALIGNMENT_LEFT, -1, LABEL_FONT_SIZE)

func _physics_process(delta: float) -> void:
	if set_up:
		direction = int(Input.is_action_pressed("right")) - int(Input.is_action_pressed("left"))
		linear_velocity = Vector2(move_speed * direction, 0)
		if Input.is_action_just_pressed("space"):
			gravity_scale = 1.0
			set_up = false
			dropped.emit()
			
func _shake():
	var bodies = get_colliding_bodies()
	if bodies.size() > 0:
		apply_central_impulse(Vector2(randi_range(-1, 1), randi_range(-1, 1)) * 500.0)
