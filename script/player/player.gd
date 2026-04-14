extends Node2D

var _base_modulate := Color.WHITE
@onready var _sprite := get_node_or_null("Sprite2D") as Sprite2D

func _ready() -> void:
	if _sprite != null:
		_base_modulate = _sprite.modulate

func flash() -> void:
	if _sprite == null:
		return
	_sprite.modulate = Color(18.892, 0.0, 0.0)
	$Timer.start()


func _on_timer_timeout() -> void:
	if _sprite != null:
		_sprite.modulate = _base_modulate
