extends EnemyActionBase
class_name SpiderEggDropAction

## "ball_spider_egg" is not in BallCatalog; fall back to a normal ball.
const EGG_BALL_ID := "ball_normal"
const EGG_RANK := 1
const ThrowEffect := preload("res://scenes/visual_effects/throw_effect.tscn")


func execute(ctx: BattleContext, enemy: EnemyBase) -> void:
	var data := BallCatalog.data_for_id(EGG_BALL_ID)
	var fx := ThrowEffect.instantiate()
	fx.setup(data, EGG_RANK)
	enemy.add_sibling(fx)
	fx.landed.connect(func() -> void:
		ctx.drop_ball_in_box(EGG_BALL_ID, EGG_RANK)
	)
	fx.launch(enemy.global_position, ctx.drop_zone_global())
