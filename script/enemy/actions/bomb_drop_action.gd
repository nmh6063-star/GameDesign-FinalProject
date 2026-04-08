extends EnemyAction
class_name BombDropAction

const BOMB_SCENE_PATH := "res://scenes/balls/ball_bomb.tscn"

func execute(ctx: BattleContext, enemy) -> void:
	ctx.damage_player(enemy.data.attack_damage)
	ctx.drop_ball_in_box(BOMB_SCENE_PATH)
