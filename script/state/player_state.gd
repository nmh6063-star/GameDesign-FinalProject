extends Node

var player_max_health := 100
var player_health := 100


func heal(amount: int) -> void:
	player_health = min(player_health + amount, player_max_health)


func damage(amount: int) -> void:
	player_health = max(player_health - amount, 0)


func reset_for_run() -> void:
	player_health = player_max_health
