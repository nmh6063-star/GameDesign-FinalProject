extends RefCounted
class_name MapController

const MapGenerator := preload("res://script/map/map_generator.gd")
const MapTypes := preload("res://script/map/map_types.gd")

signal run_started(run_data)
signal state_changed
signal room_entered(room_data)
signal run_completed(room_data)

var _generator := MapGenerator.new()
var _run
var _current_room_id := -1
var _visited_room_ids: Array = []
var _available_choice_ids: Array = []
var _selected_choice_index := 0


func start_new_run(seed: int = -1, config = null) -> void:
	_run = _generator.generate(seed, config)
	_current_room_id = _run.start_node_id
	_visited_room_ids = [_current_room_id]
	_refresh_choices()
	run_started.emit(_run)
	state_changed.emit()


func run_data():
	return _run


func seed() -> int:
	return 0 if _run == null else int(_run.seed)


func current_room():
	return null if _run == null else _run.node(_current_room_id)


func current_room_type() -> int:
	var room = current_room()
	return MapTypes.RoomType.START if room == null else int(room.room_type)


func current_layer_index() -> int:
	var room = current_room()
	return -1 if room == null else int(room.layer_index)


func visited_room_ids() -> Array:
	return _visited_room_ids.duplicate()


func visited_has(room_id: int) -> bool:
	return room_id in _visited_room_ids


func available_choices() -> Array:
	if _run == null:
		return []
	var rooms: Array = []
	for room_id in _available_choice_ids:
		rooms.append(_run.node(room_id))
	return rooms


func available_choice_ids() -> Array:
	return _available_choice_ids.duplicate()


func selected_choice_index() -> int:
	return _selected_choice_index


func selected_choice():
	if _run == null or _available_choice_ids.is_empty():
		return null
	return _run.node(_available_choice_ids[_selected_choice_index])


func selected_path_target_id() -> int:
	var room = selected_choice()
	return -1 if room == null else int(room.id)


func move_selection(step: int) -> void:
	if _available_choice_ids.size() <= 1:
		return
	_selected_choice_index = wrapi(_selected_choice_index + step, 0, _available_choice_ids.size())
	state_changed.emit()


func select_choice_index(index: int) -> void:
	if _available_choice_ids.is_empty():
		return
	var next_index := clampi(index, 0, _available_choice_ids.size() - 1)
	if next_index == _selected_choice_index:
		return
	_selected_choice_index = next_index
	state_changed.emit()


func confirm_selection():
	var room = selected_choice()
	if room == null:
		return null
	_current_room_id = room.id
	if room.id not in _visited_room_ids:
		_visited_room_ids.append(room.id)
	_refresh_choices()
	room_entered.emit(room)
	if is_complete():
		run_completed.emit(room)
	state_changed.emit()
	return room


func is_complete() -> bool:
	var room = current_room()
	return room != null and room.room_type == MapTypes.RoomType.FINAL_BOSS and _available_choice_ids.is_empty()


func has_choices() -> bool:
	return not _available_choice_ids.is_empty()


func room_by_id(room_id: int):
	return null if _run == null else _run.node(room_id)


func edge_is_selected(source_id: int, target_id: int) -> bool:
	return source_id == _current_room_id and target_id == selected_path_target_id()


func _refresh_choices() -> void:
	_available_choice_ids.clear()
	_selected_choice_index = 0
	var room = current_room()
	if room == null:
		return
	_available_choice_ids = room.outgoing.duplicate()
	_available_choice_ids.sort_custom(func(a, b):
		var left = _run.node(int(a))
		var right = _run.node(int(b))
		if left.layer_index == right.layer_index:
			return left.slot_index < right.slot_index
		return left.layer_index < right.layer_index
	)
