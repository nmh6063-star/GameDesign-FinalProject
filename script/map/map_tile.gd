extends Polygon2D
class_name MapTile

var type := ""

const IMAGES := {
	"fight" : preload("res://assets/tempAssets/sword.png"),
	"chest" : preload("res://assets/tempAssets/chest.png"),
	"shop" : preload("res://assets/tempAssets/dollar.png"),
	"random" : preload("res://assets/tempAssets/random.png"),
	"empty" : null
}


func setup(tile_type: String) -> void:
	type = tile_type
	$Sprite2D.texture = IMAGES[tile_type]
