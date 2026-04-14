extends Resource
class_name BallEffectBase


func can_trigger(_ctx: BattleContext, _source: BallBase) -> bool:
	return true


func apply(_ctx: BattleContext, _source: BallBase) -> void:
	push_error("BallEffectBase.apply() must be implemented")


func tick(_ctx: BattleContext, _source: BallBase) -> void:
	pass


func shot_multiplier(_source: BallBase) -> float:
	return 1.0


func on_merge(_ctx: BattleContext, _source: BallBase, _other: BallBase) -> void:
	pass


func on_shot(_ctx: BattleContext, _source: BallBase) -> void:
	pass


func on_destroy(_ctx: BattleContext, _source: BallBase) -> void:
	pass
