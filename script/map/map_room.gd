extends Area2D
class_name MapRoom

const MapGenerator := preload("res://script/map/map_generator.gd")
const _MapRoute := preload("res://script/map/map_route_colors.gd")

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

const BASE_ICON_SCALE := Vector2(0.026, 0.026)
const BORDER_RADIUS := 16.0
const CLICK_RADIUS := 40.0
const BORDER_WIDTH := 2.0
const BORDER_SUPERSAMPLE := 4.0
const BORDER_COLOR := Color(0.10, 0.08, 0.14, 0.72)
## Inside the ring: same geometry as `_border_texture` (centerline at BORDER_RADIUS in node space, stroke BORDER_WIDTH).
const FILL_INSET := 0.12
const FILL_DISK_SEGMENTS := 48
const ICON_ON_ROUTE := Color(0.98, 0.96, 0.95, 1.0)
const FILL_CLEAR := Color(1, 1, 1, 0)

signal selected(room: MapGenerator.Room)
signal hover_choice_changed(room: MapGenerator.Room, hovering: bool)

var room: MapGenerator.Room
var selectable := false
var _visited := false
var _current := false
var _hover := false
static var _border_textures := {}


static func texture_for_type(room_type: int) -> Texture2D:
	return TEXTURES.get(room_type)


static func label_for_type(room_type: int) -> String:
	return LABELS.get(room_type, "Room")


static func short_label_for_type(room_type: int) -> String:
	return SHORT_LABELS.get(room_type, "??")


static func tint_for_type(room_type: int) -> Color:
	return TINTS.get(room_type, Color.WHITE)


static func _disk_polygon(radius: float, segments: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(segments):
		var a := TAU * float(i) / float(segments)
		pts.append(Vector2(cos(a), sin(a)) * radius)
	return pts


static func _fill_disk_radius() -> float:
	return maxf(0.1, BORDER_RADIUS - BORDER_WIDTH * 0.5 - FILL_INSET)


func set_room(room_data: MapGenerator.Room) -> void:
	if not mouse_entered.is_connected(_on_mouse_entered):
		mouse_entered.connect(_on_mouse_entered)
		mouse_exited.connect(_on_mouse_exited)
	input_pickable = true
	monitoring = true
	monitorable = true
	room = room_data
	var texture := texture_for_type(int(room.type))
	# MapGraph calls this in the same stack frame as add_child, before this node's _ready — use $, not @onready.
	var col := $CollisionShape2D as CollisionShape2D
	var fill := $Visuals/Fill as Polygon2D
	var brd := $Visuals/Border as Sprite2D
	var spr := $Visuals/Sprite2D as Sprite2D
	var vis := $Visuals as Node2D
	var anim := $AnimationPlayer as AnimationPlayer
	fill.polygon = _disk_polygon(_fill_disk_radius(), FILL_DISK_SEGMENTS)
	fill.color = FILL_CLEAR
	fill.z_index = -1
	brd.z_index = 0
	spr.z_index = 1
	if col.shape == null or not col.shape is CircleShape2D:
		col.shape = CircleShape2D.new()
	(col.shape as CircleShape2D).radius = CLICK_RADIUS
	brd.texture = _border_texture(BORDER_RADIUS, BORDER_WIDTH, BORDER_SUPERSAMPLE)
	brd.scale = Vector2.ONE / BORDER_SUPERSAMPLE
	brd.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	brd.modulate = BORDER_COLOR
	spr.texture = texture
	spr.visible = texture != null
	spr.scale = BASE_ICON_SCALE
	spr.modulate = tint_for_type(int(room.type))
	vis.scale = Vector2.ONE
	anim.play("RESET")


func set_state(is_available: bool, is_current: bool, is_visited: bool) -> void:
	if room == null:
		return
	selectable = is_available
	_visited = is_visited
	_current = is_current
	_apply_appearance()


func _apply_appearance() -> void:
	if room == null:
		return
	var fill := $Visuals/Fill as Polygon2D
	var spr := $Visuals/Sprite2D as Sprite2D
	var brd := $Visuals/Border as Sprite2D
	var anim := $AnimationPlayer as AnimationPlayer
	var route := _MapRoute.ROUTE
	var hidden := room.mystery and not _visited and not _current
	if hidden:
		spr.visible = false
		spr.modulate = Color("d4a017")
		fill.color = FILL_CLEAR
		brd.modulate = Color("d4a017")
	else:
		var texture := texture_for_type(int(room.type))
		spr.texture = texture
		spr.visible = texture != null
		spr.scale = BASE_ICON_SCALE
		spr.modulate = tint_for_type(int(room.type))
	var modulate_color := Color("d4a017") if hidden else tint_for_type(int(room.type))
	if not _visited and not selectable and not _current:
		modulate_color = modulate_color.darkened(0.45)
	var hot := _hover and selectable
	var on_route := hot or _visited
	if not hidden:
		if on_route:
			spr.modulate = ICON_ON_ROUTE
			fill.color = route
			brd.modulate = route
		else:
			spr.modulate = modulate_color
			fill.color = FILL_CLEAR
			brd.modulate = BORDER_COLOR
	anim.play("highlight" if hot else "RESET")


func _on_mouse_entered() -> void:
	if not selectable:
		return
	_hover = true
	hover_choice_changed.emit(room, true)
	_apply_appearance()


func _on_mouse_exited() -> void:
	if selectable:
		hover_choice_changed.emit(room, false)
	_hover = false
	_apply_appearance()


func _input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if not selectable or room == null:
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
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
