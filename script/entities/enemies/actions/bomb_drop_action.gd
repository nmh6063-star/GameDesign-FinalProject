extends EnemyActionBase
class_name BombDropAction

const BOMB_BALL_ID := "ball_bomb"

func execute(ctx: BattleContext, enemy: EnemyBase) -> void:
	#ctx.damage_player(enemy.data.attack_damage)
	ctx.drop_ball_in_box(BOMB_BALL_ID)
