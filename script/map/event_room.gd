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

## Styled HP bar nodes (same layout as the map-screen PlayerHealthBar).
var _hp_bg:    ColorRect
var _hp_fill:  ColorRect
var _hp_label: Label
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


## Build a styled HP bar (Background / Fill / Label) and insert it at the top of the VBox.
## Matches the visual style of the map-screen top-right PlayerHealthBar.
func _insert_hp_bar() -> void:
	var font_bold := load("res://assets/dogica/TTF/dogicabold.ttf") as Font

	# Outer container — fixed height, fills VBox width.
	var bar_container := Control.new()
	bar_container.custom_minimum_size = Vector2(0, 38)
	bar_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# Dark background track.
	_hp_bg = ColorRect.new()
	_hp_bg.layout_mode = 1
	_hp_bg.anchors_preset = Control.PRESET_FULL_RECT
	_hp_bg.offset_top    =  2.0
	_hp_bg.offset_bottom = -2.0
	_hp_bg.color = Color(0.05, 0.05, 0.05, 1.0)
	bar_container.add_child(_hp_bg)

	# Green HP fill — width is set dynamically in _sync_info().
	_hp_fill = ColorRect.new()
	_hp_fill.layout_mode = 0
	_hp_fill.anchor_top    = 0.0
	_hp_fill.anchor_bottom = 1.0
	_hp_fill.offset_top    =  2.0
	_hp_fill.offset_bottom = -2.0
	_hp_fill.size = Vector2(0.0, 0.0)
	_hp_fill.color = Color(0.0, 0.76, 0.0, 1.0)
	bar_container.add_child(_hp_fill)

	# HP text label centred over the bar.
	_hp_label = Label.new()
	_hp_label.layout_mode = 1
	_hp_label.anchors_preset = Control.PRESET_FULL_RECT
	_hp_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_hp_label.grow_vertical   = Control.GROW_DIRECTION_BOTH
	_hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hp_label.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	if font_bold != null:
		_hp_label.add_theme_font_override("font", font_bold)
	_hp_label.add_theme_font_size_override("font_size", 14)
	_hp_label.add_theme_color_override("font_color", Color(1, 1, 1))
	bar_container.add_child(_hp_label)

	_vbox.add_child(bar_container)
	_vbox.move_child(bar_container, 0)

	# Hide the plain text info label — the bar replaces it visually.
	if _info_label != null:
		_info_label.visible = false

	_sync_info()


func _sync_info() -> void:
	var hp     := PlayerState.player_health
	var max_hp := PlayerState.player_max_health
	if _hp_label != null:
		_hp_label.text = "%d / %d" % [hp, max_hp]
	if _hp_bg != null and _hp_fill != null:
		PlayerHealthBarSync.apply_hp_fill(
			_hp_bg, _hp_fill,
			float(hp) / maxf(1.0, float(max_hp))
		)


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
