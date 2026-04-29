extends EnemyActionBase
class_name BurnAttackAction

func execute(ctx: BattleContext, enemy: EnemyBase) -> void:
	ctx.damage_player(enemy.data.attack_damage)
	ctx.burn_stacks += 1
