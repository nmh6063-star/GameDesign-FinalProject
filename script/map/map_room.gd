extends Area2D
class_name MapRoom

const MapGenerator := preload("res://script/map/map_generator.gd")

const TEXTURES := {
	MapGenerator.Room.Type.MONSTER: preload("res://assets/tempAssets/sword.png"),
	MapGenerator.Room.Type.TREASURE: preload("res://assets/tempAssets/chest.png"),
	MapGenerator.Room.Type.SHOP: preload("res://assets/tempAssets/dollar.png"),
	MapGenerator.Room.Type.CAMPFIRE: preload("res://assets/tempAssets/random.png"),
	MapGenerator.Room.Type.BOSS: preload("res://assets/tempAssets/sword.png"),
}

const LABELS := {
	MapGenerator.Room.Type.START: "Start",
	MapGenerator.Room.Type.MONSTER: "Battle",
	MapGenerator.Room.Type.TREASURE: "Treasure",
	MapGenerator.Room.Type.SHOP: "Shop",
	MapGenerator.Room.Type.CAMPFIRE: "Campfire",
	MapGenerator.Room.Type.BOSS: "Boss",
	MapGenerator.Room.Type.EVENT: "Event",
}

const SHORT_LABELS := {
	MapGenerator.Room.Type.START: "ST",
	MapGenerator.Room.Type.MONSTER: "BT",
	MapGenerator.Room.Type.TREASURE: "TR",
	MapGenerator.Room.Type.SHOP: "SH",
	MapGenerator.Room.Type.CAMPFIRE: "CF",
	MapGenerator.Room.Type.BOSS: "BS",
	MapGenerator.Room.Type.EVENT: "?",
}

const TINTS := {
	MapGenerator.Room.Type.START: Color("f2e6b8"),
	MapGenerator.Room.Type.MONSTER: Color("120c11"),
	MapGenerator.Room.Type.TREASURE: Color("120c11"),
	MapGenerator.Room.Type.SHOP: Color("120c11"),
	MapGenerator.Room.Type.CAMPFIRE: Color("120c11"),
	MapGenerator.Room.Type.BOSS: Color("6b091d"),
	MapGenerator.Room.Type.EVENT: Color("d4a017"),
}

const BASE_ICON_SCALE := Vector2(0.015, 0.015)
const BORDER_RADIUS := 8.0
const BORDER_WIDTH := 2.0
const BORDER_SUPERSAMPLE := 4.0
const BORDER_COLOR := Color(0.10, 0.08, 0.14, 0.72)
const HIGHLIGHT_COLOR := Color(1.0, 0.32, 0.36, 0.96)

signal selected(room: MapGenerator.Room)

@onready var animation_player := $AnimationPlayer as AnimationPlayer
@onready var visuals := $Visuals as Node2D
@onready var border := $Visuals/Border as Sprite2D
@onready var sprite_2d := $Visuals/Sprite2D as Sprite2D
@onready var collision_shape := $CollisionShape2D as CollisionShape2D

var room: MapGenerator.Room
var selectable := false
static var _border_textures := {}


static func texture_for_type(room_type: int) -> Texture2D:
	return TEXTURES.get(room_type)


static func label_for_type(room_type: int) -> String:
	return LABELS.get(room_type, "Room")


static func short_label_for_type(room_type: int) -> String:
	return SHORT_LABELS.get(room_type, "??")


static func tint_for_type(room_type: int) -> Color:
	return TINTS.get(room_type, Color.WHITE)


func set_room(room_data: MapGenerator.Room) -> void:
	room = room_data
	var texture := texture_for_type(int(room.type))
	var shape := collision_shape.shape as CircleShape2D
	if shape != null:
		shape.radius = BORDER_RADIUS
	border.texture = _border_texture(BORDER_RADIUS, BORDER_WIDTH, BORDER_SUPERSAMPLE)
	border.scale = Vector2.ONE / BORDER_SUPERSAMPLE
	border.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	border.modulate = BORDER_COLOR
	sprite_2d.texture = texture
	sprite_2d.visible = texture != null
	sprite_2d.scale = BASE_ICON_SCALE
	sprite_2d.modulate = tint_for_type(int(room.type))
	visuals.scale = Vector2.ONE
	animation_player.play("RESET")


func set_state(is_available: bool, is_current: bool, is_visited: bool, is_selected: bool) -> void:
	if room == null:
		return
	selectable = is_available
	var hidden := room.mystery and not is_visited and not is_current
	if hidden:
		sprite_2d.visible = false
		sprite_2d.modulate = Color("d4a017")
	else:
		var texture := texture_for_type(int(room.type))
		sprite_2d.texture = texture
		sprite_2d.visible = texture != null
		sprite_2d.scale = BASE_ICON_SCALE
		sprite_2d.modulate = tint_for_type(int(room.type))
	var modulate_color := Color("d4a017") if hidden else tint_for_type(int(room.type))
	if not is_visited and not is_available and not is_current:
		modulate_color = modulate_color.darkened(0.45)
	if is_current:
		modulate_color = Color.WHITE
	if not hidden:
		sprite_2d.modulate = modulate_color
	border.modulate = HIGHLIGHT_COLOR if is_current or is_selected else BORDER_COLOR
	if is_current or is_selected:
		animation_player.play("highlight")
	else:
		animation_player.play("RESET")


func _input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if not selectable or room == null or not event.is_action_pressed("left_mouse"):
		return
	selected.emit(room)


func _border_texture(radius: float, width: float, supersample: float) -> Texture2D:
	var key := "%s:%s:%s" % [radius, width, supersample]
	if _border_textures.has(key):
		return _border_textures[key]
	var scaled_radius: float = radius * supersample
	var scaled_width: float = maxf(width * supersample, 1.0)
	var margin := int(ceil(scaled_width)) + 2
	var size := int(ceil(scaled_radius * 2.0)) + margin * 2
	var center := Vector2(size * 0.5, size * 0.5)
	var half_width: float = scaled_width * 0.5
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(Color(1, 1, 1, 0))
	for y in range(size):
		for x in range(size):
			var distance := Vector2(x + 0.5, y + 0.5).distance_to(center)
			var alpha: float = clampf(half_width + 0.75 - absf(distance - scaled_radius), 0.0, 1.0)
			if alpha > 0.0:
				image.set_pixel(x, y, Color(1, 1, 1, alpha))
	var texture := ImageTexture.create_from_image(image)
	_border_textures[key] = texture
	return texture
