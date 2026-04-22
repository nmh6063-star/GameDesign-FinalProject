extends CanvasLayer
class_name ShopController

signal selection_completed


func _ready() -> void:
	_connect_signals()
	_populate_slots()


func _connect_signals() -> void:
	var buttons := _slot_buttons()
	for i in range(buttons.size()):
		buttons[i].pressed.connect(_on_slot_pressed.bind(i))
		buttons[i].mouse_entered.connect(_on_slot_hovered.bind(i))
		buttons[i].mouse_exited.connect(_on_slot_unhovered)
	_continue_button().pressed.connect(_on_continue_pressed)


func _populate_slots() -> void:
	# TODO: fill slots with shop items
	pass


func _on_slot_hovered(_index: int) -> void:
	# TODO: show item description
	pass


func _on_slot_unhovered() -> void:
	pass


func _on_slot_pressed(index: int) -> void:
	# TODO: apply purchased item effect
	_slot_buttons()[index].disabled = true
	_continue_button().disabled = false


func _on_continue_pressed() -> void:
	selection_completed.emit()
	GameManager.complete_current_room()


func _slot_buttons() -> Array[Button]:
	var buttons: Array[Button]
	for button in $Overlay/Card.get_children():
		buttons.append(button)
	return buttons
	"""
	return [
		$Overlay/Card/Slots/item1 as Button,
		$Overlay/Card/Slots/item2 as Button,
		$Overlay/Card/Slots/item3 as Button,
		$Overlay/Card/Slots/Slot3 as Button,
		$Overlay/Card/Slots/item4 as Button,
	]
	"""


func _preview_roots() -> Array[Node2D]:
	return [
		$Overlay/Card/Slots/item1/PreviewRoot as Node2D,
		$Overlay/Card/Slots/item2/PreviewRoot as Node2D,
		$Overlay/Card/Slots/item3/PreviewRoot as Node2D,
		$Overlay/Card/Slots/Slot3/PreviewRoot as Node2D,
		$Overlay/Card/Slots/item4/PreviewRoot as Node2D,
	]


func _name_labels() -> Array[Label]:
	return [
		$Overlay/Card/Slots/item1/Name as Label,
		$Overlay/Card/Slots/item2/Name as Label,
		$Overlay/Card/Slots/item3/Name as Label,
		$Overlay/Card/Slots/Slot3/Name as Label,
		$Overlay/Card/Slots/item4/Name as Label,
	]


func _continue_button() -> Button:
	return $Overlay/Card/Continue as Button
