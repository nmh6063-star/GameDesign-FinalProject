extends Panel
class_name MapGraph

const MapTypes := preload("res://script/map/map_types.gd")

const TITLE_HEIGHT := 40.0
const FOOTER_HEIGHT := 28.0

@export var graph_margin := 24.0
@export var node_radius := 13.0
@export var edge_width := 2.0
@export var selected_edge_width := 4.0

var _controller = null

@onready var _title := $Title as Label
@onready var _legend := $Legend as Label


func _ready() -> void:
	queue_redraw()


func set_controller(controller) -> void:
	var callback := Callable(self, "_on_controller_state_changed")
	if _controller != null and _controller.state_changed.is_connected(callback):
		_controller.state_changed.disconnect(callback)
	_controller = controller
	if _controller != null:
		_controller.state_changed.connect(callback)
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func _on_controller_state_changed() -> void:
	queue_redraw()


func _draw() -> void:
	var run = null if _controller == null else _controller.run_data()
	if run == null:
		_draw_empty_state()
		return
	var graph_rect := _graph_rect()
	if graph_rect.size.x <= 0.0 or graph_rect.size.y <= 0.0:
		return
	var positions := _build_positions(run, graph_rect)
	_draw_edges(run, positions)
	_draw_nodes(run, positions)


func _draw_empty_state() -> void:
	var font: Font = _label_font()
	if font == null:
		return
	draw_string(
		font,
		Vector2(20.0, TITLE_HEIGHT + 36.0),
		"No map",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1.0,
		12,
		Color(0.22, 0.15, 0.12, 0.85)
	)


func _graph_rect() -> Rect2:
	return Rect2(
		Vector2(graph_margin, TITLE_HEIGHT + 4.0),
		Vector2(
			max(0.0, size.x - graph_margin * 2.0),
			max(0.0, size.y - TITLE_HEIGHT - FOOTER_HEIGHT - graph_margin)
		)
	)


func _build_positions(run, graph_rect: Rect2) -> Dictionary:
	var positions := {}
	var total_layers: int = max(1, int(run.layers.size()))
	var inner_margin: float = node_radius * 1.8
	var usable_width: float = max(0.0, graph_rect.size.x - inner_margin * 2.0)
	for layer_index in range(total_layers):
		var rooms: Array = run.nodes_in_layer(layer_index)
		var y_ratio: float = 0.0 if total_layers == 1 else float(layer_index) / float(total_layers - 1)
		var y: float = graph_rect.position.y + graph_rect.size.y - (graph_rect.size.y * y_ratio)
		var room_count: int = rooms.size()
		for room_index in range(room_count):
			var room = rooms[room_index]
			var x: float = graph_rect.position.x + graph_rect.size.x * 0.5
			if room_count > 1:
				var x_ratio: float = float(room_index) / float(room_count - 1)
				x = graph_rect.position.x + inner_margin + usable_width * x_ratio
			positions[room.id] = Vector2(x, y)
	return positions


func _draw_edges(run, positions: Dictionary) -> void:
	var current = _controller.current_room()
	var current_id: int = -1 if current == null else int(current.id)
	var selected_id: int = _controller.selected_path_target_id()
	var visited := {}
	for room_id in _controller.visited_room_ids():
		visited[room_id] = true
	for room in run.all_nodes():
		var from: Vector2 = positions.get(room.id, Vector2.ZERO)
		for target_id in room.outgoing:
			var to: Vector2 = positions.get(target_id, Vector2.ZERO)
			var color: Color = Color(1.0, 1.0, 1.0, 0.25)
			var width: float = edge_width
			if visited.has(room.id) and visited.has(target_id):
				color = Color(1.0, 0.96, 0.86, 0.55)
			elif room.id == current_id:
				color = Color(0.96, 0.96, 0.96, 0.48)
			if room.id == current_id and target_id == selected_id:
				color = Color(0.96, 0.18, 0.22, 0.95)
				width = selected_edge_width
			draw_line(from, to, color, width, true)


func _draw_nodes(run, positions: Dictionary) -> void:
	var font: Font = _label_font()
	var current = _controller.current_room()
	var current_id: int = -1 if current == null else int(current.id)
	var selected_id: int = _controller.selected_path_target_id()
	var visited := {}
	for room_id in _controller.visited_room_ids():
		visited[room_id] = true
	for room in run.all_nodes():
		var center: Vector2 = positions.get(room.id, Vector2.ZERO)
		var base_color := MapTypes.color(room.room_type)
		var fill := base_color.darkened(0.2)
		if not visited.has(room.id):
			fill = fill.darkened(0.45)
			fill.a = 0.78
		if room.id == current_id:
			fill = Color(1.0, 0.18, 0.22, 1.0)
		draw_circle(center, node_radius, fill)
		var outline := Color(0.1, 0.08, 0.14, 0.9)
		var outline_width := 2.0
		if room.id == selected_id:
			outline = Color(1.0, 0.98, 0.9, 0.95)
			outline_width = 3.0
		elif visited.has(room.id):
			outline = Color(1.0, 0.95, 0.86, 0.6)
		draw_arc(center, node_radius, 0.0, TAU, 32, outline, outline_width, true)
		if font != null:
			var text_color := Color(0.08, 0.05, 0.07, 1.0)
			draw_string(
				font,
				center + Vector2(-node_radius, 5.0),
				MapTypes.mark(room.room_type),
				HORIZONTAL_ALIGNMENT_CENTER,
				node_radius * 2.0,
				10,
				text_color
			)


func _label_font():
	if _title != null:
		return _title.get_theme_font("font")
	return ThemeDB.fallback_font
