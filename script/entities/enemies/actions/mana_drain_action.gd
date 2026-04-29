extends EnemyActionBase
class_name ManaDrainAction

func execute(ctx: BattleContext, enemy: EnemyBase) -> void:
	ctx.damage_player(enemy.data.attack_damage)
	ctx.try_spend_mana(1)
