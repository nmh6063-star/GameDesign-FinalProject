extends RefCounted
class_name MapGenerator


func build(size: Vector2i) -> Dictionary:
	var tiles := {Vector2.ZERO: "empty"}
	for y in range(1, size.y):
		var range = (size.x - 1.0)/2.0
		var counter = -range
		while counter < range + 1.0:
			tiles[Vector2(counter, -y)] = _roll_tile_type()
			counter += 1
	tiles[Vector2(0, -size.y)] = "empty"
	"""
	for x in range(1, size.x):
		tiles[Vector2i(x, 0)] = _roll_tile_type()
		for direction in [-1, 1]:
			var y := 0
			while abs(y) < size.y and randi() % 2 == 1:
				y += direction
				tiles[Vector2i(x, y)] = _roll_tile_type()
	"""
	return tiles


func _roll_tile_type() -> String:
	var roll := randf()
	if roll < 0.25:
		return "fight"
	if roll < 0.5:
		return "chest"
	#if roll < 0.75:
		#return "shop"
	return "random"
