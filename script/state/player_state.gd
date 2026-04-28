extends Node

const RankAbilityCatalog := preload("res://script/entities/balls/elemental_balls/rank_ability_catalog.gd")

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


func reset_default_rank_slots() -> void:
	elements[0] = []
	for r in range(1, 8):
		elements[r] = RankAbilityCatalog.default_element_for_rank(r)


func equip_rank_ability(rank: int, ability: Dictionary) -> void:
	if rank < 1 or rank > 7:
		return
	elements[rank] = ability.duplicate(true)


func reset_for_run() -> void:
	player_health = player_max_health
	aim_size_level = 0
	player_gold = 200
	reset_default_rank_slots()
