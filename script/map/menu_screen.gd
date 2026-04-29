extends Node2D
class_name MenuScreenController

const ABILITY_COLLECTION_SCENE := preload("res://scenes/ability_collection.tscn")


func _ready() -> void:
	$MenuScreen/StartGame.pressed.connect(_on_start_game_pressed)
	$MenuScreen/Tutorial.pressed.connect(_on_tutorial_pressed)
	var ability_btn := get_node_or_null("MenuScreen/AbilityCollection") as Button
	if ability_btn != null:
		ability_btn.pressed.connect(_on_ability_collection_pressed)


func _on_start_game_pressed() -> void:
	GameManager.generate_new_run()
	GameManager.open_map_selection()


func _on_tutorial_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/tutorial.tscn")


func _on_ability_collection_pressed() -> void:
	var inst := ABILITY_COLLECTION_SCENE.instantiate() as Node
	get_tree().current_scene.add_child(inst)
