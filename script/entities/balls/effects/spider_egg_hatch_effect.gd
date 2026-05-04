extends BallEffectBase
class_name SpiderEggHatchEffect

const SPIDER_ID := "enemy_small_spider"
const QUEEN_ID := "enemy_spider_queen"


func can_trigger(_ctx: BattleContext, _source: BallBase) -> bool:
	return false


func apply(_ctx: BattleContext, _source: BallBase) -> void:
	pass


func on_destroy(ctx: BattleContext, _source: BallBase) -> void:
	var loop = ctx.controller
	if loop == null or not loop.has_method("_on_enemy_action_requested"):
		return
	var enemy_slots = loop._enemy_slots
	if not enemy_slots is Array:
		return
	var queen_alive := false
	for slot in enemy_slots:
		if slot._enemy_id == QUEEN_ID and slot.is_alive():
			queen_alive = true
			break
	if not queen_alive:
		return
	var on_action := Callable(loop, "_on_enemy_action_requested")
	for slot in enemy_slots:
		if slot._enemy_id == QUEEN_ID:
			continue
		if not slot.is_alive():
			slot._enemy_id = SPIDER_ID
			var enemy = slot.spawn_enemy()
			if enemy != null:
				enemy.action_requested.connect(on_action.bind(enemy))
