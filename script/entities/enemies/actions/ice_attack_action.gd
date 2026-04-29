extends EnemyActionBase
class_name IceAttackAction

# Number of ball drops the player must make before they can attack again.
const FREEZE_DURATION := 3

func execute(ctx: BattleContext, enemy: EnemyBase) -> void:
	ctx.damage_player(enemy.data.attack_damage)
	ctx.player_statuses["freeze_stacks"] = FREEZE_DURATION
