extends EnemyActionBase
class_name ManaDrainAction

const _ICON := preload("res://assets/enemies/attack_icon/mana drain no back.png")


func execute(ctx: BattleContext, enemy: EnemyBase) -> void:
	ctx.damage_player(enemy.data.attack_damage)
	ctx.try_spend_mana(1)


func icon_texture() -> Texture2D:
	return _ICON
