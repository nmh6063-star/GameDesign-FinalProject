extends Node2D

const _LAYERS := [
	[26.0, Color(0.88, 0.12, 0.12)],
	[18.0, Color(0.95, 0.95, 0.98)],
	[12.0, Color(0.82, 0.1, 0.1)],
	[7.0, Color(0.96, 0.96, 1.0)],
	[3.0, Color(0.92, 0.08, 0.08)],
]


func _ready() -> void:
	var z := 0
	for layer in _LAYERS:
		var r := float(layer[0])
		var col: Color = layer[1] as Color
		var spr := Sprite2D.new()
		spr.texture = _circle_texture(int(ceil(r)), col)
		spr.z_index = z
		z += 1
		add_child(spr)


func _circle_texture(radius: int, color: Color) -> ImageTexture:
	var size := radius * 2 + 2
	var c := Vector2(size / 2.0, size / 2.0)
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	for y in range(size):
		for x in range(size):
			if Vector2(x + 0.5, y + 0.5).distance_to(c) <= float(radius):
				img.set_pixel(x, y, color)
	return ImageTexture.create_from_image(img)
