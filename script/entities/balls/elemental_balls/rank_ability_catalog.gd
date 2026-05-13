extends RefCounted
class_name RankAbilityCatalog

## Data for rank-slot abilities (type "Rank" → ElementalRankAbilities).

const ELEMENT_TYPE := "Rank"


static func default_element_for_rank(rank: int) -> Dictionary:
	var r := clampi(rank, 1, 7)
	var dmg := 10 + (r - 1) * 4
	return _ability("strike", r, "Strike", "Deal %d damage to current enemy." % dmg)


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
				_ability("venom", 1, "Venom", "Poison current enemy (5 stacks)."),
				_ability("ember", 1, "Ember", "Burn all enemies (3 stacks). Deals 1 damage/sec per stack."),
				_ability("critical", 1, "Critical", "50% deal 5 to all enemies, else deal 5 to current enemy."),
				_ability("refresh", 1, "Refresh", "Gain +1 mana."),
			]
		2:
			return [
				_ability("frost_touch", 2, "Frost Touch", "Freeze all enemies for 5 seconds."),
				_ability("triple_shot", 2, "Triple Shot", "Hit 4 random enemies for 6 each."),
			_ability("heavy_strike", 2, "Heavy Strike", "Deal 18 damage to current enemy."),
			_ability("scatter_drop", 2, "Scatter Drop", "Drop 2 random balls (rank 1-3)."),
			_ability("critical_strike", 2, "Critical Strike", "50% deal 20 to current enemy, else deal 10 to current enemy."),
			_ability("fireburn", 2, "FireBurn", "Burn all enemies (5 stacks)."),
			_ability("toxic_burst", 2, "Toxic Burst", "Apply Poison (6 stacks) to 2 random enemies."),
			]
		3:
			return [
				_ability("pollution", 3, "Pollution", "If the current enemy has no poison: apply 10 poison. If they already have poison: that enemy loses half their poison stacks (rounded down)."),
				_ability("fireball", 3, "Fireball", "Hit 2 random enemies for 8 each and apply Burn (8 stacks) to each."),
			_ability("reinforce", 3, "Reinforce", "Gain +2 attack damage this battle (excludes DOT)."),
				_ability("convert", 3, "Convert", "Upgrade 1 random ball in the box by +1 rank (this battle)."),
			_ability("echo_shot", 3, "Echo Shot", "Reapply the last resolved damage + effect."),
			_ability("charm", 3, "Charm", "All enemies gain 1 charm stack. On their next attack, 50% chance the hit strikes one random other enemy (single target); otherwise it hits you."),
		]
		4:
			return [
				_ability("greater_heal", 4, "Greater Heal", "Heal 30% of missing HP."),
				_ability("bomb_orb", 4, "Bomb Orb", "After 10s, deal 50 damage to all enemies. Countdown shown on enemies."),
				_ability("chain_spark", 4, "Chain Spark", "Hit 3 enemies — 20 → 15 → 10 damage."),
				_ability("mirror_shield", 4, "Mirror Shield", "Reflect the next 1 incoming damage instance. (Nerfed from 2.)"),
			_ability("corrupt_field", 4, "Corrupt Field", "Poison all enemies (9 stacks). This shoot, all poisoned enemies deal 20% less damage."),
		]
		5:
			return [
			_ability("critical_edge", 5, "Critical Edge", "Deal 25 damage to each of 2 random enemies (same enemy can be hit twice)."),
			_ability("freeze_wave", 5, "Freeze Wave", "Freeze all enemies 8s — they cannot attack until thawed or they break free (chance each second: (HP%)×60% + 5%×elapsed s). No damage while frozen. Gain 50 Shield."),
			_ability("giant_orb", 5, "Giant Orb", "All current balls gain ×3 attack and ×2 size for 5 ball drops. Effect is inherited on merge (does not stack)."),
			_ability("consume_core", 5, "Consume Core", "Remove 1 ball from the box → deal 50 damage to current enemy."),
				_ability("poison_rain", 5, "Poison Rain", "For 5 shoots: every board merge adds +3 poison to all enemies. (☣ Rain indicator shown)"),
				_ability("time_drift", 5, "Time Drift", "10s: enemies cannot act, player ignores control effects. Damage taken in first 5s is reflected as DoT in last 5s."),
			_ability("contagion", 5, "Contagion", "Copy current enemy debuffs to one random other enemy (stacks with theirs)."),
		]
		6:
			return [
			_ability("full_recovery", 6, "Full Recovery", "Restore 30% of max HP."),
			_ability("chaos_rain", 6, "Chaos Rain", "Spawn 3 random balls (rank 1-3). Spend 1 mana to spawn 6 instead."),
			_ability("overcharge", 6, "Overcharge", "Gain +5 attack damage this battle."),
			_ability("mass_morph", 6, "Mass Morph", "Upgrade all rank 1 and 2 balls in the box by +1."),
			_ability("reflect_wall", 6, "Reflect Wall", "Reflect all incoming damage for 12 seconds."),
			_ability("giant_core", 6, "Giant Core", "All current balls gain ×3 attack, trigger twice, and ×2 size for 5 ball drops. Effect is inherited on merge (does not stack)."),
		_ability("dot_siphon", 6, "Siphon", "This battle: heal 10% of all DOT damage dealt to enemies."),
		]
		7:
			return [
			_ability("apocalypse", 7, "Apocalypse", "Deal 8 damage to all enemies 6 times (48 total)."),
			_ability("resurrection", 7, "Resurrection", "Revive once with low HP upon death (this battle)."),
			_ability("time_stop", 7, "Time Stop", "Remove the highest-rank ball on the board (random if tied). Freeze all enemies for 10s — they cannot act and take 50% more damage."),
			_ability("magic_flood", 7, "Magic Flood", "Apply 10 random enchantments (Poison 8 / Burn 3 / Freeze 3) each to a random enemy."),
				_ability("miracle_cascade", 7, "Miracle Cascade", "Trigger one random ability from each of ranks 3, 4, and 5."),
				_ability("sacrifice_nova", 7, "Sacrifice Nova", "Lose 50% current HP → deal 800 damage to all enemies after 10s."),
				_ability("one_shower", 7, "Shower", "Spawn 10 rank 1-3 balls spread randomly across the box (1 per second for 10s)."),
			_ability("dot_echo", 7, "Echo", "This battle: every DOT damage instance triggers twice."),
		]
	return []


static func all_display_rows_for_rank(rank: int) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	var base := default_element_for_rank(rank)
	var base_fn := String(base.get("function", ""))
	rows.append(
		{"name": base["name"], "description": base["description"], "is_base": true, "function": base["function"]}
	)
	for opt in reward_options_for_rank(rank):
		if String(opt.get("function", "")) == base_fn:
			continue
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
