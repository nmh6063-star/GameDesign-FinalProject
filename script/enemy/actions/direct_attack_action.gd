extends EnemyAction
class_name DirectAttackAction


func execute(ctx: BattleContext, enemy) -> void:
	ctx.damage_player(enemy.data.attack_damage)
