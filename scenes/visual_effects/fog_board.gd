extends Node2D

const LIFETIME := 8.0

var _elapsed: float = 0.0


func _ready() -> void:
	var interior := get_tree().current_scene.get_node_or_null("Background/Box/Interior") as Polygon2D
	if interior == null:
		return
	var min_x := INF
	var max_x := -INF
	var min_y := INF
	var max_y := -INF
	for point in interior.polygon:
		var g := interior.to_global(point)
		min_x = minf(min_x, g.x)
		max_x = maxf(max_x, g.x)
		min_y = minf(min_y, g.y)
		max_y = maxf(max_y, g.y)
	var board_center := Vector2((min_x + max_x) / 2.0, (min_y + max_y) / 2.0)
	var board_size := Vector2(max_x - min_x, max_y - min_y)
	global_position = board_center
	var sprite := $Sprite2D
	if sprite.texture != null:
		var tex_size: Vector2 = sprite.texture.get_size()
		if tex_size.x > 0.0 and tex_size.y > 0.0:
			sprite.scale = Vector2(board_size.x / tex_size.x, board_size.y / tex_size.y)


func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= LIFETIME:
		queue_free()
		return
	modulate.a = 1.0 - (_elapsed / LIFETIME)
