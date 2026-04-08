extends Node

var player_max_health := 100
var player_health := 100

var map_size := Vector2(4, 8)
var map_layout: Dictionary = {}
var current_tile := Vector2(-1, 0)


func heal_player(amount: int) -> void:
	player_health = min(player_health + amount, player_max_health)


func damage_player(amount: int) -> void:
	player_health = max(player_health - amount, 0)


func reset_map() -> void:
	map_layout.clear()
	current_tile = Vector2i(-1, 0)
