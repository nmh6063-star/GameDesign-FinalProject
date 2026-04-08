extends CanvasLayer
class_name RewardSelectionOverlay

const GameBall := preload("res://script/ball/game_ball.gd")
const BALL_SCENE_DIR := "res://scenes/balls"
const NORMAL_BALL_SCENE_PATH := "res://scenes/balls/ball_normal.tscn"
const OPTION_COUNT := 5
const PICK_COUNT := 2

signal continued(scene_paths: Array[String])

var _entries: Array = []
var _selected_paths: Array[String] = []

@onready var _slot_buttons: Array[Button] = [
	$Overlay/Card/Slots/Slot0,
	$Overlay/Card/Slots/Slot1,
	$Overlay/Card/Slots/Slot2,
	$Overlay/Card/Slots/Slot3,
	$Overlay/Card/Slots/Slot4,
]
@onready var _preview_roots: Array[Node2D] = [
	$Overlay/Card/Slots/Slot0/PreviewRoot,
	$Overlay/Card/Slots/Slot1/PreviewRoot,
	$Overlay/Card/Slots/Slot2/PreviewRoot,
	$Overlay/Card/Slots/Slot3/PreviewRoot,
	$Overlay/Card/Slots/Slot4/PreviewRoot,
]
@onready var _name_labels: Array[Label] = [
	$Overlay/Card/Slots/Slot0/Name,
	$Overlay/Card/Slots/Slot1/Name,
	$Overlay/Card/Slots/Slot2/Name,
	$Overlay/Card/Slots/Slot3/Name,
	$Overlay/Card/Slots/Slot4/Name,
]
@onready var _description_popup := $Overlay/Card/DescriptionPopup as Control
@onready var _description_label := $Overlay/Card/DescriptionPopup/Description as Label
@onready var _continue_button := $Overlay/Card/Continue as Button


func _ready() -> void:
	_entries = _pick_entries()
	for i in range(_slot_buttons.size()):
		_slot_buttons[i].pressed.connect(_on_slot_pressed.bind(i))
		_slot_buttons[i].mouse_entered.connect(_on_slot_hovered.bind(i))
		_slot_buttons[i].mouse_exited.connect(_on_slot_unhovered)
	_render_slots()
	_continue_button.pressed.connect(_on_continue_pressed)
	_continue_button.disabled = true


func _pick_entries() -> Array:
	var paths: Array[String] = []
	for file_name in DirAccess.get_files_at(BALL_SCENE_DIR):
		if not file_name.ends_with(".tscn"):
			continue
		var scene_path := "%s/%s" % [BALL_SCENE_DIR, file_name]
		if scene_path != NORMAL_BALL_SCENE_PATH:
			paths.append(scene_path)
	paths.shuffle()
	var entries: Array = []
	for scene_path in paths:
		var scene := load(scene_path) as PackedScene
		if scene == null:
			continue
		var ball := scene.instantiate() as GameBall
		if ball == null or ball.data == null:
			if ball != null:
				ball.free()
			continue
		entries.append({"path": scene_path, "scene": scene, "data": ball.data})
		ball.free()
		if entries.size() == OPTION_COUNT:
			break
	return entries


func _render_slots() -> void:
	for i in range(_slot_buttons.size()):
		var button: Button = _slot_buttons[i]
		if i >= _entries.size():
			button.visible = false
			continue
		button.visible = true
		button.disabled = false
		button.modulate = Color.WHITE
		var entry: Dictionary = _entries[i]
		var data: BallData = entry["data"]
		_name_labels[i].text = data.display_name
		for child in _preview_roots[i].get_children():
			child.queue_free()
		var ball: GameBall = (entry["scene"] as PackedScene).instantiate() as GameBall
		ball.ui_preview = true
		ball.set_preview(data, 1)
		_ignore_control_mouse(ball)
		_preview_roots[i].add_child(ball)
		ball.position = Vector2.ZERO
		ball.scale = Vector2.ONE * 0.9


func _on_slot_hovered(index: int) -> void:
	if index >= _entries.size():
		return
	var entry: Dictionary = _entries[index]
	var data: BallData = entry["data"]
	_description_label.text = data.description if data.description != "" else data.display_name
	_description_popup.visible = true


func _on_slot_unhovered() -> void:
	_description_popup.visible = false


func _on_slot_pressed(index: int) -> void:
	if _selected_paths.size() >= PICK_COUNT or index >= _entries.size():
		return
	var entry: Dictionary = _entries[index]
	var scene_path: String = entry["path"]
	_selected_paths.append(scene_path)
	_slot_buttons[index].disabled = true
	_slot_buttons[index].modulate = Color(1, 1, 1, 0)
	_description_popup.visible = false
	_continue_button.disabled = _selected_paths.size() < PICK_COUNT


func _on_continue_pressed() -> void:
	if _selected_paths.size() < PICK_COUNT:
		return
	var scene_paths: Array[String] = _selected_paths.duplicate()
	continued.emit(scene_paths)
	queue_free()


func _ignore_control_mouse(node: Node) -> void:
	if node is Control:
		(node as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		_ignore_control_mouse(child)
