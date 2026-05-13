extends RefCounted
class_name RankAbilityCatalog

## Data for rank-slot abilities (type "Rank" → ElementalRankAbilities).

const ELEMENT_TYPE := "Rank"


static func default_element_for_rank(rank: int) -> Dictionary:
	var r := clampi(rank, 1, 7)
	match r:
		1:
			return _ability("strike", 1, "Strike", "Deal 8 damage to current enemy.")
		2:
			return _ability("heavy_strike", 2, "Heavy Strike", "Deal 18 damage to current enemy.")
		3:
			return _ability("power_slash", 3, "Power Slash", "Deal 25 damage to current enemy.")
		4:
			return _ability("cleave", 4, "Cleave", "Deal 20 damage to all enemies.")
		5:
			var opts5 := reward_options_for_rank(5)
			if opts5.is_empty():
				return _ability("strike", 5, "Strike", "Deal 8 damage to current enemy.")
			return (opts5[0] as Dictionary).duplicate(true)
		6:
			return _ability("meteor_crash", 6, "Meteor Crash", "Deal 30 damage to all enemies.")
		7:
			return _ability("final_judgment", 7, "Final Judgment", "Deal 12 damage to current enemy 4 times (48 total).")
		_:
			# clampi(1,7) makes this unreachable; satisfies analyzer for Dictionary return.
			return _ability("strike", r, "Strike", "Deal 8 damage to current enemy.")


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
			_ability("charm", 3, "Charm", "All enemies redirect their next attack at each other (1 stack)."),
			_ability("thunder_fang", 3, "Thunder Fang", "Deal 5% current HP to target and 5% to each other enemy. Apply 5 ⚡ stacks to target and 3 to others. Thundered enemies pass (stack)% of any damage they receive to every other thundered enemy."),
		]
		4:
			return [
				_ability("greater_heal", 4, "Greater Heal", "Heal 30% of missing HP."),
				_ability("bomb_orb", 4, "Bomb Orb", "After 10s, deal 50 damage to all enemies. Countdown shown on enemies."),
				_ability("chain_spark", 4, "Chain Spark", "Hit 3 enemies — 20 → 15 → 10 damage."),
				_ability("mirror_shield", 4, "Mirror Shield", "Reflect the next 1 incoming damage instance. (Nerfed from 2.)"),
			_ability("corrupt_field", 4, "Corrupt Field", "Poison all enemies (9 stacks). This shoot, all poisoned enemies deal 20% less damage."),
			_ability("tide_turner", 4, "Tide Turner", "Shot alongside X other balls: after all shots resolve, deal X × the total damage those balls dealt this turn."),
			_ability("weakness_brand", 4, "Weakness Brand", "Mark the active enemy: they take 30% more direct damage for 3 shoots. (🔻 Brand indicator shown.)"),
			_ability("lifesteal_field", 4, "Lifesteal Field", "This battle: heal 5% of all direct damage dealt to enemies (separate from DoT Siphon)."),
			_ability("fortress", 4, "Fortress", "Gain 25 Shield. Take 8 HP damage (bypasses shield; cannot reduce HP below 1)."),
			_ability("mend_plus", 4, "Mend+", "Heal 8% of missing HP. Deal 12% of the healing as damage to current enemy."),
			_ability("bulwark", 4, "Bulwark", "Gain 30 Shield."),
			_ability("glacial_ward", 4, "Glacial Ward", "Gain 40 Shield and Freeze current enemy for 5 seconds."),
		]
		5:
			return [
			_ability("critical_edge", 5, "Critical Edge", "Deal 25 damage to 2 random enemies."),
			_ability("freeze_wave", 5, "Freeze Wave", "Freeze all enemies 8s — they cannot attack until thawed or they break free (chance each second: (HP%)×60% + 5%×elapsed s). No damage while frozen. Gain 50 Shield."),
			_ability("giant_orb", 5, "Giant Orb", "All current balls gain ×3 attack and ×2 size for 5 ball drops. Effect is inherited on merge (does not stack)."),
			_ability("consume_core", 5, "Consume Core", "Remove 1 ball from the box → deal 100 damage to current enemy."),
				_ability("poison_rain", 5, "Poison Rain", "For 3 shoots: enemies gain poison stacks instead of losing them, and every board merge adds +2 poison to all enemies. (☣ Rain indicator shown)"),
				_ability("time_drift", 5, "Time Drift", "10s: enemies cannot act, player ignores control effects. Damage taken in first 5s is reflected as DoT in last 5s."),
			_ability("contagion", 5, "Contagion", "Copy current enemy debuffs to one random other enemy (stacks with theirs)."),
		_ability("chaos_slash", 5, "Chaos Slash", "Strike 5 random targets for 15 each — can hit enemies or player. Each player hit inflicts Fragile: +20% damage taken until next shoot."),
		_ability("guillotine", 5, "Guillotine", "Deal damage equal to 25% of the active enemy's MISSING HP."),
			_ability("recovery_plus", 5, "Recovery+", "Heal 15% of missing HP."),
			_ability("iron_fortress", 5, "Iron Fortress", "Gain 60 Shield."),
			_ability("regen_pulse", 5, "Regen Pulse", "Heal 15 HP per second for 10 seconds (150 HP total)."),
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
		_ability("gatekeeper", 6, "Gatekeeper", "The next 3 times you take damage, convert 25% of each hit into Shield."),
			_ability("storm_surge", 6, "Storm Surge", "Deal 10% max HP to all enemies and apply 20 ⚡ thunder stacks to each."),
			_ability("second_wind", 6, "Second Wind", "When HP drops below 30%: heal 40% max HP (first use) or 10% missing HP (repeat). One trigger per low-HP event."),
			_ability("overkill", 6, "Overkill", "Deal 40 damage to the active enemy. For the rest of this battle: excess damage from any kill spills to the next alive enemy."),
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
			_ability("baators_flame", 7, "Baator's Flame", "Convert all DoT on enemies to Burn: Poison ×1.5, ⚡Thunder ×2, Freeze ×10 stacks."),
			_ability("thunder_strike", 7, "Thunder Strike", "If no enemy has ⚡ thunder: apply 15 stacks to the current enemy. Otherwise, each enemy with thunder takes 2% of their current HP damage per stack."),
			_ability("elbaphs_power", 7, "Elbaph's Power", "For 15s: all ball sizes scale 1.0×→1.5× and direct damage scales 1.0×→3.0×. Excludes DoT."),
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
