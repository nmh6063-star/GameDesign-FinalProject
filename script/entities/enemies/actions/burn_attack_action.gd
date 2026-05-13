extends EnemyActionBase
class_name BurnAttackAction

const _ICON := preload("res://assets/enemies/attack_icon/Burn icon no back.png")


func execute(ctx: BattleContext, enemy: EnemyBase) -> void:
	ctx.damage_player(enemy.data.effective_attack_damage())
	ctx.player_statuses["burn_stacks"] = int(ctx.player_statuses.get("burn_stacks", 0)) + 1


func action_name() -> String:
	return "Burn Attack"


func icon_texture() -> Texture2D:
	return _ICON


func special_effect() -> String:
	return "Inflicts burn, dealing damage every ball drop"
