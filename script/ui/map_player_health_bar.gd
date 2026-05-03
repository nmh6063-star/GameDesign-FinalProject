extends Control

@onready var _player_bar := $Background as ColorRect
@onready var _player_fill := $Fill as ColorRect
@onready var _player_hp_label := $Label as Label
@onready var _player_status_label := get_node_or_null("Status") as Label
@onready var _player_shield_fill := get_node_or_null("ShieldFill") as ColorRect


func _ready() -> void:
	sync()


func sync() -> void:
	var hp_frac := float(PlayerState.player_health) / float(maxf(1.0, PlayerState.player_max_health))
	PlayerHealthBarSync.apply_hp_fill(_player_bar, _player_fill, hp_frac)
	_player_hp_label.text = "%d/%d" % [PlayerState.player_health, PlayerState.player_max_health]
	if _player_shield_fill != null:
		_player_shield_fill.visible = false
	if _player_status_label != null:
		_player_status_label.text = ""
