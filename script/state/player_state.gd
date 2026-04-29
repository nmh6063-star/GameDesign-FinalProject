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


## Debug helper: equips a deterministic cross-rank ability set without reward selection.
func apply_test_current_abilities_set() -> void:
	var picks := {
		1: "venom_1",
		2: "triple_shot_2",
		3: "fireball_3",
		4: "chain_spark_4",
		5: "poison_rain_5",
		6: "chaos_rain_6",
		7: "apocalypse_7",
	}
	for rank in range(1, 8):
		var target := String(picks.get(rank, ""))
		var chosen := RankAbilityCatalog.default_element_for_rank(rank)
		for row in RankAbilityCatalog.all_display_rows_for_rank(rank):
			var fn := String(row.get("function", ""))
			if fn == target:
				chosen = {
					"name": row.get("name", ""),
					"type": RankAbilityCatalog.ELEMENT_TYPE,
					"function": fn,
					"description": row.get("description", ""),
					"rank": rank,
				}
				break
		elements[rank] = chosen
