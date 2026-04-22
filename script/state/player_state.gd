extends Node

var player_max_health := 1000
var player_health := 1000
var aim_size_level: int = 0
var player_gold: int = 0
var elements = {
		0: [],
		1: null,
		2: null,
		3: null,
		4: null,
		5: null,
		6: null,
		7: null,
	}
var unlockedElementals = []


func heal(amount: int) -> void:
	player_health = min(player_health + amount, player_max_health)


func damage(amount: int) -> void:
	player_health = max(player_health - amount, 0)


func add_gold(amount: int) -> void:
	player_gold += amount


func spend_gold(amount: int) -> bool:
	if player_gold < amount:
		return false
	player_gold -= amount
	return true


func reset_for_run() -> void:
	player_health = player_max_health
	aim_size_level = 0
	player_gold = 200
