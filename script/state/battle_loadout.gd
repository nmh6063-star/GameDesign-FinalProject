extends Node

const BallCatalog := preload("res://script/entities/balls/ball_catalog.gd")
const DEFAULT_BALL_POOL: Array[String] = [BallCatalog.NORMAL_BALL_ID]

var ball_pool: Array[String] = DEFAULT_BALL_POOL.duplicate()


func add_ball_to_pool(ball_id: String) -> void:
	if not ball_pool.has(ball_id):
		ball_pool.append(ball_id)


func ball_pool_ids() -> Array[String]:
	return ball_pool.duplicate()


func reset_for_run() -> void:
	ball_pool = DEFAULT_BALL_POOL.duplicate()
