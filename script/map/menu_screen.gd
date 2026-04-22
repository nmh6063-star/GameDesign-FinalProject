extends Node2D
class_name MenuScreenController


func _ready() -> void:
	$MenuScreen/StartGame.pressed.connect(_on_start_game_pressed)
	$MenuScreen/Tutorial.pressed.connect(_on_tutorial_pressed)


func _on_start_game_pressed() -> void:
	GameManager.generate_new_run()
	GameManager.open_map_selection()


func _on_tutorial_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/tutorial.tscn")
