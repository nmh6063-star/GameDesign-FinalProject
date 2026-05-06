extends Node2D
## Event room — two choices:
##   1) Heal 20% of max HP and leave.
##   2) Gamble on the Plinko board.
## Uses the same map-screen PlayerHealthBar (top-right) via MapHud layer.

const PLINKO_SCENE := "res://scenes/plinko_room.tscn"

@onready var _dialog_text := $ConversationUI/Center/VBox/DialogText as RichTextLabel
@onready var _heal_button := $ConversationUI/Center/VBox/TakeGoldButton as TextureButton
@onready var _heal_label := $ConversationUI/Center/VBox/TakeGoldButton/Label as Label
@onready var _gamble_button := $ConversationUI/Center/VBox/PlayButton as TextureButton
@onready var _gamble_label := $ConversationUI/Center/VBox/PlayButton/Label as Label
@onready var _info_label := $ConversationUI/Center/VBox/GoldInfo as Label
@onready var _map_hp_bar := $MapHud/PlayerHealthBar

var _used := false


func _ready() -> void:
	_update_labels()
	_sync_map_hp_bar()
	_heal_button.pressed.connect(_on_heal)
	_gamble_button.pressed.connect(_on_gamble)


func _update_labels() -> void:
	_dialog_text.text = (
		"[center]You stumble upon a mysterious shrine.\n\n"
		+ "A faint glow pulses from its surface.\n"
		+ "\"Rest here, weary traveler... or tempt fate.\"[/center]"
	)
	_heal_label.text = "Heal 20% Max HP"
	_gamble_label.text = "Gamble  (Plinko Board)"
	if _info_label != null:
		_info_label.visible = true


func _sync_map_hp_bar() -> void:
	if _map_hp_bar != null and _map_hp_bar.has_method("sync"):
		_map_hp_bar.sync()


func _on_heal() -> void:
	if _used:
		return
	_used = true
	var heal_amount := int(PlayerState.player_max_health * 0.20)
	PlayerState.heal(heal_amount)
	_sync_map_hp_bar()
	_heal_button.disabled = true
	_gamble_button.disabled = true
	_dialog_text.text = (
		"[center][color=lime]The shrine glows warmly.[/color]\n\n"
		+ "You recover [b]%d HP[/b].[/center]" % heal_amount
	)
	await get_tree().create_timer(1.4).timeout
	if is_inside_tree():
		GameManager.complete_current_room()


func _on_gamble() -> void:
	if _used:
		return
	_used = true
	get_tree().change_scene_to_file(PLINKO_SCENE)
