extends RigidBody2D
class_name GameBall

const BattleState := preload("res://script/battle/state/state.gd")
const BallData := preload("res://script/ball/ball_data.gd")

signal dropped

@export var data: BallData

var battle_state: BattleState
var aim_target: Node2D
var set_up := false
var level := 1

const GRAVITY_SCALE := 2.0
const OUTLINE_WIDTH := 2.0
const OUTLINE_POINTS := 64


func _ready() -> void:
	add_to_group("ball")
	gravity_scale = 0.0
	contact_monitor = true
	max_contacts_reported = 10
	refresh()


func set_runtime(state: BattleState, target: Node2D) -> void:
	battle_state = state
	aim_target = target


func configure(ball_data: BallData, ball_level: int, state: BattleState, target: Node2D) -> void:
	data = ball_data
	level = ball_level
	set_runtime(state, target)
	refresh()


func refresh() -> void:
	_update_collision()
	queue_redraw()


func set_collision_enabled(enabled: bool) -> void:
	($CollisionShape2D as CollisionShape2D).disabled = not enabled


func set_playfield_state(is_set_up: bool) -> void:
	set_up = is_set_up
	gravity_scale = 0.0 if set_up else GRAVITY_SCALE


func participates_in_level_merge() -> bool:
	return data.participates_in_level_merge()


func has_tag(tag: String) -> bool:
	return data.has_tag(tag)


func get_radius() -> float:
	return data.radius_for_level(level)


func _update_collision() -> void:
	var col := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if col == null or not col.shape is CircleShape2D:
		return
	var circle := (col.shape as CircleShape2D).duplicate()
	circle.radius = get_radius()
	col.shape = circle


func merge_into_me() -> void:
	level *= 2
	refresh()


func _draw() -> void:
	var radius := get_radius()
	var color := data.display_color(level)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, OUTLINE_POINTS, color, OUTLINE_WIDTH, true)
	var sprite := $Sprite2D as Sprite2D
	var scale := (radius * 2.0) / float(sprite.texture.get_width())
	sprite.scale = Vector2.ONE * scale
	sprite.modulate = color
	($RichTextLabel as RichTextLabel).text = "[b]%s[/b]" % data.display_label(level)


func _physics_process(_delta: float) -> void:
	physics_material_override.absorbent = linear_velocity.y <= 1.0
	if not visible:
		gravity_scale = 0.0
		return
	sleeping = false

	if battle_state.phase != BattleState.Phase.PLAY:
		set_up = false
		gravity_scale = GRAVITY_SCALE
		return
	if not set_up:
		gravity_scale = GRAVITY_SCALE
		return
	gravity_scale = 0.0
	var delta_x := aim_target.position.x - position.x
	var direction := 0.0 if absf(delta_x) < 15.0 else signf(delta_x)
	linear_velocity = Vector2(clampf(absf(delta_x) * 25.0, 0.0, 2500.0) * direction, 0.0)
	if Input.is_action_just_pressed("play_card"):
		gravity_scale = GRAVITY_SCALE
		set_up = false
		dropped.emit()
