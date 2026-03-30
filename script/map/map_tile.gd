extends Polygon2D

var type = ""

var images = {
	"fight" : preload("res://assets/tempAssets/sword.png"),
	"chest" : preload("res://assets/tempAssets/chest.png"),
	"shop" : preload("res://assets/tempAssets/dollar.png"),
	"random" : preload("res://assets/tempAssets/random.png"),
	"empty" : null
}

func setPanel(x: String):
	type = x
	$Sprite2D.texture = images[x]
