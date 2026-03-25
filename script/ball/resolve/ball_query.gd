extends RefCounted

const GameBall := preload("res://script/ball/game_ball.gd")


func active_balls(tree: SceneTree, template: RigidBody2D) -> Array[RigidBody2D]:
	var out: Array[RigidBody2D] = []
	for body in tree.get_nodes_in_group("ball"):
		if not is_instance_valid(body) or not body is GameBall:
			continue
		var gb := body as GameBall
		if gb != template and not gb.set_up:
			out.append(body)
	return out
