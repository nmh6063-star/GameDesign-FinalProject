extends Node2D
class_name MenuScreenController

const ABILITY_COLLECTION_SCENE := preload("res://scenes/ability_collection.tscn")
const sound := preload("res://script/game_manager/sound_manager.gd")


func _ready() -> void:
	$MenuScreen/StartGame.pressed.connect(_on_start_game_pressed)
	$MenuScreen/Tutorial.pressed.connect(_on_tutorial_pressed)
	var ability_btn := get_node_or_null("MenuScreen/AbilityCollection") as Button
	if ability_btn != null:
		ability_btn.pressed.connect(_on_ability_collection_pressed)
	var playground_btn := get_node_or_null("MenuScreen/Playground") as Button
	if playground_btn != null:
		playground_btn.pressed.connect(_on_playground_pressed)


func _on_start_game_pressed() -> void:
	sound.play_sound_from_string("click")
	GameManager.generate_new_run()
	GameManager.open_map()


func _on_tutorial_pressed() -> void:
	sound.play_sound_from_string("click")
	get_tree().change_scene_to_file("res://scenes/tutorial.tscn")


func _on_ability_collection_pressed() -> void:
	sound.play_sound_from_string("click")
	var inst := ABILITY_COLLECTION_SCENE.instantiate() as Node
	get_tree().current_scene.add_child(inst)


func _on_playground_pressed() -> void:
	sound.play_sound_from_string("click")
	GameManager.generate_new_run()
	GameManager.open_playground()
