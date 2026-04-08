extends MergeRule
class_name LevelMergeRule

@export var tolerance := 4.0


func participates_in_level_merge() -> bool:
	return true


func can_merge(ctx: BattleContext, a, b) -> bool:
	return a.level == b.level and ctx.are_touching(a, b, tolerance)


func resolve(ctx: BattleContext, a, b) -> void:
	a.merge_into_me()
	ctx.consume_ball(b)
	ctx.wake_playfield()
