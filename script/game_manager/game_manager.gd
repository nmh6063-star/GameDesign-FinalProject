extends Node

const MapController := preload("res://script/map/map_controller.gd")
const MapGenerator := preload("res://script/map/map_generator.gd")

const MAP_SELECTION_SCENE_PATH := "res://scenes/map/map_selection.tscn"
const BATTLE_SCENE_PATH := "res://scenes/main.tscn"

signal run_started(run_data)
signal room_started(room_data)
signal room_completed(room_data)
signal run_reset
signal map_state_changed

var current_map_data := {}
var map_view_visible := false

var _controller := MapController.new()


func _ready() -> void:
	_bind_controller()
	if not has_run():
		generate_new_run()


func controller() -> MapController:
	return _controller


func has_run() -> bool:
	return _controller.run_data() != null


func current_seed() -> int:
	return _controller.seed()


func active_room():
	return _controller.current_room()


func active_room_type() -> int:
	return _controller.current_room_type() if has_run() else MapGenerator.Room.Type.START


func generate_new_run(seed: int = -1) -> void:
	BattleLoadout.reset_for_run()
	PlayerState.reset_for_run()
	map_view_visible = false
	_controller.start_new_run(seed)


func start_new_run(seed: int = -1) -> void:
	generate_new_run(seed)


func open_map_selection() -> void:
	_change_scene(MAP_SELECTION_SCENE_PATH)


func current_map_node():
	return _controller.current_room()


func node_by_id(node_id: int):
	return _controller.room_by_id(node_id)


func visited_has(node_id: int) -> bool:
	return _controller.visited_has(node_id)


func completed_has(node_id: int) -> bool:
	return _controller.completed_has(node_id)


func get_current_map_choices() -> Array:
	return _controller.available_choices()


func current_map_choice_target_id() -> int:
	return _controller.selected_path_target_id()


func has_map_choices() -> bool:
	return _controller.has_choices()


func is_map_complete() -> bool:
	return _controller.is_complete()


func shift_map_choice(step: int) -> void:
	_controller.move_selection(step)


func set_map_choice_index(index: int) -> void:
	_controller.select_choice_index(index)


func selected_map_choice_index() -> int:
	return _controller.selected_choice_index()


func current_node_id() -> int:
	return _controller.current_room_id()


func visited_map_node_ids() -> Array:
	return _controller.visited_room_ids()


func completed_map_node_ids() -> Array:
	return _controller.completed_room_ids()


func choose_map_node(choice_index: int = -1):
	if choice_index >= 0:
		_controller.select_choice_index(choice_index)
	var room = _controller.confirm_selection()
	if room == null:
		return null
	_change_scene(_scene_for_room(room))
	return room


func enter_selected_room():
	return choose_map_node()


func mark_current_room_complete() -> void:
	_controller.mark_current_room_complete()


func complete_current_room() -> void:
	var room = active_room()
	if room == null:
		return
	_controller.mark_current_room_complete()
	room_completed.emit(_room_payload(room))
	open_map_selection()


func restart_run(seed: int = -1) -> void:
	generate_new_run(seed if seed >= 0 else current_seed())
	run_reset.emit()
	open_map_selection()


func should_skip_battle_rewards() -> bool:
	return true


func toggle_map_view() -> bool:
	map_view_visible = not map_view_visible
	map_state_changed.emit()
	return map_view_visible


func _scene_for_room(_room) -> String:
	return BATTLE_SCENE_PATH


func _change_scene(scene_path: String) -> void:
	var tree := get_tree()
	var current := tree.current_scene
	if current != null and current.scene_file_path == scene_path:
		map_state_changed.emit()
		return
	tree.change_scene_to_file(scene_path)


func _bind_controller() -> void:
	var run_callback := Callable(self, "_on_controller_run_started")
	if not _controller.run_started.is_connected(run_callback):
		_controller.run_started.connect(run_callback)
	var state_callback := Callable(self, "_on_controller_state_changed")
	if not _controller.state_changed.is_connected(state_callback):
		_controller.state_changed.connect(state_callback)
	var room_callback := Callable(self, "_on_controller_room_entered")
	if not _controller.room_entered.is_connected(room_callback):
		_controller.room_entered.connect(room_callback)


func _on_controller_run_started(run_data) -> void:
	current_map_data = run_data.to_dictionary()
	run_started.emit(current_map_data)


func _on_controller_state_changed() -> void:
	_sync_map_snapshot()
	map_state_changed.emit()


func _on_controller_room_entered(room) -> void:
	room_started.emit(_room_payload(room))


func _sync_map_snapshot() -> void:
	if _controller.run_data() == null:
		current_map_data = {}
		return
	current_map_data = _controller.run_data().to_dictionary()


func _room_payload(room) -> Dictionary:
	return room.to_dictionary() if room != null and room.has_method("to_dictionary") else {}
