extends Node2D
class_name TutorialCompleteController


func _ready() -> void:
	$TutorailCompleted/GoBackToMenu.pressed.connect(_on_go_back_to_menu_pressed)


func _on_go_back_to_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menu_screen.tscn")
