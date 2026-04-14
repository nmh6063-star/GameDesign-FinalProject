extends Resource
class_name EnemyEffectBase


func on_turn_start(_ctx: BattleContext, _enemy: EnemyBase) -> void:
	pass


func on_before_act(_ctx: BattleContext, _enemy: EnemyBase, _action: EnemyActionBase) -> void:
	pass


func on_after_act(_ctx: BattleContext, _enemy: EnemyBase, _action: EnemyActionBase) -> void:
	pass


func on_hit(_ctx: BattleContext, _enemy: EnemyBase, _amount: int) -> void:
	pass


func on_defeated(_ctx: BattleContext, _enemy: EnemyBase) -> void:
	pass
