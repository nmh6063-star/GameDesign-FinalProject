extends BallEffectBase
class_name ShotAmplifierEffect

@export var multiplier: float = 1.5


func can_trigger(_ctx: BattleContext, _source: BallBase) -> bool:
	return false


func apply(_ctx: BattleContext, _source: BallBase) -> void:
	pass


func shot_multiplier(_source: BallBase) -> float:
	return multiplier
