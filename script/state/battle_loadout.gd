extends Node

const BallCatalog := preload("res://script/entities/balls/ball_catalog.gd")
const DEFAULT_BALL_POOL: Array[String] = [BallCatalog.NORMAL_BALL_ID]

var ball_pool: Array[String] = DEFAULT_BALL_POOL.duplicate()


func add_ball_to_pool(ball_id: String) -> void:
	if not ball_pool.has(ball_id):
		ball_pool.append(ball_id)


func ball_pool_ids() -> Array[String]:
	return ball_pool.duplicate()


func queue_ball_pool_ids() -> Array[String]:
	return DEFAULT_BALL_POOL.duplicate()


func special_ball_ids() -> Array[String]:
	var special_ids: Array[String] = []
	for ball_id in ball_pool:
		if not BallCatalog.is_special(ball_id):
			continue
		special_ids.append(ball_id)
		if special_ids.size() == BallCatalog.MAX_SPECIAL_SLOTS:
			break
	return special_ids


func reset_for_run() -> void:
	ball_pool = DEFAULT_BALL_POOL.duplicate()
	for ball_id in _random_start_special_ids(2):
		add_ball_to_pool(ball_id)


func _random_start_special_ids(count: int) -> Array[String]:
	var special_ids := BallCatalog.ids(false)
	special_ids.shuffle()
	var out: Array[String] = []
	var limit := mini(count, special_ids.size())
	for i in range(limit):
		out.append(special_ids[i])
	return out
