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
	)


func resolve(ctx: BattleContext, a: BallBase, b: BallBase) -> void:
	a.merge_into_me()
	ctx.consume_ball(b)
