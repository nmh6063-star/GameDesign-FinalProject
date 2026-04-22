extends Node2D

var touching = false

var time = 10.0

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is RigidBody2D:
		touching = true


func _on_area_2d_body_exited(body: Node2D) -> void:
	touching = false
