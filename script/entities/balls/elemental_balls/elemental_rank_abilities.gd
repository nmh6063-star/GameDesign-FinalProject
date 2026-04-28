extends ElementalRuleBase
class_name ElementalRankAbilities


static func get_target_function(_source: BallBase, function: String, function_match: String) -> bool:
	var parsed := _parse(function)
	if parsed.is_empty():
		return false
	if _source.rank != parsed["rank"]:
		return false
	return parsed["phase"] == function_match


static func can_trigger(_ctx: BattleContext, _source: BallBase, function: String) -> bool:
	return false


static func apply(_ctx: BattleContext, _source: BallBase, function: String) -> void:
	pass


static func on_shot(_ctx: BattleContext, _source: BallBase, function: String) -> void:
	var parsed := _parse(function)
	if parsed.is_empty() or parsed["phase"] != "on_shot":
		return
	if _source.rank != parsed["rank"]:
		return
	match String(parsed["kind"]):
		"attack":
			var ae := _ctx.active_enemy()
			if ae != null:
				_ctx.damage_enemy(parsed["rank"], ae)
		"attack_all":
			if _ctx.controller != null and _ctx.controller.has_method("damage_all_enemies"):
				_ctx.controller.damage_all_enemies(parsed["rank"], _ctx)
		"defend":
			_ctx.heal_player(4 * parsed["rank"])
		"heal":
			_ctx.heal_player(8 * parsed["rank"])


static func on_merge(_ctx: BattleContext, _source: BallBase, function: String) -> void:
	pass


static func _parse(function: String) -> Dictionary:
	var parts := function.split("_")
	if parts.is_empty():
		return {}
	var rank := parts[-1].to_int()
	if rank < 1 or rank > 7:
		return {}
	if parts.size() >= 3 and parts[0] == "attack" and parts[1] == "all":
		return {"kind": "attack_all", "rank": rank, "phase": "on_shot"}
	if parts[0] == "attack":
		return {"kind": "attack", "rank": rank, "phase": "on_shot"}
	if parts[0] == "defend":
		return {"kind": "defend", "rank": rank, "phase": "on_shot"}
	if parts[0] == "heal":
		return {"kind": "heal", "rank": rank, "phase": "on_shot"}
	return {}
