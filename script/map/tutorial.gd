extends Node2D
class_name TutorialController


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_0:
			get_tree().change_scene_to_file("res://scenes/tutorial_complete.tscn")
