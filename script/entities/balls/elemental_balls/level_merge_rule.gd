extends MergeRuleBase
class_name RankMergeRule

@export var tolerance := 4.0


func participates_in_rank_merge() -> bool:
	return true


func can_merge(ctx: BattleContext, a: BallBase, b: BallBase) -> bool:
	return (
		a.is_elemental()
		and b.is_elemental()
		and a.rank == b.rank
		and ctx.are_touching(a, b, tolerance)
		and a.rank < 7
		and b.rank < 7
		and a.typing == b.typing
	)


func resolve(ctx: BattleContext, a: BallBase, b: BallBase) -> void:
	# Giant buff inheritance: if b carries the buff and a doesn't, pass it to a
	var b_st := ctx.ball_status_for(b)
	var a_st := ctx.ball_status_for(a)
	if int(b_st.get("giant_drops_left", 0)) > 0 and not bool(a_st.get("is_giant", false)):
		a_st["attack_mult"]      = float(b_st.get("attack_mult", 1.0))
		a_st["size_mult"]        = float(b_st.get("size_mult", 1.0))
		a_st["trigger_twice"]    = bool(b_st.get("trigger_twice", false))
		a_st["is_giant"]         = true
		a_st["giant_drops_left"] = int(b_st.get("giant_drops_left", 0))
	a.merge_into_me(ctx, b)
	var keep_uid := int(a_st.get("stat_uid", 0))
	var drop_uid := int(b_st.get("stat_uid", 0))
	if keep_uid > 0 and drop_uid > 0:
		PlayerState.merge_ball_battle_damage_uids(keep_uid, drop_uid)
	elif drop_uid > 0 and keep_uid <= 0:
		a_st["stat_uid"] = drop_uid
	var temp = a.type.duplicate()
	for type in b.type:
		if not temp.has(type):
			temp.append(type)
	a.type = temp
	ctx.consume_ball(b)
