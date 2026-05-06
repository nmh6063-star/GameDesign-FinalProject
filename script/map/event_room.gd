extends Node2D
## Event room — two choices:
##   1) Heal 20% of max HP and leave.
##   2) Gamble on the Plinko board.
## Shows the player's HP bar so they can see their current state.

const PLINKO_SCENE := "res://scenes/plinko_room.tscn"

@onready var _dialog_text  := $ConversationUI/Center/VBox/DialogText     as RichTextLabel
@onready var _heal_button  := $ConversationUI/Center/VBox/TakeGoldButton as TextureButton
@onready var _heal_label   := $ConversationUI/Center/VBox/TakeGoldButton/Label as Label
@onready var _gamble_button := $ConversationUI/Center/VBox/PlayButton     as TextureButton
@onready var _gamble_label := $ConversationUI/Center/VBox/PlayButton/Label as Label
@onready var _info_label   := $ConversationUI/Center/VBox/GoldInfo        as Label
@onready var _vbox         := $ConversationUI/Center/VBox                 as VBoxContainer

var _hp_bar: ProgressBar
var _used := false


func _ready() -> void:
	_update_labels()
	_insert_hp_bar()
	_heal_button.pressed.connect(_on_heal)
	_gamble_button.pressed.connect(_on_gamble)


func _update_labels() -> void:
	_dialog_text.text = (
		"[center]You stumble upon a mysterious shrine.\n\n"
		+ "A faint glow pulses from its surface.\n"
		+ "\"Rest here, weary traveler... or tempt fate.\"[/center]"
	)
	_heal_label.text  = "Heal 20% Max HP"
	_gamble_label.text = "Gamble  (Plinko Board)"
	_sync_info()


func _insert_hp_bar() -> void:
	_hp_bar = ProgressBar.new()
	_hp_bar.custom_minimum_size = Vector2(0, 22)
	_hp_bar.max_value = PlayerState.player_max_health
	_hp_bar.value = PlayerState.player_health
	_hp_bar.show_percentage = false

	var font := load("res://assets/dogica/TTF/dogicapixelbold.ttf") as Font
	if font != null:
		_hp_bar.add_theme_font_override("font", font)
		_hp_bar.add_theme_font_size_override("font_size", 10)

	_hp_bar.add_theme_color_override("font_color", Color(1, 1, 1))
	# Insert at position 0 in the VBox (above dialog text, below nothing)
	_vbox.add_child(_hp_bar)
	_vbox.move_child(_hp_bar, 0)


func _sync_info() -> void:
	var hp := PlayerState.player_health
	var max_hp := PlayerState.player_max_health
	_info_label.text = "HP: %d / %d" % [hp, max_hp]
	if _hp_bar != null:
		_hp_bar.max_value = max_hp
		_hp_bar.value = hp


func _on_heal() -> void:
	if _used:
		return
	_used = true
	var heal_amount := int(PlayerState.player_max_health * 0.20)
	PlayerState.heal(heal_amount)
	_sync_info()
	_heal_button.disabled = true
	_gamble_button.disabled = true
	_dialog_text.text = (
		"[center][color=lime]The shrine glows warmly.[/color]\n\n"
		+ "You recover [b]%d HP[/b].\n\nHP: %d / %d[/center]" % [
			heal_amount, PlayerState.player_health, PlayerState.player_max_health
		]
	)
	await get_tree().create_timer(1.4).timeout
	if is_inside_tree():
		GameManager.complete_current_room()


func _on_gamble() -> void:
	if _used:
		return
	_used = true
	get_tree().change_scene_to_file(PLINKO_SCENE)
