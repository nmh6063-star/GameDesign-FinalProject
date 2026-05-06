extends Node2D

const HALF_W := 356.0
const HALF_H := 64.0
const LIFETIME := 10.0
const MAX_SPEED := 120.0
const DRAG_PER_FRAME := 0.05

var _elapsed: float = 0.0


func _physics_process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= LIFETIME:
		queue_free()
		return
	modulate.a = 1.0 - (_elapsed / LIFETIME)
	for node in get_tree().get_nodes_in_group("ball"):
		var rb := node as RigidBody2D
		if rb == null:
			continue
		var local_pos := to_local(rb.global_position)
		if abs(local_pos.x) <= HALF_W and abs(local_pos.y) <= HALF_H:
			var vel := rb.linear_velocity
			vel *= DRAG_PER_FRAME
			if vel.length() > MAX_SPEED:
				vel = vel.normalized() * MAX_SPEED
			rb.linear_velocity = vel
