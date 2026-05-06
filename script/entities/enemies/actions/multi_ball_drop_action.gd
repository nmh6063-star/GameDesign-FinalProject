extends EnemyActionBase
class_name MultiBallDropAction

const DROPS := 3
const BALL_ID := "ball_normal"


func execute(ctx: BattleContext, _enemy: EnemyBase) -> void:
	for i in range(DROPS):
		ctx.drop_ball_in_box(BALL_ID, 1)
