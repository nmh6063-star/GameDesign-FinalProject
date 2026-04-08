extends Node2D
class_name MapController

const MapGenerator := preload("res://script/map/map_generator.gd")
const MAP_TILE_SCENE := preload("res://scenes/map_tile.tscn")
const BATTLE_SCENE := "res://scenes/main.tscn"

var _generator := MapGenerator.new()
var _tiles: Dictionary = {}
var _current_tile := Vector2.ZERO

@onready var _root := get_parent() as Node2D
@onready var _shop_button := _root.get_node("CanvasLayer/Container/Button") as Button


func _ready() -> void:
	_shop_button.visible = false
	if RunState.map_layout.is_empty():
		RunState.map_layout = _generator.build(RunState.map_size)
	_draw_map()
	_current_tile = RunState.current_tile if RunState.current_tile.x >= 0 else Vector2.ZERO
	if not _tiles.has(_current_tile):
		_current_tile = Vector2.ZERO
	_refresh_selection()


func _physics_process(_delta: float) -> void:
	var step := _input_step()
	if step != Vector2.ZERO and _tiles.has(_current_tile + step):
		_current_tile += step
		_refresh_selection()
	if Input.is_action_just_pressed("enter_level"):
		_enter_tile()
	if get_viewport():
		get_viewport().get_camera_2d().global_position = lerp(get_viewport().get_camera_2d().global_position, _current_tile * 80, 10.0 * _delta)


func _draw_map() -> void:
	for position in RunState.map_layout.keys():
		var tile := MAP_TILE_SCENE.instantiate()
		tile.position = Vector2(position.x * 80, position.y * 100)
		tile.setup(RunState.map_layout[position])
		_tiles[round(position)] = tile
		add_child(tile)


func _input_step() -> Vector2:
	if Input.is_action_just_pressed("Move_Up"):
		if _current_tile.y == -RunState.map_size.y + 1:
			return Vector2(-_current_tile.x, -1)
		return Vector2(0, -1)
	if Input.is_action_just_pressed("Move_Left"):
		if _current_tile.y == -RunState.map_size.y + 1:
			return Vector2(-_current_tile.x, -1)
		if _current_tile.x == 1:
			print("extra step")
			return Vector2(-2, -1)
		return Vector2(-1, -1)
	if Input.is_action_just_pressed("Move_Right"):
		if _current_tile.y == -RunState.map_size.y + 1:
			return Vector2(-_current_tile.x, -1)
		if _current_tile.x == -1:
			return Vector2(2, -1)
		return Vector2(1, -1)
	return Vector2.ZERO


func _enter_tile() -> void:
	var tile = _tiles[_current_tile]
	if tile.type == "chest":
		_shop_button.visible = true
		return
	elif tile.type == "random":
		var check = randi_range(0, 1)
		if check == 0:
			_shop_button.visible = true
			return
	get_tree().change_scene_to_file(BATTLE_SCENE)

func _generate_item():
	pass


func _refresh_selection() -> void:
	if _tiles.has(RunState.current_tile):
		(_tiles[RunState.current_tile] as CanvasItem).modulate = Color.WHITE
	(_tiles[_current_tile] as CanvasItem).modulate = Color(0.502, 0.502, 0.502)
	RunState.current_tile = _current_tile
