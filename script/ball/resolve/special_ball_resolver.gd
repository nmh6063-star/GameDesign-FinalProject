extends RefCounted

const GameBall := preload("res://script/ball/game_ball.gd")
const BallBehavior := preload("res://script/ball/behaviors/ball_behavior.gd")
var tolerance := 4.0

func _wake_playfield(root: Node2D) -> void:
	for n in root.get_tree().get_nodes_in_group("ball"):
		if not is_instance_valid(n):
			continue
		if n is RigidBody2D:
			var rb := n as RigidBody2D
			rb.sleeping = false


func resolve(root: Node2D, template: GameBall, wire: Callable) -> int:
	var heal_total := 0
	while true:
		var h := _wave_heal(root, template)
		if h == 0:
			break
		heal_total += h
	while _wave_mult(root, template):
		pass
	while _wave_dup(root, template, wire):
		pass
	if heal_total > 0:
		Global.player_health = mini(Global.player_health + heal_total, Global.player_max_health)
	return heal_total


func _balls(root: Node2D, template: GameBall) -> Array[GameBall]:
	var out: Array[GameBall] = []
	for n in root.get_tree().get_nodes_in_group("ball"):
		if not is_instance_valid(n) or not n is GameBall:
			continue
		var gb := n as GameBall
		if gb == template or gb.set_up or not gb.visible:
			continue
		out.append(gb)
	return out


func _touching(seed: GameBall, pool: Array[GameBall]) -> Array[GameBall]:
	var out: Array[GameBall] = []
	for o in pool:
		if o == seed:
			continue
		if seed.global_position.distance_to(o.global_position) <= seed.get_radius() + o.get_radius() + tolerance:
			out.append(o)
	return out


func _wave_heal(root: Node2D, template: GameBall) -> int:
	var balls := _balls(root, template)
	for b in balls:
		if b.behavior.kind != BallBehavior.Kind.HEAL:
			continue
		var comp := _touching(b, balls)
		var sum := 0
		for o in comp:
			if o.behavior.participates_in_level_merge():
				sum += o.level
		# Heal deletes only numbered (NORMAL) balls, not other specials.
		for o in comp:
			if o.behavior.participates_in_level_merge():
				_consume(o)
		_consume(b)
		_wake_playfield(root)
		return sum * 2
	return 0


func _wave_mult(root: Node2D, template: GameBall) -> bool:
	var balls := _balls(root, template)
	for b in balls:
		if b.behavior.kind != BallBehavior.Kind.MULTIPLICATION:
			continue
		for o in _touching(b, balls):
			if o.behavior.participates_in_level_merge():
				o.level *= 2
				o._update_collision()
				o.queue_redraw()
		_consume(b)
		_wake_playfield(root)
		return true
	return false


func _wave_dup(root: Node2D, template: GameBall, wire: Callable) -> bool:
	var balls := _balls(root, template)
	for b in balls:
		if b.behavior.kind != BallBehavior.Kind.DUPLICATION:
			continue
		var comp := _touching(b, balls)
		var others: Array[GameBall] = []
		for o in comp:
			if o != b:
				others.append(o)
		# D triggers when it touches at least 2 other balls.
		if others.size() < 2:
			continue
		for o in others:
			var d := o.duplicate() as GameBall
			_prep_playfield(d)
			root.add_child(d)
			d.global_position = o.global_position + Vector2(randf_range(-8.0, 8.0), randf_range(-8.0, 8.0))
			wire.call(d)
		_consume(b)
		_wake_playfield(root)
		return true
	return false


func _consume(b: GameBall) -> void:
	b.visible = false
	b.set_up = false
	b.remove_from_group("ball")
	b.queue_free()


func _prep_playfield(b: GameBall) -> void:
	b.set_up = false
	b.visible = true
	b.gravity_scale = 2.0
	var cs := b.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if cs:
		cs.disabled = false
