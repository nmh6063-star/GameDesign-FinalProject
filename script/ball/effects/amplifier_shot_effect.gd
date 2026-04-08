extends BallEffect
class_name AmplifierShotEffect

@export var multiplier: float = 1.5


func can_trigger(_ctx, _source) -> bool:
	return false


func apply(_ctx, _source) -> void:
	pass


func shot_multiplier(_source) -> float:
	return multiplier
