extends RefCounted

func active_balls(tree: SceneTree, template: RigidBody2D) -> Array[RigidBody2D]:
	var result: Array[RigidBody2D] = []
	for body: RigidBody2D in tree.get_nodes_in_group("ball"):
		if body != template and not body.set_up:
			result.append(body)
	return result

