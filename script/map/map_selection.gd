extends Control
class_name MapSelection

const MapController := preload("res://script/map/map_controller.gd")
const MapGenerator := preload("res://script/map/map_generator.gd")
const MapRoom := preload("res://script/map/map_room.gd")
const ElementCatalog := preload("res://script/entities/balls/elemental_balls/elemental_ball_catalog.gd")
const RewardSelectionController := preload("res://script/battle/controllers/reward_selection_controller.gd")
const REWARD_SELECTION_SCENE := preload("res://scenes/reward_selection.tscn")
var rank_sizing = {
	1: null,
	2: null,
	3: null,
	4: null,
	5: null,
	6: null,
	7: null
}

signal room_confirmed(room_type, room_id, element_data)
signal minimap_toggled(is_visible)
signal augment_toggled(is_visible)

@export var run_seed := -1

@onready var _game_manager := get_node_or_null("/root/GameManager")
@onready var _current_room_label := $CurrentRoomLabel as Label
@onready var _status_label := $StatusLabel as Label
@onready var _seed_label := $SeedLabel as Label
@onready var _instructions_label := $InstructionsLabel as Label
@onready var _map_graph := get_node_or_null("MapGraph")
@onready var _augment_view := get_node_or_null("AugmentView")
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

var stored_data = []
var _pre_map_reward_overlay: RewardSelectionController


func _ready() -> void:
	set_process_unhandled_input(true)
	for i in range(_doors.size()):
		_doors[i].gui_input.connect(_on_door_gui_input.bind(i))
	if _game_manager != null:
		var callback := Callable(self, "_on_map_state_changed")
		if not _game_manager.map_state_changed.is_connected(callback):
			_game_manager.map_state_changed.connect(callback)
		if not _game_manager.has_run():
			_game_manager.generate_new_run(run_seed)
	_refresh_view()
	_maybe_show_pre_map_reward()
	var element_balls = _augment_view.get_node("Panel").get_children()
	var rank = 7
	for child in element_balls:
		rank_sizing[rank] = child
		rank -= 1


func _exit_tree() -> void:
	if _game_manager == null:
		return
	var callback := Callable(self, "_on_map_state_changed")
	if _game_manager.map_state_changed.is_connected(callback):
		_game_manager.map_state_changed.disconnect(callback)


func _unhandled_input(event: InputEvent) -> void:
	if _pre_map_reward_overlay != null and is_instance_valid(_pre_map_reward_overlay):
		return
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
	if key_event.keycode == KEY_Q:
		_toggle_augment()
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
		var hidden: bool = room.mystery and not _game_manager.visited_has(int(room.id))
		door.visible = true
		if hidden:
			icon.visible = false
			mark.visible = true
			mark.text = "?"
			mark.modulate = Color("d4a017")
			name.text = "???"
		else:
			var room_type := int(room.type)
			var texture := MapRoom.texture_for_type(room_type)
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


func _on_door_gui_input(event: InputEvent, door_index: int) -> void:
	if _pre_map_reward_overlay != null and is_instance_valid(_pre_map_reward_overlay):
		return
	if _game_manager == null:
		return
	if not event is InputEventMouseButton:
		return
	var mouse_event := event as InputEventMouseButton
	if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT:
		_game_manager.set_map_choice_index(door_index)
		_confirm_selection()


func _confirm_selection() -> void:
	if _pre_map_reward_overlay != null and is_instance_valid(_pre_map_reward_overlay):
		return
	if _game_manager == null:
		return
	#for child in _augment_view.get_children():
	#	elementData.append(child.get_item_text(child.selected))
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

func _toggle_augment() -> void:
	if _game_manager == null:
		return
	var ref = _augment_view.get_node("Reference/TextureButton")
	var scroll_box = _augment_view.get_node("Panel2/ScrollContainer/HBoxContainer")
	for child in scroll_box.get_children():
		child.queue_free()
	for element in ElementCatalog.elemental_database:
		if element.rank == 0:
			continue
		var clone = ref.duplicate()
		clone.mouse_entered.connect(_set_element_text.bind(element["name"], element["description"], element["type"]))
		clone.pressed.connect(_set_element_data.bind(element))
		scroll_box.add_child(clone)
		clone.ignore_texture_size = true
		clone.modulate = ElementCatalog.get_color(element["type"])
		clone.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		clone.custom_minimum_size = rank_sizing[element["rank"]].size
	var is_visible: bool = bool(_game_manager.toggle_augment_view())
	if _augment_view != null:
		_augment_view.visible = is_visible
	augment_toggled.emit(is_visible)

func _set_element_text(text1, text2, text3):
	var textBox1 = _augment_view.get_node("Panel3/Title")
	var textBox2 = _augment_view.get_node("Panel3/Desc")
	textBox1.text = "[u]" + text1 + " : " + text3 + "[/u]"
	textBox2.text = text2

func _set_element_data(element):
	PlayerState.elements[element["rank"]] = element
	_refresh_augment()

func _refresh_augment():
	PlayerState.elements[0] = []
	var types = []
	var base = []
	for child in rank_sizing:
		if PlayerState.elements[child]:
			if !types.has(PlayerState.elements[child]["type"]):
				types.append(PlayerState.elements[child]["type"])
				base.append(ElementCatalog.get_passive(PlayerState.elements[child]["type"]))
			rank_sizing[child].modulate = ElementCatalog.get_color(PlayerState.elements[child]["type"])
			rank_sizing[child].mouse_entered.connect(_set_element_text.bind(PlayerState.elements[child]["name"], PlayerState.elements[child]["description"], PlayerState.elements[child]["type"]))
	PlayerState.elements[0] = base
	print(base)
	
		


func _controller() -> MapController:
	return null if _game_manager == null else _game_manager.controller()


func _maybe_show_pre_map_reward() -> void:
	if _game_manager == null:
		return
	if not _game_manager.has_method("consume_pre_map_reward_pending"):
		return
	if not bool(_game_manager.call("consume_pre_map_reward_pending")):
		return
	_pre_map_reward_overlay = REWARD_SELECTION_SCENE.instantiate() as RewardSelectionController
	if _pre_map_reward_overlay == null:
		return
	_pre_map_reward_overlay.selection_completed.connect(_on_pre_map_reward_done)
	add_child(_pre_map_reward_overlay)


func _on_pre_map_reward_done() -> void:
	_pre_map_reward_overlay = null
	_refresh_view()
