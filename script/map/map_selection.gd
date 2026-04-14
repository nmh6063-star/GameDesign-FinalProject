extends Control
class_name MapSelection

const MapController := preload("res://script/map/map_controller.gd")
const MapGenerator := preload("res://script/map/map_generator.gd")
const MapRoom := preload("res://script/map/map_room.gd")

signal room_confirmed(room_type, room_id)
signal minimap_toggled(is_visible)

@export var run_seed := -1

@onready var _game_manager := get_node_or_null("/root/GameManager")
@onready var _current_room_label := $CurrentRoomLabel as Label
@onready var _status_label := $StatusLabel as Label
@onready var _seed_label := $SeedLabel as Label
@onready var _instructions_label := $InstructionsLabel as Label
@onready var _map_graph := get_node_or_null("MapGraph")
@onready var _doors := [
	$DoorCenter/Doors/LeftDoor,
	$DoorCenter/Doors/CenterDoor,
	$DoorCenter/Doors/RightDoor,
]
@onready var _door_icons := [
	$DoorCenter/Doors/LeftDoor/TypeIcon,
	$DoorCenter/Doors/CenterDoor/TypeIcon,
	$DoorCenter/Doors/RightDoor/TypeIcon,
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
		var callback := Callable(self, "_on_map_state_changed")
		if not _game_manager.map_state_changed.is_connected(callback):
			_game_manager.map_state_changed.connect(callback)
		if not _game_manager.has_run():
			_game_manager.generate_new_run(run_seed)
	_refresh_view()


func _exit_tree() -> void:
	if _game_manager == null:
		return
	var callback := Callable(self, "_on_map_state_changed")
	if _game_manager.map_state_changed.is_connected(callback):
		_game_manager.map_state_changed.disconnect(callback)


func _unhandled_input(event: InputEvent) -> void:
	if _game_manager == null or not (event is InputEventKey):
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	if key_event.is_action_pressed("left") or key_event.is_action_pressed("Move_Left") or key_event.keycode == KEY_LEFT or key_event.keycode == KEY_A:
		_game_manager.shift_map_choice(-1)
		accept_event()
		return
	if key_event.is_action_pressed("right") or key_event.is_action_pressed("Move_Right") or key_event.keycode == KEY_RIGHT or key_event.keycode == KEY_D:
		_game_manager.shift_map_choice(1)
		accept_event()
		return
	if key_event.is_action_pressed("ui_accept") or key_event.is_action_pressed("Interact") or key_event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
		_confirm_selection()
		accept_event()
		return
	if key_event.keycode == KEY_M:
		_toggle_minimap()
		accept_event()


func _on_map_state_changed() -> void:
	_refresh_view()


func _refresh_view() -> void:
	var controller: MapController = _controller()
	if controller == null or controller.run_data() == null:
		_current_room_label.text = "CURRENT ROOM: NONE"
		_status_label.text = "NO MAP"
		_seed_label.text = "Seed -"
		_instructions_label.text = "LEFT / RIGHT SELECT     ENTER CONFIRM     M TOGGLE MAP"
		for door in _doors:
			(door as Control).visible = false
		return
	var current = controller.current_room()
	var current_type := MapGenerator.Room.Type.START if current == null else int(current.type)
	_seed_label.text = "Seed %d" % int(_game_manager.current_seed())
	_current_room_label.text = "CURRENT ROOM: %s" % MapRoom.label_for_type(current_type).to_upper()
	if controller.is_complete():
		_status_label.text = "RUN COMPLETE"
	elif controller.has_choices():
		_status_label.text = "CHOOSE YOUR PATH"
	else:
		_status_label.text = "ROOM RESOLVED"
	_instructions_label.text = "LEFT / RIGHT SELECT     ENTER CONFIRM     M TOGGLE MAP"
	if _map_graph != null:
		_map_graph.visible = bool(_game_manager.map_view_visible)
	var choices: Array = controller.available_choices()
	var selected_index := clampi(controller.selected_choice_index(), 0, max(choices.size() - 1, 0))
	for index in range(_doors.size()):
		var door := _doors[index] as Control
		var frame := _door_selection_frames[index] as Control
		var icon := _door_icons[index] as TextureRect
		var mark := _door_marks[index] as Label
		var name := _door_names[index] as Label
		var layer := _door_layers[index] as Label
		if index >= choices.size():
			door.visible = false
			door.scale = Vector2.ONE
			continue
		var room = choices[index]
		var room_type := int(room.type)
		var texture := MapRoom.texture_for_type(room_type)
		door.visible = true
		icon.texture = texture
		icon.visible = texture != null
		icon.modulate = MapRoom.tint_for_type(room_type) if texture != null else Color.WHITE
		mark.visible = texture == null
		mark.text = MapRoom.short_label_for_type(room_type)
		mark.modulate = MapRoom.tint_for_type(room_type)
		name.text = MapRoom.label_for_type(room_type).to_upper()
		layer.text = "FLOOR %d" % (int(room.row) + 1)
		var is_selected := index == selected_index
		frame.visible = is_selected
		door.modulate = Color(1.0, 1.0, 1.0, 1.0) if is_selected else Color(0.9, 0.88, 0.97, 0.94)
		door.scale = Vector2.ONE * (1.06 if is_selected else 1.0)


func _confirm_selection() -> void:
	if _game_manager == null:
		return
	var room = _game_manager.enter_selected_room()
	if room == null:
		return
	room_confirmed.emit(int(room.type), int(room.id))


func _toggle_minimap() -> void:
	if _game_manager == null:
		return
	var is_visible: bool = bool(_game_manager.toggle_map_view())
	if _map_graph != null:
		_map_graph.visible = is_visible
	minimap_toggled.emit(is_visible)


func _controller() -> MapController:
	return null if _game_manager == null else _game_manager.controller()
