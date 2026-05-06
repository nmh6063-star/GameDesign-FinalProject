extends Panel
class_name MapGraph

const MapController := preload("res://script/map/map_controller.gd")
const MapGenerator := preload("res://script/map/map_generator.gd")
const MapRoom := preload("res://script/map/map_room.gd")
const RewardSelectionController := preload("res://script/battle/controllers/reward_selection_controller.gd")
const REWARD_SCENE := preload("res://scenes/reward_selection.tscn")
const ROOM_SCENE := preload("res://scenes/map/room.tscn")

@export var graph_margin := 26.0
@export var top_padding := 40.0
@export var bottom_padding := 20.0
@export var edge_width := 3.5

@onready var _gm := get_node_or_null("/root/GameManager")
@onready var _graph := $GraphPanel
@onready var _edges := get_node_or_null("GraphPanel/EdgeDrawer")
@onready var _rooms_root := $GraphPanel/Rooms as Node2D
@onready var _current := $CurrentRoomLabel as Label
@onready var _status := $StatusLabel as Label
@onready var _seed := $SeedLabel as Label
@onready var _hint := $InstructionsLabel as Label

var _positions := {}
var _reward_overlay: RewardSelectionController
var _hover_choice_room_id := -1


func _ready() -> void:
	if _gm != null:
		var cb := Callable(self, "_schedule_refresh")
		if not _gm.map_state_changed.is_connected(cb):
			_gm.map_state_changed.connect(cb)
		if not _gm.has_run():
			_gm.generate_new_run(-1)
	_refresh()
	_maybe_reward()


func _exit_tree() -> void:
	if _gm == null:
		return
	var cb := Callable(self, "_schedule_refresh")
	if _gm.map_state_changed.is_connected(cb):
		_gm.map_state_changed.disconnect(cb)


func _schedule_refresh() -> void:
	if not is_inside_tree():
		return
	call_deferred("_refresh")


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_node_ready():
		call_deferred("_refresh")


func _refresh() -> void:
	if _rooms_root == null or _graph == null or _current == null:
		return
	_hover_choice_room_id = -1
	_clear_rooms()
	_positions.clear()
	var controller := _controller()
	if controller == null or controller.run_data() == null:
		_labels_empty()
		_sync_edges(null, {})
		_queue_sync_hp()
		return
	controller.reconcile_visit_data_for_display()
	_update_labels(controller)
	var run := controller.run_data() as MapGenerator.Run
	_positions = _build_positions(run)
	for room_data in run.all_rooms():
		var room := room_data as MapGenerator.Room
		var node := ROOM_SCENE.instantiate() as MapRoom
		node.position = _positions.get(room.id, Vector2.ZERO)
		_rooms_root.add_child(node)
		node.set_room(room)
		var cur_id := controller.current_room_id()
		var is_visited := controller.visited_has(room.id) or room.id == cur_id
		node.set_state(
			room.id in controller.available_choice_ids(),
			room.id == cur_id,
			is_visited
		)
		node.z_index = 1 if is_visited else 0
		node.selected.connect(_on_room_clicked)
		node.hover_choice_changed.connect(_on_hover_choice_changed)
	_sync_edges(controller, _positions)
	_queue_sync_hp()


func _queue_sync_hp() -> void:
	call_deferred("_sync_hp")


func _sync_hp() -> void:
	var bar := get_node_or_null("PlayerHealthBar")
	if bar != null and bar.has_method("sync"):
		bar.sync()


func _sync_edges(controller: MapController, positions: Dictionary) -> void:
	if _edges != null and _edges.has_method("configure"):
		_edges.configure(controller, positions, edge_width, _hover_choice_room_id)


func _on_hover_choice_changed(room: MapGenerator.Room, hovering: bool) -> void:
	_hover_choice_room_id = int(room.id) if hovering else -1
	var c := _controller()
	if c != null:
		_sync_edges(c, _positions)


func _on_room_clicked(room: MapGenerator.Room) -> void:
	if _reward_overlay != null and is_instance_valid(_reward_overlay):
		return
	if _gm == null or not _gm.select_map_room(int(room.id)):
		return
	_gm.enter_selected_room()


func _labels_empty() -> void:
	_current.text = "CURRENT ROOM: NONE"
	_status.text = "NO MAP"
	_seed.text = "Seed -"
	_hint.text = "CLICK AN AVAILABLE ROOM TO TRAVEL"


func _update_labels(controller: MapController) -> void:
	var current = controller.current_room()
	var current_type := MapGenerator.Room.Type.START if current == null else int(current.type)
	_seed.text = "Seed %d" % int(_gm.current_seed())
	_current.text = "CURRENT ROOM: %s" % MapRoom.label_for_type(current_type).to_upper()
	if controller.is_complete():
		_status.text = "RUN COMPLETE"
	elif controller.has_choices():
		_status.text = "CHOOSE YOUR PATH"
	else:
		_status.text = "ROOM RESOLVED"
	_hint.text = "CLICK AN AVAILABLE ROOM TO TRAVEL"


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
		Vector2(
			max(0.0, _graph.size.x - graph_margin * 2.0),
			max(0.0, _graph.size.y - top_padding - bottom_padding)
		)
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
	if _rooms_root == null:
		return
	for child in _rooms_root.get_children():
		_rooms_root.remove_child(child)
		child.queue_free()


func _controller() -> MapController:
	return null if _gm == null else _gm.controller()


func _maybe_reward() -> void:
	if _gm == null or not _gm.has_method("consume_pre_map_reward_pending"):
		return
	if not bool(_gm.call("consume_pre_map_reward_pending")):
		return
	_reward_overlay = REWARD_SCENE.instantiate() as RewardSelectionController
	if _reward_overlay == null:
		return
	_reward_overlay.selection_completed.connect(_on_reward_done)
	add_child(_reward_overlay)


func _on_reward_done() -> void:
	_reward_overlay = null
	_refresh()
