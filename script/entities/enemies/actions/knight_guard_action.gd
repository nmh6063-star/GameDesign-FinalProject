extends EnemyActionBase
class_name KnightGuardAction

const SHIELD_RESTORE := 20
const GUARD_ID := "enemy_guard"
const _ICON := preload("res://assets/enemies/attack_icon/guard icon no back.png")


func execute(ctx: BattleContext, enemy: EnemyBase) -> void:
	enemy.restore_shield(SHIELD_RESTORE)

	var loop = ctx.controller
	if loop == null:
		return
	var slots = loop._enemy_slots
	if not slots is Array:
		return
	for slot in slots:
		if slot._enemy_id == GUARD_ID and slot.is_alive():
			slot.enemy.restore_shield(SHIELD_RESTORE)


func action_name() -> String:
	return "Guard"


func icon_texture() -> Texture2D:
	return _ICON


func damage_amount(_enemy: EnemyBase) -> int:
	return 0


func special_effect() -> String:
	return "Restores %d shield to self and nearby allies" % SHIELD_RESTORE
