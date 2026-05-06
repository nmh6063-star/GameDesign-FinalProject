extends EnemyActionBase
class_name WebDropAction

const ThrowEffect := preload("res://scenes/visual_effects/throw_effect.tscn")
const SpiderWeb := preload("res://scenes/visual_effects/SpiderWeb.tscn")
const _ICON := preload("res://assets/enemies/attack_icon/spider web icon no back.png")

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
	)
	fx.launch(enemy.global_position, ctx.drop_zone_global())


func action_name() -> String:
	return "Web Drop"


func icon_texture() -> Texture2D:
	return _ICON


func damage_amount(_enemy: EnemyBase) -> int:
	return 0


func special_effect() -> String:
	return "Places a web that traps balls"
