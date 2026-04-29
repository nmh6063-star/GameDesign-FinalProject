extends "res://script/entities/balls/ball_base.gd"
class_name ElementalBallBase


func check_merge(ctx: BattleContext, other: BallBase) -> bool:
	if other == null or not other.is_elemental():
		return false
	var rule: MergeRuleBase = _merge_rule()
	return rule != null and rule.can_merge(ctx, self, other)


func merge_with(ctx: BattleContext, other: BallBase, rank_strength: float) -> void:
	var rule: MergeRuleBase = _merge_rule()
	if rule == null:
		return
	rule.resolve(ctx, self, other)
	for effect in _effects():
		effect.on_merge(ctx, self, other)
	ctx.register_merge()
	ctx.burst(global_position, rank_strength)
