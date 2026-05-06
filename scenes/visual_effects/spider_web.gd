extends Node2D

const LIFETIME := 10.0
const MAX_SPEED := 120.0
const DRAG_PER_FRAME := 0.05

var _elapsed: float = 0.0
var _min_x: float = 0.0
var _max_x: float = 0.0
var _min_y: float = 0.0
var _mid_y: float = 0.0


func _ready() -> void:
	var interior := get_tree().current_scene.get_node_or_null("Background/Box/Interior") as Polygon2D
	if interior == null:
		return
	var board_min_x := INF
	var board_max_x := -INF
	var board_min_y := INF
	var board_max_y := -INF
	for point in interior.polygon:
		var g := interior.to_global(point)
		board_min_x = minf(board_min_x, g.x)
		board_max_x = maxf(board_max_x, g.x)
		board_min_y = minf(board_min_y, g.y)
		board_max_y = maxf(board_max_y, g.y)
	_min_x = board_min_x
	_max_x = board_max_x
	_min_y = board_min_y
	_mid_y = (board_min_y + board_max_y) / 2.0
	global_position = Vector2((_min_x + _max_x) / 2.0, (_min_y + _mid_y) / 2.0)
	var sprite := $Sprite2D
	if sprite.texture != null:
		var tex_size: Vector2 = sprite.texture.get_size()
		if tex_size.x > 0.0 and tex_size.y > 0.0:
			sprite.scale = Vector2((_max_x - _min_x) / tex_size.x, (_mid_y - _min_y) / tex_size.y)


func _physics_process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= LIFETIME:
		queue_free()
		return
	modulate.a = 1.0 - (_elapsed / LIFETIME)
	for node in get_tree().get_nodes_in_group("ball"):
		var rb := node as RigidBody2D
		if rb == null:
			continue
		var gp := rb.global_position
		if gp.x >= _min_x and gp.x <= _max_x and gp.y >= _min_y and gp.y <= _mid_y:
			var vel := rb.linear_velocity
			vel *= DRAG_PER_FRAME
			if vel.length() > MAX_SPEED:
				vel = vel.normalized() * MAX_SPEED
			rb.linear_velocity = vel
