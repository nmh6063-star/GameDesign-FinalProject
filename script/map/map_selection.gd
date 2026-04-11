extends Control
class_name MapSelection

const MapController := preload("res://script/map/map_controller.gd")
const MapGenerator := preload("res://script/map/map_generator.gd")
const MapTypes := preload("res://script/map/map_types.gd")

signal room_confirmed(room_type, room_id)
signal minimap_toggled(is_visible)

@export var run_seed := -1
@export var total_layers := 8
@export var middle_boss_layer := 4

var _controller = null

@onready var _game_manager := get_node_or_null("/root/GameManager")
@onready var _current_room_label := $CurrentRoomLabel as Label
@onready var _status_label := $StatusLabel as Label
@onready var _seed_label := $SeedLabel as Label
@onready var _instructions_label := $InstructionsLabel as Label
@onready var _map_graph := $MapGraph
@onready var _doors := [
	$DoorCenter/Doors/LeftDoor,
	$DoorCenter/Doors/CenterDoor,
	$DoorCenter/Doors/RightDoor,
]
@onready var _door_marks := [
	$DoorCenter/Doors/LeftDoor/TypeMark,
	$DoorCenter/Doors/CenterDoor/TypeMark,
	$DoorCenter/Doors/RightDoor/TypeMark,
]
@onready var _door_names := [
	$DoorCenter/Doors/LeftDoor/TypeName,
	$DoorCenter/Doors/CenterDoor/TypeName,
	$DoorCenter/Doors/RightDoor/TypeName,
]
@onready var _door_layers := [
	$DoorCenter/Doors/LeftDoor/LayerLabel,
	$DoorCenter/Doors/CenterDoor/LayerLabel,
	$DoorCenter/Doors/RightDoor/LayerLabel,
]
@onready var _door_selection_frames := [
	$DoorCenter/Doors/LeftDoor/SelectionFrame,
	$DoorCenter/Doors/CenterDoor/SelectionFrame,
	$DoorCenter/Doors/RightDoor/SelectionFrame,
]


func _ready() -> void:
	set_process_unhandled_input(true)
	if _game_manager != null:
		if not _game_manager.has_run():
			_game_manager.start_new_run(run_seed)
		_controller = _game_manager.controller()
	elif _controller == null:
		_controller = MapController.new()
	_bind_controller()
	_map_graph.set_controller(_controller)
	if _controller != null and _controller.run_data() == null:
		var config := MapGenerator.GenerationConfig.new()
		config.total_layers = max(total_layers, 8)
		config.middle_boss_layer = middle_boss_layer
		_controller.start_new_run(run_seed, config)
	if _controller != null:
		_refresh_view()


func set_controller(controller) -> void:
	_unbind_controller()
	_controller = controller
	if is_node_ready():
		_bind_controller()
		_map_graph.set_controller(_controller)
		_refresh_view()


func controller():
	return _controller


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if _controller == null or not (event is InputEventKey):
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	if key_event.is_action_pressed("left") or key_event.is_action_pressed("Move_Left") or key_event.keycode == KEY_LEFT or key_event.keycode == KEY_A:
		_controller.move_selection(-1)
		accept_event()
		return
	if key_event.is_action_pressed("right") or key_event.is_action_pressed("Move_Right") or key_event.keycode == KEY_RIGHT or key_event.keycode == KEY_D:
		_controller.move_selection(1)
		accept_event()
		return
	if key_event.is_action_pressed("ui_accept") or key_event.is_action_pressed("Interact") or key_event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
		_confirm_selection()
		accept_event()
		return
	if key_event.keycode == KEY_M:
		_toggle_minimap()
		accept_event()


func _draw() -> void:
	if not is_node_ready() or _controller == null:
		return
	var origin := Vector2(size.x * 0.5, size.y - 10.0)
	for index in range(_doors.size()):
		var door := _doors[index] as Control
		if not door.visible:
			continue
		var rect := door.get_global_rect()
		var local_top := rect.position - global_position + Vector2(rect.size.x * 0.5, rect.size.y * 0.78)
		var color := Color(0.93, 0.93, 0.98, 0.15)
		var width := 10.0
		if index == _controller.selected_choice_index():
			color = Color(1.0, 0.40, 0.44, 0.94)
			width = 14.0
		draw_line(origin, local_top, color, width, true)


func _bind_controller() -> void:
	if _controller == null:
		return
	var callback := Callable(self, "_on_controller_state_changed")
	if not _controller.state_changed.is_connected(callback):
		_controller.state_changed.connect(callback)


func _unbind_controller() -> void:
	if _controller == null:
		return
	var callback := Callable(self, "_on_controller_state_changed")
	if _controller.state_changed.is_connected(callback):
		_controller.state_changed.disconnect(callback)


func _on_controller_state_changed() -> void:
	_refresh_view()


func _refresh_view() -> void:
	if _controller == null or _controller.run_data() == null:
		return
	var current = _controller.current_room()
	_seed_label.text = "Seed %d" % _controller.seed()
	_current_room_label.text = "CURRENT ROOM: %s" % MapTypes.label(current.room_type).to_upper()
	if _controller.is_complete():
		_status_label.text = "RUN COMPLETE"
	elif _controller.has_choices():
		_status_label.text = "CHOOSE YOUR PATH"
	else:
		_status_label.text = "NO FURTHER PATH"
	_instructions_label.text = "LEFT / RIGHT SELECT     ENTER CONFIRM     M TOGGLE MAP"
	var choices: Array = _controller.available_choices()
	for index in range(_doors.size()):
		var door := _doors[index] as Control
		var selected_frame := _door_selection_frames[index] as Control
		if index >= choices.size():
			door.visible = false
			door.scale = Vector2.ONE
			continue
		var room = choices[index]
		door.visible = true
		(_door_marks[index] as Label).text = MapTypes.icon(room.room_type)
		(_door_names[index] as Label).text = MapTypes.label(room.room_type).to_upper()
		(_door_layers[index] as Label).text = "LAYER %d" % room.layer_index
		var is_selected: bool = index == _controller.selected_choice_index()
		selected_frame.visible = is_selected
		door.modulate = Color(1.0, 1.0, 1.0, 1.0) if is_selected else Color(0.9, 0.88, 0.97, 0.94)
		door.scale = Vector2.ONE * (1.06 if is_selected else 1.0)
	queue_redraw()


func _confirm_selection() -> void:
	if _game_manager != null:
		var room = _game_manager.enter_selected_room()
		if room == null:
			return
		room_confirmed.emit(room.room_type, room.id)
		return
	if _controller == null:
		return
	var room = _controller.confirm_selection()
	if room == null:
		return
	room_confirmed.emit(room.room_type, room.id)


func _toggle_minimap() -> void:
	_map_graph.visible = not _map_graph.visible
	minimap_toggled.emit(_map_graph.visible)
