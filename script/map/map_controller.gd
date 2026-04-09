extends Node2D
class_name MapController

const MapGenerator := preload("res://script/map/map_generator.gd")
const MAP_TILE_SCENE := preload("res://scenes/map_tile.tscn")
const BATTLE_SCENE := "res://scenes/main.tscn"

var _generator := MapGenerator.new()
var _tiles: Dictionary = {}
var _current_tile := Vector2i.ZERO

@onready var _root := get_parent() as Node2D
@onready var _shop_button := _root.get_node("CanvasLayer/Container/Button") as Button


func _ready() -> void:
	_shop_button.visible = false
	if MapState.map_layout.is_empty():
		MapState.map_layout = _generator.build(MapState.map_size)
	_draw_map()
	_current_tile = MapState.current_tile if MapState.current_tile.x >= 0 else Vector2i.ZERO
	if not _tiles.has(_current_tile):
		_current_tile = Vector2i.ZERO
	_refresh_selection()


func _physics_process(_delta: float) -> void:
	var step := _input_step()
	if step != Vector2i.ZERO and _tiles.has(_current_tile + step):
		_current_tile += step
		_refresh_selection()
	if Input.is_action_just_pressed("enter_level"):
		_enter_tile()


func _draw_map() -> void:
	for position in MapState.map_layout.keys():
		var tile := MAP_TILE_SCENE.instantiate()
		tile.position = Vector2(position.x * 80, position.y * 80)
		tile.setup(MapState.map_layout[position])
		_tiles[position] = tile
		add_child(tile)


func _input_step() -> Vector2i:
	if Input.is_action_just_pressed("Move_Up"):
		return Vector2i(0, -1)
	if Input.is_action_just_pressed("Move_Down"):
		return Vector2i(0, 1)
	if Input.is_action_just_pressed("Move_Right"):
		return Vector2i(1, 0)
	return Vector2i.ZERO


func _enter_tile() -> void:
	var tile = _tiles[_current_tile]
	if tile.type == "shop":
		_shop_button.visible = true
		return
	get_tree().change_scene_to_file(BATTLE_SCENE)


func _refresh_selection() -> void:
	if _tiles.has(MapState.current_tile):
		(_tiles[MapState.current_tile] as CanvasItem).modulate = Color.WHITE
	(_tiles[_current_tile] as CanvasItem).modulate = Color(0.502, 0.502, 0.502)
	MapState.current_tile = _current_tile
