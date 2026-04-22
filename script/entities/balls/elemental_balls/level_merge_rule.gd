extends MergeRuleBase
class_name LevelMergeRule

@export var tolerance := 4.0


func participates_in_level_merge() -> bool:
	return true


func can_merge(ctx: BattleContext, a: BallBase, b: BallBase) -> bool:
	return (
		a.is_elemental()
		and b.is_elemental()
		and a.level == b.level
		and ctx.are_touching(a, b, tolerance)
		and a.rank < 7
		and b.rank < 7
	)


func resolve(ctx: BattleContext, a: BallBase, b: BallBase) -> void:
	a.merge_into_me(ctx, b)
	var temp = a.type.duplicate()
	for type in b.type:
		if not temp.has(type):
			temp.append(type)
	a.type = temp
	ctx.consume_ball(b)
