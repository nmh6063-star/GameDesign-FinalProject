extends EnemyActionBase
class_name HeavyStrikeAction

const DAMAGE_MULTIPLIER := 2
const _ICON := preload("res://assets/enemies/attack_icon/heavy strike no back.png")


func execute(ctx: BattleContext, enemy: EnemyBase) -> void:
	ctx.damage_player(enemy.data.effective_attack_damage() * DAMAGE_MULTIPLIER)


func action_name() -> String:
	return "Heavy Strike"


func icon_texture() -> Texture2D:
	return _ICON


func damage_amount(enemy: EnemyBase) -> int:
	return enemy.data.effective_attack_damage() * DAMAGE_MULTIPLIER if enemy != null and enemy.data != null else 0


func special_effect() -> String:
	return "Deals double damage"
