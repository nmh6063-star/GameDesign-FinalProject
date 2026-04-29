extends Resource
class_name MergeRuleBase


func participates_in_rank_merge() -> bool:
	return false


func can_merge(_ctx: BattleContext, _a: BallBase, _b: BallBase) -> bool:
	return false


func resolve(_ctx: BattleContext, _a: BallBase, _b: BallBase) -> void:
	push_error("MergeRuleBase.resolve() must be implemented")
