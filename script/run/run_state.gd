extends Node

const DEFAULT_BALL_POOL: Array[String] = ["res://scenes/balls/ball_normal.tscn"]

var player_max_health := 100
var player_health := 100
var ball_pool: Array[String] = DEFAULT_BALL_POOL.duplicate()

var map_size := Vector2i(4, 2)
var map_layout: Dictionary = {}
var current_tile := Vector2i(-1, 0)


func heal_player(amount: int) -> void:
	player_health = min(player_health + amount, player_max_health)


func damage_player(amount: int) -> void:
	player_health = max(player_health - amount, 0)


func add_ball_to_pool(scene_path: String) -> void:
	if not ball_pool.has(scene_path):
		ball_pool.append(scene_path)


func ball_pool_paths() -> Array[String]:
	return ball_pool.duplicate()


func reset_map() -> void:
	ball_pool = DEFAULT_BALL_POOL.duplicate()
	map_layout.clear()
	current_tile = Vector2i(-1, 0)
