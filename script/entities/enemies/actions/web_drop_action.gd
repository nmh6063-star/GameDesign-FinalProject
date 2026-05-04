extends EnemyActionBase
class_name WebDropAction

const ThrowEffect := preload("res://scenes/visual_effects/throw_effect.tscn")
const SpiderWeb := preload("res://scenes/visual_effects/SpiderWeb.tscn")

const WEB_CENTER := Vector2(396.0, 404.0)
const WEB_TINT := Color(0.75, 0.82, 0.72)
const WEB_OUTLINE := Color(0.25, 0.55, 0.22)
const WEB_RADIUS := 38.0


func execute(ctx: BattleContext, enemy: EnemyBase) -> void:
	var fx := ThrowEffect.instantiate()
	fx.setup_raw(WEB_RADIUS, WEB_TINT, WEB_OUTLINE)
	enemy.add_sibling(fx)
	fx.landed.connect(func() -> void:
		var web := SpiderWeb.instantiate()
		enemy.add_sibling(web)
		web.global_position = WEB_CENTER
	)
	fx.launch(enemy.global_position, WEB_CENTER)
