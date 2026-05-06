extends EnemyActionBase
class_name IceAttackAction

const FREEZE_DURATION := 3
const _ICON := preload("res://assets/enemies/attack_icon/ice icon no back.png")


func execute(ctx: BattleContext, enemy: EnemyBase) -> void:
	ctx.damage_player(enemy.data.attack_damage)
	ctx.player_statuses["freeze_stacks"] = FREEZE_DURATION


func action_name() -> String:
	return "Ice Attack"


func icon_texture() -> Texture2D:
	return _ICON


func special_effect() -> String:
	return "Freezes player for %d turns" % FREEZE_DURATION
