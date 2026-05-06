extends Node2D

const SEGMENTS := 48
const ICON_SIZE := 22.0

@export var radius := 18.0
@export var ring_width := 4.0
@export var base_color := Color(0.2, 0.16, 0.12, 0.9)
@export var fill_color := Color(0.96, 0.53, 0.08, 1.0)

var _progress := 1.0
var _icon: Sprite2D

@onready var _label := $Label as Label


func _ready() -> void:
	_icon = get_node_or_null("icon") as Sprite2D
	if _icon == null:
		_icon = Sprite2D.new()
		add_child(_icon)
	_icon.visible = false


func set_icon(texture: Texture2D) -> void:
	if _icon == null:
		return
	_icon.texture = texture
	_icon.visible = texture != null
	if texture != null:
		var t_size := texture.get_size()
		var max_dim := maxf(t_size.x, t_size.y)
		_icon.scale = Vector2.ONE * (ICON_SIZE / max_dim) if max_dim > 0.0 else Vector2.ONE


func sync(seconds_left: float, duration: float) -> void:
	visible = duration > 0.0
	if not visible:
		return
	_progress = clampf(seconds_left / duration, 0.0, 1.0)
	#_label.text = str(int(ceil(seconds_left)))
	queue_redraw()


func _draw() -> void:
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, SEGMENTS, base_color, ring_width, true)
	if _progress <= 0.0:
		return
	draw_arc(
		Vector2.ZERO,
		radius,
		-PI * 0.5,
		-PI * 0.5 + TAU * _progress,
		SEGMENTS,
		fill_color,
		ring_width,
		true,
	)
