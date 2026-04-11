extends Node

const MapController := preload("res://script/map/map_controller.gd")
const MapGenerator := preload("res://script/map/map_generator.gd")
const MapTypes := preload("res://script/map/map_types.gd")

const MAP_SELECTION_SCENE_PATH := "res://scenes/map/map_selection.tscn"
const BATTLE_SCENE_PATH := "res://scenes/main.tscn"

signal run_started(run_data)
signal room_started(room_data)
signal room_completed(room_data)
signal run_reset

var _controller: MapController
var _active_room_id := -1
var _seed := -1


func _ready() -> void:
	if _controller == null:
		start_new_run()


func controller() -> MapController:
	return _controller


func has_run() -> bool:
	return _controller != null and _controller.run_data() != null


func current_seed() -> int:
	return _seed


func active_room():
	if _controller == null:
		return null
	if _active_room_id >= 0:
		return _controller.room_by_id(_active_room_id)
	return _controller.current_room()


func active_room_type() -> int:
	var room = active_room()
	return MapTypes.RoomType.START if room == null else int(room.room_type)


func start_new_run(seed: int = -1) -> void:
	_seed = seed
	BattleLoadout.reset_for_run()
	PlayerState.reset_for_run()
	_controller = MapController.new()
	var config := MapGenerator.GenerationConfig.new()
	_controller.start_new_run(seed, config)
	var room = _controller.current_room()
	_active_room_id = -1 if room == null else int(room.id)
	run_started.emit(_controller.run_data())
	_bind_map_scene_if_needed()


func open_map_selection() -> void:
	_change_scene(MAP_SELECTION_SCENE_PATH)


func enter_selected_room():
	if _controller == null:
		return null
	var room = _controller.confirm_selection()
	if room == null:
		return null
	_active_room_id = room.id
	room_started.emit(room)
	_change_scene(_scene_for_room(room))
	return room


func complete_current_room() -> void:
	var room = active_room()
	if room != null:
		room_completed.emit(room)
	open_map_selection()


func restart_run(seed: int = -1) -> void:
	start_new_run(seed if seed >= 0 else _seed)
	run_reset.emit()
	open_map_selection()


func should_skip_battle_rewards() -> bool:
	return true


func _scene_for_room(_room) -> String:
	return BATTLE_SCENE_PATH


func _change_scene(scene_path: String) -> void:
	var tree := get_tree()
	var current := tree.current_scene
	if current != null and current.scene_file_path == scene_path:
		_bind_map_scene_if_needed()
		return
	tree.change_scene_to_file(scene_path)


func _bind_map_scene_if_needed() -> void:
	var tree := get_tree()
	var current := tree.current_scene
	if current == null:
		return
	if current.scene_file_path != MAP_SELECTION_SCENE_PATH:
		return
	if current.has_method("set_controller"):
		current.call("set_controller", _controller)
