extends EnemyActionBase
class_name BurnAttackAction

func execute(ctx: BattleContext, enemy: EnemyBase) -> void:
	ctx.damage_player(enemy.data.attack_damage)
	ctx.player_statuses["burn_stacks"] = int(ctx.player_statuses.get("burn_stacks", 0)) + 1
