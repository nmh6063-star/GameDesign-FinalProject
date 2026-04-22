extends CanvasLayer
class_name RewardSelectionController

const BallCatalog := preload("res://script/entities/balls/ball_catalog.gd")
const BallBase := preload("res://script/entities/balls/ball_base.gd")
const REWARD_OPTION_COUNT := 5
const REWARD_PICK_COUNT := 2

signal selection_completed(ball_ids: Array[String])

var _entries: Array = []
var _selected_ids: Array[String] = []


func _ready() -> void:
	_connect_signals()
	_refresh_rewards()


func _refresh_rewards() -> void:
	_entries = _pick_reward_entries()
	_selected_ids.clear()
	_continue_button().disabled = true
	_description_popup().visible = false
	_render_slots()


func _connect_signals() -> void:
	var buttons := _slot_buttons()
	for i in range(buttons.size()):
		buttons[i].pressed.connect(_on_slot_pressed.bind(i))
		buttons[i].mouse_entered.connect(_on_slot_hovered.bind(i))
		buttons[i].mouse_exited.connect(_on_slot_unhovered)
	_continue_button().pressed.connect(_on_continue_pressed)


func _pick_reward_entries() -> Array:
	var ball_ids: Array[String] = BallCatalog.ids(false)
	ball_ids.shuffle()
	var entries: Array = []
	for ball_id in ball_ids:
		var data := BallCatalog.data_for_id(ball_id)
		var scene := BallCatalog.scene_for_id(ball_id)
		if scene == null or data == null:
			continue
		entries.append({"id": ball_id, "scene": scene, "data": data})
		if entries.size() == REWARD_OPTION_COUNT:
			break
	return entries


func _render_slots() -> void:
	var buttons := _slot_buttons()
	var preview_roots := _preview_roots()
	var name_labels := _name_labels()
	for i in range(buttons.size()):
		var button: Button = buttons[i]
		for child in preview_roots[i].get_children():
			child.queue_free()
		if i >= _entries.size():
			button.visible = false
			continue
		button.visible = true
		button.disabled = false
		button.modulate = Color.WHITE
		var entry: Dictionary = _entries[i]
		var data = entry["data"]
		name_labels[i].text = data.display_name
		var ball: BallBase = (entry["scene"] as PackedScene).instantiate() as BallBase
		ball.ui_preview = true
		ball.set_preview(data, 1)
		_ignore_control_mouse(ball)
		preview_roots[i].add_child(ball)
		ball.position = Vector2.ZERO
		ball.scale = Vector2.ONE * 0.9


func _on_slot_hovered(index: int) -> void:
	if index >= _entries.size():
		return
	var entry: Dictionary = _entries[index]
	var data = entry["data"]
	_description_label().text = data.description if data.description != "" else data.display_name
	_description_popup().visible = true


func _on_slot_unhovered() -> void:
	_description_popup().visible = false


func _on_slot_pressed(index: int) -> void:
	if _selected_ids.size() >= REWARD_PICK_COUNT or index >= _entries.size():
		return
	var entry: Dictionary = _entries[index]
	var ball_id: String = entry["id"]
	_selected_ids.append(ball_id)
	var button: Button = _slot_buttons()[index]
	button.disabled = true
	button.modulate = Color(1, 1, 1, 0)
	_description_popup().visible = false
	_continue_button().disabled = _selected_ids.size() < REWARD_PICK_COUNT


func _on_continue_pressed() -> void:
	if _selected_ids.size() < REWARD_PICK_COUNT:
		return
	selection_completed.emit(_selected_ids.duplicate())
	queue_free()


func _slot_buttons() -> Array[Button]:
	return [
		$Overlay/Card/Slots/Slot0 as Button,
		$Overlay/Card/Slots/Slot1 as Button,
		$Overlay/Card/Slots/Slot2 as Button,
		$Overlay/Card/Slots/Slot3 as Button,
		$Overlay/Card/Slots/Slot4 as Button,
	]


func _preview_roots() -> Array[Node2D]:
	return [
		$Overlay/Card/Slots/Slot0/PreviewRoot as Node2D,
		$Overlay/Card/Slots/Slot1/PreviewRoot as Node2D,
		$Overlay/Card/Slots/Slot2/PreviewRoot as Node2D,
		$Overlay/Card/Slots/Slot3/PreviewRoot as Node2D,
		$Overlay/Card/Slots/Slot4/PreviewRoot as Node2D,
	]


func _name_labels() -> Array[Label]:
	return [
		$Overlay/Card/Slots/Slot0/Name as Label,
		$Overlay/Card/Slots/Slot1/Name as Label,
		$Overlay/Card/Slots/Slot2/Name as Label,
		$Overlay/Card/Slots/Slot3/Name as Label,
		$Overlay/Card/Slots/Slot4/Name as Label,
	]


func _description_popup() -> Control:
	return $Overlay/Card/DescriptionPopup as Control


func _description_label() -> Label:
	return $Overlay/Card/DescriptionPopup/Description as Label


func _continue_button() -> Button:
	return $Overlay/Card/Continue as Button


func _ignore_control_mouse(node: Node) -> void:
	if node is Control:
		(node as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		_ignore_control_mouse(child)
