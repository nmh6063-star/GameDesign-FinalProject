extends EnemyActionBase
class_name KnightGuardAction

const SHIELD_RESTORE := 20
const GUARD_ID := "enemy_guard"


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
