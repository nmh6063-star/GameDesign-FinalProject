extends RefCounted

const GameBall := preload("res://script/ball/game_ball.gd")

var tolerance := 4.0


func step_merge(balls: Array[RigidBody2D]) -> RigidBody2D:
	for i in balls.size():
		var a := balls[i]
		for j in range(i + 1, balls.size()):
			var b := balls[j]
			if not _can_merge(a, b):
				continue
			(a as GameBall).merge_into_me()
			b.queue_free()
			# Prevent "sleeping" bodies from staying stuck after support disappears.
			for x in balls:
				if x != null and is_instance_valid(x) and x is RigidBody2D:
					(x as RigidBody2D).sleeping = false
			return a
	return null


func _can_merge(a: RigidBody2D, b: RigidBody2D) -> bool:
	if not is_instance_valid(a) or not is_instance_valid(b) or not a is GameBall or not b is GameBall:
		return false
	var ga := a as GameBall
	var gb := b as GameBall
	if not ga.behavior.participates_in_level_merge() or not gb.behavior.participates_in_level_merge():
		return false
	var dist := a.global_position.distance_to(b.global_position)
	return ga.level == gb.level and dist <= ga.get_radius() + gb.get_radius() + tolerance
