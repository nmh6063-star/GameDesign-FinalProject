extends EnemyActionBase
class_name DirectAttackAction


func execute(ctx: BattleContext, enemy: EnemyBase) -> void:
	ctx.damage_player(enemy.data.attack_damage)
