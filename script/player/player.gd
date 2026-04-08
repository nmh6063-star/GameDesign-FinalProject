extends Node2D

@onready var base = $Sprite2D.modulate


func flash() -> void:
	$Sprite2D.modulate = Color(18.892, 0.0, 0.0)
	$Timer.start()


func _on_timer_timeout() -> void:
	$Sprite2D.modulate = base
