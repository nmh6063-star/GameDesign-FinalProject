extends Resource
class_name BallEffect


func can_trigger(_ctx, _source) -> bool:
	return true


func apply(_ctx, _source) -> void:
	push_error("BallEffect.apply() must be implemented")
