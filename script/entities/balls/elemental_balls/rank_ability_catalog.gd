extends RefCounted
class_name RankAbilityCatalog

## Data for rank-slot abilities (type "Rank" → ElementalRankAbilities).

const ELEMENT_TYPE := "Rank"


static func default_element_for_rank(rank: int) -> Dictionary:
	return _element(
		"attack_%d" % rank,
		rank,
		"Attack %d" % rank,
		"Deal damage to the selected enemy when this ball is shot at merge rank %d." % rank
	)


static func reward_options_for_rank(rank: int) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	out.append(
		_element(
			"defend_%d" % rank,
			rank,
			"Defend %d" % rank,
			"When this ball is shot at merge rank %d, recover a small amount of HP." % rank
		)
	)
	out.append(
		_element(
			"heal_%d" % rank,
			rank,
			"Heal %d" % rank,
			"When this ball is shot at merge rank %d, heal for a moderate amount." % rank
		)
	)
	out.append(
		_element(
			"attack_all_%d" % rank,
			rank,
			"Attack All %d" % rank,
			"When shot at merge rank %d, damage every living enemy." % rank
		)
	)
	return out


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


static func _element(function_id: String, rank: int, display_name: String, description: String) -> Dictionary:
	return {
		"name": display_name,
		"type": ELEMENT_TYPE,
		"function": function_id,
		"description": description,
		"rank": rank,
	}
