extends EnemyActionBase
class_name SelfHealAction

const HEAL_AMOUNT := 20

func execute(ctx: BattleContext, enemy: EnemyBase) -> void:
	enemy.current_health = mini(enemy.current_health + HEAL_AMOUNT, enemy.max_health())
	ctx.damage_player(enemy.data.attack_damage)
