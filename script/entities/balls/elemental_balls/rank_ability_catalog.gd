extends RefCounted
class_name RankAbilityCatalog

## Data for rank-slot abilities (type "Rank" → ElementalRankAbilities).

const ELEMENT_TYPE := "Rank"


static func default_element_for_rank(rank: int) -> Dictionary:
	match rank:
		1:
			return _ability("strike", rank, "Strike", "Deal 5 damage to current enemy.")
		2:
			return _ability("heavy_strike", rank, "Heavy Strike", "Deal 10 damage to one enemy.")
		3:
			return _ability("power_slash", rank, "Power Slash", "Deal 30 damage to one target.")
		4:
			return _ability("cleave", rank, "Cleave", "Deal 20 damage to all enemies.")
		5:
			return _ability("critical_edge", rank, "Critical Edge", "Deal random damage: 5 / 10 / 20 / 100.")
		6:
			return _ability("meteor_crash", rank, "Meteor Crash", "Deal 50 damage to all enemies.")
		7:
			return _ability("final_judgment", rank, "Final Judgment", "Deal 300 damage to one target.")
	return _ability("strike", rank, "Strike", "Deal 5 damage to current enemy.")


## Combined reward pools for reward tiers: 0 → ranks 1–3, 1 → 4–6, 2 → rank 7 only.
static func reward_pool_for_reward_range(range_id: int) -> Array[Dictionary]:
	match range_id:
		0:
			return _reward_pool_for_ranks(1, 3)
		1:
			return _reward_pool_for_ranks(4, 6)
		2:
			return _reward_pool_for_ranks(7, 7)
	return []


static func _reward_pool_for_ranks(low: int, high: int) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for r in range(low, high + 1):
		for opt in reward_options_for_rank(r):
			out.append(opt)
	return out


static func reward_options_for_rank(rank: int) -> Array[Dictionary]:
	match rank:
		1:
			return [
				_ability("mend", 1, "Mend", "Heal 5 HP."),
				_ability("venom", 1, "Venom", "Poison current enemy (15 stacks). Triggers before each enemy attack."),
				_ability("ember", 1, "Ember", "Burn all enemies (3 stacks). Deals 1 damage/sec per stack."),
				_ability("guard", 1, "Guard", "Gain 5 Shield."),
				_ability("critical", 1, "Critical", "50% deal 5 to all enemies, else deal 5 to current enemy."),
				_ability("refresh", 1, "Refresh", "Gain +1 mana."),
			]
		2:
			return [
				_ability("recovery", 2, "Recovery", "Heal 15% of missing HP."),
				_ability("frost_touch", 2, "Frost Touch", "Freeze all enemies for 5 seconds."),
				_ability("iron_guard", 2, "Iron Guard", "Gain 20 Shield."),
				_ability("triple_shot", 2, "Triple Shot", "Hit 3 random enemies for 8 each."),
				_ability("scatter_drop", 2, "Scatter Drop", "Drop 2 random balls (rank 1-3)."),
				_ability("critical_strike", 2, "Critical Strike", "50% deal 8 to all enemies, else deal 8 to one."),
				_ability("pollution", 2, "Pollution", "Double poison stacks on current enemy."),
				_ability("fireburn", 2, "FireBurn", "Burn all enemies (5 stacks)."),
			]
		3:
			return [
				_ability("toxic_burst", 3, "Toxic Burst", "Poison all enemies (20 stacks)."),
				_ability("fireball", 3, "Fireball", "Hit 2 random enemies for 5 each and apply Burn (5 stacks) to each."),
				_ability("ice_shield", 3, "Ice Shield", "Gain 10 Shield and Freeze current enemy (5 stacks = 5s)."),
				_ability("reinforce", 3, "Reinforce", "Gain +2 attack damage this battle (excludes DOT)."),
				_ability("convert", 3, "Convert", "Upgrade 1 random ball in the box by +1 rank (this battle)."),
				_ability("echo_shot", 3, "Echo Shot", "Reapply the last resolved damage + effect."),
				_ability("charm", 3, "Charm", "All enemies redirect their next attack at each other (1 stack)."),
			]
		4:
			return [
				_ability("greater_heal", 4, "Greater Heal", "Heal 30% of missing HP."),
				_ability("bomb_orb", 4, "Bomb Orb", "After 10s, deal 50 damage to all enemies."),
				_ability("chain_spark", 4, "Chain Spark", "Hit 3 enemies — 10 → 20 → 40 damage (doubles each hit)."),
				_ability("mirror_shield", 4, "Mirror Shield", "Reflect the next 2 incoming damage instances."),
				_ability("corrupt_field", 4, "Corrupt Field", "Apply Poison (20 stacks) to all enemies."),
			]
		5:
			return [
				_ability("freeze_wave", 5, "Freeze Wave", "Freeze all enemies (5 stacks = 5s)."),
				_ability("giant_orb", 5, "Giant Orb", "One random ball gets ×3 attack and ×2 visual size."),
				_ability("consume_core", 5, "Consume Core", "Remove 1 ball from the box → deal 100 damage to current enemy."),
				_ability("upgrade_pulse", 5, "Upgrade Pulse", "Upgrade a random nearby ball by +1 rank."),
				_ability("poison_rain", 5, "Poison Rain", "Poison all enemies (20 stacks)."),
				_ability("time_drift", 5, "Time Drift", "Slow time 10s. Damage you take in the first 5s is stored and reflected back to enemies over the final 5s."),
				_ability("contagion", 5, "Contagion", "Copy current enemy debuffs to one random other enemy (stacks with theirs)."),
			]
		6:
			return [
				_ability("full_recovery", 6, "Full Recovery", "Restore 30% of max HP."),
				_ability("chaos_rain", 6, "Chaos Rain", "Spawn 3 random balls (rank 1-3). Spend 1 mana to spawn 6 instead."),
				_ability("overcharge", 6, "Overcharge", "Gain +5 attack damage this battle."),
				_ability("mass_morph", 6, "Mass Morph", "Upgrade all rank 1 and 2 balls in the box by +1."),
				_ability("reflect_wall", 6, "Reflect Wall", "Reflect all incoming damage for 12 seconds."),
				_ability("giant_core", 6, "Giant Core", "One rank 1-5 ball gets ×3 attack, triggers twice, ×2 visual size."),
				_ability("dot_siphon", 6, "Siphon", "This battle: heal 20% of all DOT damage dealt to enemies."),
			]
		7:
			return [
				_ability("apocalypse", 7, "Apocalypse", "Deal 100 damage to all enemies."),
				_ability("resurrection", 7, "Resurrection", "Revive once with low HP upon death (this battle)."),
				_ability("time_stop", 7, "Time Stop", "Clear all balls from the box and freeze all enemies for 10s."),
				_ability("magic_flood", 7, "Magic Flood", "Apply random enchantment (Poison 8 / Burn 3 / Freeze 3 stacks) to all enemies."),
				_ability("miracle_cascade", 7, "Miracle Cascade", "Trigger one random ability from each of ranks 3, 4, and 5."),
				_ability("sacrifice_nova", 7, "Sacrifice Nova", "Lose 50% current HP → deal 500 damage to all enemies after 10s."),
				_ability("one_shower", 7, "1 Shower", "Continuously spawn rank 1-3 balls for 10 seconds."),
				_ability("dot_echo", 7, "Echo", "This battle: every DOT damage instance triggers twice."),
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
