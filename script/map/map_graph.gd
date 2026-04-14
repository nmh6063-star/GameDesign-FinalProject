extends Panel
class_name MapGraph

const MapController := preload("res://script/map/map_controller.gd")
const MapGenerator := preload("res://script/map/map_generator.gd")
const MapRoom := preload("res://script/map/map_room.gd")
const ROOM_SCENE := preload("res://scenes/map/room.tscn")

@export var graph_margin := 26.0
@export var top_padding := 40.0
@export var bottom_padding := 20.0
@export var edge_width := 2.0
@export var selected_edge_width := 4.0

@onready var _game_manager := get_node_or_null("/root/GameManager")
@onready var _title := $Title as Label
@onready var _rooms_root := $Rooms as Node2D

var _positions := {}


func _ready() -> void:
	if _game_manager != null:
		var callback := Callable(self, "_refresh")
		if not _game_manager.map_state_changed.is_connected(callback):
			_game_manager.map_state_changed.connect(callback)
	_refresh()


func _exit_tree() -> void:
	if _game_manager == null:
		return
	var callback := Callable(self, "_refresh")
	if _game_manager.map_state_changed.is_connected(callback):
		_game_manager.map_state_changed.disconnect(callback)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_refresh()


func _draw() -> void:
	var controller := _controller()
	if controller == null or controller.run_data() == null:
		return
	var run := controller.run_data() as MapGenerator.Run
	for room_data in run.all_rooms():
		var room := room_data as MapGenerator.Room
		var from: Vector2 = _positions.get(room.id, Vector2.ZERO)
		for next_room_data in room.next_rooms:
			var next_room := next_room_data as MapGenerator.Room
			var to: Vector2 = _positions.get(next_room.id, Vector2.ZERO)
			var color := Color(1.0, 1.0, 1.0, 0.24)
			var width := edge_width
			if controller.visited_has(room.id) and controller.visited_has(next_room.id):
				color = Color(1.0, 0.94, 0.82, 0.62)
			if controller.edge_is_selected(room.id, next_room.id):
				color = Color(0.99, 0.30, 0.34, 0.96)
				width = selected_edge_width
			draw_line(from, to, color, width, true)


func _refresh() -> void:
	_clear_rooms()
	_positions.clear()
	var controller := _controller()
	if controller == null or controller.run_data() == null:
		queue_redraw()
		return
	var run := controller.run_data() as MapGenerator.Run
	_positions = _build_positions(run)
	var selected_id := controller.selected_path_target_id()
	for room_data in run.all_rooms():
		var room := room_data as MapGenerator.Room
		var node := ROOM_SCENE.instantiate() as MapRoom
		node.position = _positions.get(room.id, Vector2.ZERO)
		_rooms_root.add_child(node)
		node.set_room(room)
		node.set_state(
			room.id in controller.available_choice_ids(),
			room.id == controller.current_room_id(),
			controller.visited_has(room.id),
			room.id == selected_id
		)
	queue_redraw()


func _build_positions(run: MapGenerator.Run) -> Dictionary:
	var positions := {}
	var rooms := run.all_rooms()
	if rooms.is_empty():
		return positions
	var min_x := INF
	var max_x := -INF
	var min_y := INF
	var max_y := -INF
	for room_data in rooms:
		var room := room_data as MapGenerator.Room
		min_x = min(min_x, room.position.x)
		max_x = max(max_x, room.position.x)
		min_y = min(min_y, room.position.y)
		max_y = max(max_y, room.position.y)
	var rect := Rect2(
		Vector2(graph_margin, top_padding),
		Vector2(max(0.0, size.x - graph_margin * 2.0), max(0.0, size.y - top_padding - bottom_padding))
	)
	var width: float = max(1.0, max_x - min_x)
	var height: float = max(1.0, max_y - min_y)
	for room_data in rooms:
		var room := room_data as MapGenerator.Room
		var x: float = rect.position.x + (room.position.x - min_x) / width * rect.size.x
		var y: float = rect.position.y + (room.position.y - min_y) / height * rect.size.y
		positions[room.id] = Vector2(x, y)
	return positions


func _clear_rooms() -> void:
	for child in _rooms_root.get_children():
		child.free()


func _controller() -> MapController:
	return null if _game_manager == null else _game_manager.controller()
