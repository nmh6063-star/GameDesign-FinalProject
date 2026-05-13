extends EnemyActionBase
class_name DirectAttackAction

const _ICON := preload("res://assets/enemies/attack_icon/normal attack no back.png")


func execute(ctx: BattleContext, enemy: EnemyBase) -> void:
	ctx.damage_player(enemy.data.effective_attack_damage())


func action_name() -> String:
	return "Direct Attack"


func icon_texture() -> Texture2D:
	return _ICON


func special_effect() -> String:
	return "None"
