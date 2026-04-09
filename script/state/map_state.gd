extends Node

var map_size := Vector2i(4, 2)
var map_layout: Dictionary = {}
var current_tile := Vector2i(-1, 0)


func reset_for_run() -> void:
	map_layout.clear()
	current_tile = Vector2i(-1, 0)
