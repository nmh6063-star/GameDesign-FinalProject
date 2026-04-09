extends Resource
class_name EnemyActionBase


func can_use(_ctx: BattleContext, _enemy: EnemyBase) -> bool:
	return true


func execute(_ctx: BattleContext, _enemy: EnemyBase) -> void:
	push_error("EnemyActionBase.execute() must be implemented")
