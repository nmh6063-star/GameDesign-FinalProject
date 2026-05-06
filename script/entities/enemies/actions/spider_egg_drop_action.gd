extends EnemyActionBase
class_name SpiderEggDropAction

## "ball_spider_egg" is not in BallCatalog; fall back to a normal ball.
const EGG_BALL_ID := "ball_normal"
const EGG_RANK := 1
const ThrowEffect := preload("res://scenes/visual_effects/throw_effect.tscn")
const _ICON := preload("res://assets/enemies/attack_icon/spider web icon no back.png")


func execute(ctx: BattleContext, enemy: EnemyBase) -> void:
	var data := BallCatalog.data_for_id(EGG_BALL_ID)
	var fx := ThrowEffect.instantiate()
	fx.setup(data, EGG_RANK)
	enemy.add_sibling(fx)
	fx.landed.connect(func() -> void:
		ctx.drop_ball_in_box(EGG_BALL_ID, EGG_RANK)
	)
	fx.launch(enemy.global_position, ctx.drop_zone_global())


func action_name() -> String:
	return "Egg Drop"


func icon_texture() -> Texture2D:
	return _ICON


func damage_amount(_enemy: EnemyBase) -> int:
	return 0


func special_effect() -> String:
	return "Drops a spider egg onto the board"
