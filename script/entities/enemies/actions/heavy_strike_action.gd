extends EnemyActionBase
class_name HeavyStrikeAction

const DAMAGE_MULTIPLIER := 2

func execute(ctx: BattleContext, enemy: EnemyBase) -> void:
	ctx.damage_player(enemy.data.attack_damage * DAMAGE_MULTIPLIER)
