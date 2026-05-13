extends Resource
class_name EnemyActionBase


func can_use(_ctx: BattleContext, _enemy: EnemyBase) -> bool:
	return true


func execute(_ctx: BattleContext, _enemy: EnemyBase) -> void:
	push_error("EnemyActionBase.execute() must be implemented")


func action_name() -> String:
	return "Attack"


func icon_texture() -> Texture2D:
	return preload("res://assets/enemies/attack_icon/normal attack no back.png")


func damage_amount(enemy: EnemyBase) -> int:
	return enemy.data.effective_attack_damage() if enemy != null and enemy.data != null else 0


func special_effect() -> String:
	return "None"
