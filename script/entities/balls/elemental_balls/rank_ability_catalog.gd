extends RefCounted
class_name RankAbilityCatalog

## Data for rank-slot abilities (type "Rank" → ElementalRankAbilities).

const ELEMENT_TYPE := "Rank"


static func default_element_for_rank(rank: int) -> Dictionary:
	match rank:
		1:
			return _ability("strike", rank, "Strike", "Attack all enemies for 1.")
		2:
			return _ability("heavy_strike", rank, "Heavy Strike", "Attack 10.")
		3:
			return _ability("power_slash", rank, "Power Slash", "Attack 30.")
		4:
			return _ability("cleave", rank, "Cleave", "Attack all enemies for 20.")
		5:
			return _ability("critical_edge", rank, "Critical Edge", "Deal random damage: 5/10/20/100.")
		6:
			return _ability("meteor_crash", rank, "Meteor Crash", "Attack all enemies for 100.")
		7:
			return _ability("final_judgment", rank, "Final Judgment", "Massive single-target attack 1000.")
	return _ability("strike", rank, "Strike", "Attack all enemies for 1.")


static func reward_options_for_rank(rank: int) -> Array[Dictionary]:
	match rank:
		1:
			return [
				_ability("mend", 1, "Mend", "Heal 3."),
				_ability("venom", 1, "Venom", "Poison: 10 stack, 1 strength."),
				_ability("ember", 1, "Ember", "Burn: 10 stack, 2 strength."),
				_ability("guard", 1, "Guard", "Gain Shield 5."),
				_ability("critical", 1, "Critical", "50% chance deal 5, else 1."),
				_ability("refresh", 1, "Refresh", "Gain +1 mana."),
			]
		2:
			return [
				_ability("recovery", 2, "Recovery", "Heal 25% of lost health."),
				_ability("frost_touch", 2, "Frost Touch", "Freeze 5 stack."),
				_ability("iron_guard", 2, "Iron Guard", "Gain Shield 20."),
				_ability("triple_shot", 2, "Triple Shot", "Random enemy hit 5 x3."),
				_ability("scatter_drop", 2, "Scatter Drop", "Drop 2 random balls (rank 1-3)."),
				_ability("critical_strike", 2, "Critical Strike", "50% all enemies 5, else single enemy 5."),
				_ability("pollution", 2, "Pollution", "Double poison strength on enemy."),
				_ability("fireburn", 2, "FireBurn", "Burn: 10 stack, 5 strength."),
			]
		3:
			return [
				_ability("toxic_burst", 3, "Toxic Burst", "Poison: 30 stack, 1 strength."),
				_ability("fireball", 3, "Fireball", "Attack 5 and Burn 5 stack, 10 strength."),
				_ability("ice_lance", 3, "Ice Lance", "Attack 5 and Freeze 5 stack."),
				_ability("reinforce", 3, "Reinforce", "Gain +3 attack this battle."),
				_ability("convert", 3, "Convert", "Upgrade rank of 1 random ball in box."),
				_ability("echo_shot", 3, "Echo Shot", "Reapply last damage and effect."),
				_ability("charm", 3, "Charm", "Charm: 5 stack."),
			]
		4:
			return [
				_ability("greater_heal", 4, "Greater Heal", "Heal 50% of lost health."),
				_ability("bomb_orb", 4, "Bomb Orb", "After 10s, attack all enemies for 50."),
				_ability("chain_spark", 4, "Chain Spark", "Hit 3 enemies, damage doubles each hit from 10."),
				_ability("mirror_shield", 4, "Mirror Shield", "Reflect next incoming damage."),
				_ability("corrupt_field", 4, "Corrupt Field", "Apply poison 10 stack, 2 strength to balls passing zone."),
			]
		5:
			return [
				_ability("freeze_wave", 5, "Freeze Wave", "Apply Freeze 5 stack to all enemies."),
				_ability("giant_orb", 5, "Giant Orb", "One ball gets x2 attack, x2 trigger, x3 size."),
				_ability("consume_core", 5, "Consume Core", "Destroy 1 ball in box, attack 100."),
				_ability("upgrade_pulse", 5, "Upgrade Pulse", "Upgrade random nearby ball +1 rank."),
				_ability("poison_rain", 5, "Poison Rain", "Poison all enemies 20 stack, 1 strength."),
				_ability("time_drift", 5, "Time Drift", "Slow time for 10 seconds."),
			]
		6:
			return [
				_ability("full_recovery", 6, "Full Recovery", "Fully heal and remove debuffs."),
				_ability("chaos_rain", 6, "Chaos Rain", "Spawn 5 random balls rank 1-3 and lose 1 mana."),
				_ability("overcharge", 6, "Overcharge", "Gain +10 attack this battle."),
				_ability("mass_morph", 6, "Mass Morph", "Upgrade all rank 1-2 balls by +1."),
				_ability("reflect_wall", 6, "Reflect Wall", "Reflect enemy damage for 20 seconds."),
				_ability("giant_core", 6, "Giant Core", "One ball gets x3 attack, x2 trigger, x3 size."),
			]
		7:
			return [
				_ability("apocalypse", 7, "Apocalypse", "Attack all enemies for 100."),
				_ability("resurrection", 7, "Resurrection", "Revive once with low HP."),
				_ability("time_stop", 7, "Time Stop", "Delete half balls and freeze enemy timers for 20s."),
				_ability("magic_flood", 7, "Magic Flood", "Buff all balls with random poison/fire/ice enchantment."),
				_ability("miracle_cascade", 7, "Miracle Cascade", "Trigger random rank 3/4/5 effect."),
				_ability("sacrifice_nova", 7, "Sacrifice Nova", "Lose 50% HP, then after 10s attack all for 500."),
				_ability("one_shower", 7, "1 Shower", "Drop rank 1 balls continuously for 30s."),
			]
	return []


static func all_display_rows_for_rank(rank: int) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	var base := default_element_for_rank(rank)
	rows.append(
		{"name": base["name"], "description": base["description"], "is_base": true, "function": base["function"]}
	)
	for opt in reward_options_for_rank(rank):
		rows.append(
			{
				"name": opt["name"],
				"description": opt["description"],
				"is_base": false,
				"function": opt["function"],
			}
		)
	return rows


static func _ability(ability_id: String, rank: int, display_name: String, description: String) -> Dictionary:
	return _element("%s_%d" % [ability_id, rank], rank, display_name, description)


static func _element(function_id: String, rank: int, display_name: String, description: String) -> Dictionary:
	return {
		"name": display_name,
		"type": ELEMENT_TYPE,
		"function": function_id,
		"description": description,
		"rank": rank,
	}
