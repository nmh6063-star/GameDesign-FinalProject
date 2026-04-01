extends Node2D

var tile = preload("res://scenes/map_tile.tscn")
var gameState = "res://scenes/main.tscn"
var currentTile = Vector2(0, 0)
@onready var shopButton = $"/root/Node2D/CanvasLayer/Container/Button"

func _ready() -> void:
	shopButton.visible = false
	if !Global.map_drawn:
		Global.map_drawn = true
		_generate_map()
	else:
		for i in range(Global.savedMapData.size()):
			_generate_tile(Global.savedMapData[i]["pos"], Global.savedMapData[i]["type"])

func _physics_process(delta: float) -> void:
	if currentTile != Global.current_tile:
		_set_current_tile()
	if Input.is_action_just_pressed("Move_Up"):
		if _check_tile_valid(Vector2(currentTile.x, currentTile.y - 1)):
			currentTile.y -= 1
	elif Input.is_action_just_pressed("Move_Down"):
		if _check_tile_valid(Vector2(currentTile.x, currentTile.y + 1)):
			currentTile.y += 1
	elif Input.is_action_just_pressed("Move_Right"):
		if _check_tile_valid(Vector2(currentTile.x + 1, currentTile.y)):
			currentTile.x += 1
	if Input.is_action_just_pressed("enter_level"):
		var tileType = _get_current_tile_type()
		if tileType == "shop" or tileType == "chest":
			shopButton.visible = true
			shopButton.pressed.connect(_add_ball)
		else:
			get_tree().change_scene_to_file(gameState)
	#print(currentTile)

func _add_ball():
	Global.boughtBalls.append("EXPLODE")

func _generate_map():
	var horizontal = 0
	while horizontal < Global.map_horizontal:
		for x in range(2):
			_generate_tile(Vector2(horizontal, 0), "")
			var vertical1 = 0
			var vertical2 = 0
			for i in range(2):
				var vertical = 0
				while vertical < Global.map_vertical and vertical > -Global.map_vertical:
					var vertChance = randi_range(0, 1)
					if vertChance == 1:
						if i == 0:
							vertical +=  1
						else:
							vertical -= 1
						print(vertical)
						print("moving")
						_generate_tile(Vector2(horizontal, vertical), "")
					else:
						break
				if i == 0:
					vertical1 = vertical
					print(str(vertical1) + " is first ending")
				else:
					vertical2 = vertical
					print(str(vertical2) + " is second ending")
				print("tester")
			horizontal += 1
			_generate_tile(Vector2(horizontal, 0), "")
			for i in range(2):
				var vert = 0
				var modifier = 1
				if i == 0:
					vert = vertical1
				else:
					vert = abs(vertical2)
					modifier = -1
				var counter = 1
				print(str(vert) + " and going " + str(modifier))
				while vert > 0:
					_generate_tile(Vector2(horizontal, counter * modifier), "")
					vert -= 1
					counter += 1
				print(counter)
			horizontal += 1
	_generate_tile(Vector2(horizontal, 0), "empty")
	
func _generate_tile(pos: Vector2, typing: String):
	var inst = tile.instantiate()
	inst.position = pos * 80
	var setType = randf_range(0.0, 1.0)
	var type = typing
	if typing == "":
		if pos == Vector2.ZERO:
			type = "empty"
		else:
			if setType < 0.25:
				type = "fight"
			elif setType < 0.5:
				type = "chest"
			elif setType < 0.75:
				type = "shop"
			else:
				type = "random"
	inst.setPanel(type)
	add_child(inst)
	Global.savedMapData.append({"type" = type, "pos" = pos})

func _check_tile_valid(pos: Vector2):
	var children = get_children()
	for child in children:
		if child.position == pos * 80:
			print("test")
			return true
	print("tried")
	return false

func _set_current_tile():
	var children = get_children()
	print(currentTile)
	print(Global.current_tile)
	for child in children:
		if child.position == currentTile * 80:
			child.modulate = Color(0.502, 0.502, 0.502)
			print("hit one")
		elif child.position == Global.current_tile * 80:
			child.modulate = Color(1.0, 1.0, 1.0)
			print("hit two")
	Global.current_tile = currentTile

func _get_current_tile_type():
	var children = get_children()
	for child in children:
		if child.position == currentTile * 80:
			return child.type
	return "empty"
