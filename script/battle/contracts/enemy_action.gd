extends Resource
class_name EnemyAction


func can_use(_ctx, _enemy) -> bool:
	return true


func execute(_ctx, _enemy) -> void:
	push_error("EnemyAction.execute() must be implemented")
