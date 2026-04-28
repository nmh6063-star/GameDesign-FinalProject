extends RefCounted
class_name MapController

const MapGenerator := preload("res://script/map/map_generator.gd")

signal run_started(run_data)
signal state_changed
signal room_entered(room_data)
signal run_completed(room_data)

var _generator := MapGenerator.new()
var _run: MapGenerator.Run
var _current_room_id := -1
var _visited_room_ids: Array = []
var _completed_room_ids: Array = []
var _available_choice_ids: Array = []
var _selected_choice_index := 0


func start_new_run(seed: int = -1) -> void:
	_run = _generator.generate(seed)
	_current_room_id = -1
	_visited_room_ids = []
	_completed_room_ids = []
	_available_choice_ids = _initial_choice_ids()
	_selected_choice_index = 0
	run_started.emit(_run)
	state_changed.emit()


func run_data() -> MapGenerator.Run:
	return _run


func seed() -> int:
	return 0 if _run == null else int(_run.seed)


func current_room() -> MapGenerator.Room:
	return null if _run == null or _current_room_id < 0 else _run.room(_current_room_id)


func current_room_id() -> int:
	return _current_room_id


func current_room_type() -> int:
	var room := current_room()
	return MapGenerator.Room.Type.START if room == null else int(room.type)


func current_layer_index() -> int:
	var room := current_room()
	return -1 if room == null else int(room.row)


func visited_room_ids() -> Array:
	return _visited_room_ids.duplicate()


func visited_has(room_id: int) -> bool:
	return room_id in _visited_room_ids


func completed_room_ids() -> Array:
	return _completed_room_ids.duplicate()


func completed_has(room_id: int) -> bool:
	return room_id in _completed_room_ids


func available_choices() -> Array:
	var rooms: Array = []
	if _run == null:
		return rooms
	for room_id in _available_choice_ids:
		var room := _run.room(int(room_id))
		if room != null:
			rooms.append(room)
	return rooms


func available_choice_ids() -> Array:
	return _available_choice_ids.duplicate()


func selected_choice_index() -> int:
	return _selected_choice_index


func selected_choice() -> MapGenerator.Room:
	if _run == null or _available_choice_ids.is_empty():
		return null
	return _run.room(int(_available_choice_ids[_selected_choice_index]))


func selected_path_target_id() -> int:
	var room := selected_choice()
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


func confirm_selection() -> MapGenerator.Room:
	print("WHAT THE HELL")
	var room := selected_choice()
	if room == null:
		return null
	_current_room_id = room.id
	room.selected = true
	if room.id not in _visited_room_ids:
		_visited_room_ids.append(room.id)
	_refresh_choices()
	room_entered.emit(room)
	if is_complete():
		run_completed.emit(room)
	state_changed.emit()
	return room


func mark_current_room_complete() -> void:
	if _current_room_id < 0 or _current_room_id in _completed_room_ids:
		return
	_completed_room_ids.append(_current_room_id)
	state_changed.emit()


func is_complete() -> bool:
	var room := current_room()
	return room != null and room.type == MapGenerator.Room.Type.BOSS and _available_choice_ids.is_empty()


func has_choices() -> bool:
	return not _available_choice_ids.is_empty()


func room_by_id(room_id: int) -> MapGenerator.Room:
	return null if _run == null else _run.room(room_id)


func edge_is_selected(source_id: int, target_id: int) -> bool:
	return source_id == _current_room_id and target_id == selected_path_target_id()


func _refresh_choices() -> void:
	_available_choice_ids.clear()
	_selected_choice_index = 0
	if _run == null:
		return
	var room := current_room()
	if room == null:
		_available_choice_ids = _initial_choice_ids()
	else:
		for next_room_data in room.next_rooms:
			_available_choice_ids.append((next_room_data as MapGenerator.Room).id)
	_available_choice_ids.sort_custom(func(left, right):
		var left_room := _run.room(int(left))
		var right_room := _run.room(int(right))
		if left_room.row == right_room.row:
			return left_room.column < right_room.column
		return left_room.row < right_room.row
	)


func _initial_choice_ids() -> Array:
	var ids: Array = []
	if _run == null:
		return ids
	for start_id in _run.start_room_ids:
		var start_room := _run.room(int(start_id))
		if start_room == null:
			continue
		for next_room_data in start_room.next_rooms:
			var next_room := next_room_data as MapGenerator.Room
			if next_room != null and next_room.id not in ids:
				ids.append(next_room.id)
	ids.sort_custom(func(left, right):
		var left_room := _run.room(int(left))
		var right_room := _run.room(int(right))
		if left_room == null or right_room == null:
			return int(left) < int(right)
		if left_room.row == right_room.row:
			return left_room.column < right_room.column
		return left_room.row < right_room.row
	)
	return ids
