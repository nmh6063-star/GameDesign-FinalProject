extends RefCounted

var tolerance := 4.0

func step_merge(balls: Array[RigidBody2D]) -> RigidBody2D:
	for i in balls.size():
		var a := balls[i]
		for j in range(i + 1, balls.size()):
			var b := balls[j]
			if a.level != b.level:
				continue
			if a.global_position.distance_to(b.global_position) <= a.get_radius() + b.get_radius() + tolerance:
				a.merge_into_me()
				b.queue_free()
				return a
	return null

