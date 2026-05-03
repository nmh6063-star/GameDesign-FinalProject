extends Node2D

const MapController := preload("res://script/map/map_controller.gd")
const _MapRoute := preload("res://script/map/map_route_colors.gd")

var _positions: Dictionary = {}
var _controller: MapController = null
var _edge_width := 2.0
var _hover_target_id := -1

const _COLOR_OPEN := Color(1, 1, 1, 1)


func configure(controller: MapController, positions: Dictionary, edge_w: float, hover_target_id: int = -1) -> void:
	_controller = controller
	_positions = positions.duplicate()
	_edge_width = edge_w
	_hover_target_id = hover_target_id
	queue_redraw()


func _draw() -> void:
	var run = null if _controller == null else _controller.run_data()
	if run == null:
		return
	var cur_id := _controller.current_room_id()
	var hover_from := cur_id
	if _hover_target_id >= 0:
		if hover_from < 0 or not _edge_connects(hover_from, _hover_target_id, run):
			hover_from = _parent_id_toward(run, _hover_target_id)
	# Draw order: open edges first, then visited path, then hover — so the route always reads on top.
	for room_data in run.all_rooms():
		var room := room_data as MapGenerator.Room
		var from: Vector2 = _positions.get(room.id, Vector2.ZERO)
		for next_room_data in room.next_rooms:
			var next_room := next_room_data as MapGenerator.Room
			var to: Vector2 = _positions.get(next_room.id, Vector2.ZERO)
			var from_id := int(room.id)
			var to_id := int(next_room.id)
			var hover_edge := _hover_target_id >= 0 and hover_from >= 0 and from_id == hover_from and to_id == _hover_target_id
			var visited_edge := _controller.visited_has(from_id) and _controller.visited_has(to_id)
			if hover_edge or visited_edge:
				continue
			draw_line(from, to, _COLOR_OPEN, _edge_width, true)
	for room_data in run.all_rooms():
		var room := room_data as MapGenerator.Room
		var from: Vector2 = _positions.get(room.id, Vector2.ZERO)
		for next_room_data in room.next_rooms:
			var next_room := next_room_data as MapGenerator.Room
			var to: Vector2 = _positions.get(next_room.id, Vector2.ZERO)
			var from_id := int(room.id)
			var to_id := int(next_room.id)
			var hover_edge := _hover_target_id >= 0 and hover_from >= 0 and from_id == hover_from and to_id == _hover_target_id
			if hover_edge:
				continue
			if _controller.visited_has(from_id) and _controller.visited_has(to_id):
				var w := maxf(_edge_width * 1.65, 4.0)
				draw_line(from, to, _MapRoute.ROUTE, w, true)
	for room_data in run.all_rooms():
		var room := room_data as MapGenerator.Room
		var from: Vector2 = _positions.get(room.id, Vector2.ZERO)
		for next_room_data in room.next_rooms:
			var next_room := next_room_data as MapGenerator.Room
			var to: Vector2 = _positions.get(next_room.id, Vector2.ZERO)
			var from_id := int(room.id)
			var to_id := int(next_room.id)
			var hover_edge := _hover_target_id >= 0 and hover_from >= 0 and from_id == hover_from and to_id == _hover_target_id
			if hover_edge:
				var w := maxf(_edge_width * 2.1, 5.0)
				draw_line(from, to, _MapRoute.ROUTE, w, true)


func _edge_connects(from_id: int, to_id: int, run) -> bool:
	var r = run.room(from_id)
	if r == null:
		return false
	for nxt in r.next_rooms:
		if int((nxt as MapGenerator.Room).id) == to_id:
			return true
	return false


func _parent_id_toward(run, target_id: int) -> int:
	for room_data in run.all_rooms():
		var room := room_data as MapGenerator.Room
		for next_room_data in room.next_rooms:
			var nr := next_room_data as MapGenerator.Room
			if int(nr.id) == target_id:
				return int(room.id)
	return -1
