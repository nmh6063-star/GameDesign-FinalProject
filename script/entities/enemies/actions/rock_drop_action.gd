extends EnemyActionBase
class_name RockDropAction

const ROCK_BALL_ID := "ball_rock"
const ROCK_RANK := 4
const ThrowEffect := preload("res://scenes/visual_effects/throw_effect.tscn")
const _ICON := preload("res://assets/enemies/attack_icon/normal attack no back.png")


func execute(ctx: BattleContext, enemy: EnemyBase) -> void:
	var data := BallCatalog.data_for_id(ROCK_BALL_ID)
	var fx := ThrowEffect.instantiate()
	fx.setup(data, ROCK_RANK)
	enemy.add_sibling(fx)
	fx.landed.connect(func() -> void:
		ctx.drop_ball_in_box(ROCK_BALL_ID, ROCK_RANK)
	)
	fx.launch(enemy.global_position, ctx.drop_zone_global())


func action_name() -> String:
	return "Rock Drop"


func icon_texture() -> Texture2D:
	return _ICON


func damage_amount(_enemy: EnemyBase) -> int:
	return 0


func special_effect() -> String:
	return "Drops a heavy rock onto the board"
