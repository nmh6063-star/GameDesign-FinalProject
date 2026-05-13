extends Node

const RankAbilityCatalog := preload("res://script/entities/balls/elemental_balls/rank_ability_catalog.gd")

var player_max_health := 500
var player_health := 500
var aim_size_level: int = 0
var player_gold: int = 0
## Last boss battle: per-ball damage (merge combines uids) and per-rank-slot ability damage segments.
var run_rank_segment_history: Array = []
var battle_ball_damage: Dictionary = {}
var _battle_next_stat_uid: int = 1
## Filled when the boss is defeated; consumed by the victory screen.
var pending_victory_snapshot: Dictionary = {}
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
	player_gold = 50
	run_rank_segment_history.clear()
	pending_victory_snapshot.clear()
	reset_default_rank_slots()


func reset_battle_damage_stats() -> void:
	battle_ball_damage.clear()
	_battle_next_stat_uid = 1


func alloc_ball_stat_uid() -> int:
	var u := _battle_next_stat_uid
	_battle_next_stat_uid += 1
	return u


func record_ball_battle_damage(uid: int, amount: int) -> void:
	if uid <= 0 or amount <= 0:
		return
	battle_ball_damage[uid] = int(battle_ball_damage.get(uid, 0)) + amount


func merge_ball_battle_damage_uids(keep_uid: int, drop_uid: int) -> void:
	if drop_uid <= 0 or keep_uid == drop_uid:
		return
	var d := int(battle_ball_damage.get(drop_uid, 0))
	battle_ball_damage.erase(drop_uid)
	if keep_uid > 0 and d > 0:
		battle_ball_damage[keep_uid] = int(battle_ball_damage.get(keep_uid, 0)) + d


func record_run_rank_segment_damage(rank: int, kind: String, amount: int) -> void:
	if amount <= 0 or rank < 1 or kind.is_empty():
		return
	var ab: Variant = elements.get(rank)
	var nm := kind
	if ab is Dictionary:
		nm = str(ab.get("name", kind))
	var idx := -1
	for i in range(run_rank_segment_history.size() - 1, -1, -1):
		var seg: Dictionary = run_rank_segment_history[i]
		if int(seg.get("rank", 0)) == rank:
			idx = i
			break
	if idx < 0:
		run_rank_segment_history.append({"rank": rank, "kind": kind, "name": nm, "damage": amount})
		return
	var last: Dictionary = run_rank_segment_history[idx]
	if str(last.get("kind", "")) == kind:
		last["damage"] = int(last.get("damage", 0)) + amount
	else:
		run_rank_segment_history.append({"rank": rank, "kind": kind, "name": nm, "damage": amount})


func begin_stat_attrib_execute(ctx: Variant, source: Variant, rank: int, kind: String) -> void:
	var st = ctx.battle_flags
	var stack: Array = st.get("stat_attrib_stack", []) as Array
	stack.append({
		"uid": int(st.get("stat_damage_uid", 0)),
		"rank": int(st.get("stat_rank_slot", 0)),
		"kind": str(st.get("stat_ability_kind", "")),
	})
	st["stat_attrib_stack"] = stack
	var uid := 0
	if is_instance_valid(source):
		uid = int(ctx.ball_status_for(source).get("stat_uid", 0))
	st["stat_damage_uid"] = uid
	st["stat_rank_slot"] = rank
	st["stat_ability_kind"] = kind


func end_stat_attrib_execute(ctx: Variant) -> void:
	var st = ctx.battle_flags
	var stack: Array = st.get("stat_attrib_stack", []) as Array
	if stack.is_empty():
		return
	var prev: Dictionary = stack.pop_back()
	st["stat_attrib_stack"] = stack
	st["stat_damage_uid"] = int(prev.get("uid", 0))
	st["stat_rank_slot"] = int(prev.get("rank", 0))
	st["stat_ability_kind"] = str(prev.get("kind", ""))
	st.erase("status_stack_enforce")


func build_victory_snapshot(ctx: Variant, battle_loop: Node) -> Dictionary:
	var ball_rows: Array = []
	if battle_loop != null and battle_loop.has_method("active_balls"):
		for ball in battle_loop.call("active_balls"):
			if not is_instance_valid(ball):
				continue
			var uid := 0
			if ctx != null and ctx.has_method("ball_status_for"):
				uid = int(ctx.ball_status_for(ball).get("stat_uid", 0))
			var dmg := int(battle_ball_damage.get(uid, 0))
			var lbl := ""
			if ball.data != null:
				lbl = ball.data.display_label(ball.rank)
			ball_rows.append({"rank": ball.rank, "label": lbl, "damage": dmg, "uid": uid})
		ball_rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			return int(a.get("rank", 0)) < int(b.get("rank", 0))
		)
	var rank_rows: Array = []
	for seg in run_rank_segment_history:
		if seg is Dictionary:
			var sd: Dictionary = seg
			var d := int(sd.get("damage", 0))
			if d > 0:
				rank_rows.append(sd.duplicate())
	return {
		"balls": ball_rows,
		"rank_segments": rank_rows,
		"gold": player_gold,
		"seed": _current_run_seed(),
	}


func _current_run_seed() -> int:
	var gm = Engine.get_main_loop().root.get_node_or_null("GameManager")
	if gm != null and gm.has_method("current_seed"):
		return int(gm.current_seed())
	return 0


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
