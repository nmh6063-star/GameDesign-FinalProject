extends Node2D

## Emitted when a plinko ball first enters this target's hit zone.
signal struck(body: Node2D)

const _LAYERS := [
	[26.0, Color(0.88, 0.12, 0.12)],
	[18.0, Color(0.95, 0.95, 0.98)],
	[12.0, Color(0.82, 0.1, 0.1)],
	[7.0, Color(0.96, 0.96, 1.0)],
	[3.0, Color(0.92, 0.08, 0.08)],
]

@export var move_amplitude: float = 30.0
@export var move_speed: float = 1.65
@export var phase: float = 0.0

var _home: Vector2
var _consumed := false
var _struck_sent := false


func _ready() -> void:
	_home = position
	_build_rings()
	var zone := Area2D.new()
	zone.name = "HitZone"
	zone.monitoring = true
	zone.monitorable = false
	zone.collision_layer = 0
	zone.collision_mask = 1
	var zsh := CollisionShape2D.new()
	var circ := CircleShape2D.new()
	circ.radius = 24.0
	zsh.shape = circ
	zone.add_child(zsh)
	add_child(zone)
	zone.body_entered.connect(_on_hit_zone_body_entered)


func mark_consumed() -> void:
	_consumed = true
	_struck_sent = true
	var zone := get_node_or_null("HitZone") as Area2D
	if zone != null:
		zone.monitoring = false


func reset_strike_gate() -> void:
	_struck_sent = false


func _physics_process(_delta: float) -> void:
	if _consumed:
		return
	var t := Time.get_ticks_msec() * 0.001 * move_speed + phase
	position.x = _home.x + sin(t) * move_amplitude


func _build_rings() -> void:
	var z := 0
	for layer in _LAYERS:
		var r := float(layer[0])
		var col: Color = layer[1] as Color
		var spr := Sprite2D.new()
		spr.texture = _circle_texture(int(ceil(r)), col)
		spr.z_index = z
		z += 1
		add_child(spr)


func _on_hit_zone_body_entered(body: Node2D) -> void:
	if _consumed or _struck_sent:
		return
	if body != null and body.is_in_group("plinko_ball"):
		_struck_sent = true
		struck.emit(body)


func _circle_texture(radius: int, color: Color) -> ImageTexture:
	var size := radius * 2 + 2
	var c := Vector2(size / 2.0, size / 2.0)
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	for y in range(size):
		for x in range(size):
			if Vector2(x + 0.5, y + 0.5).distance_to(c) <= float(radius):
				img.set_pixel(x, y, color)
	return ImageTexture.create_from_image(img)
