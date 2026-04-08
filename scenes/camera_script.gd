extends Camera2D

@export var intensity := 1.0
@export var shake_decay := 1.5
@export var max_offset := 60.0
@export var max_roll := 10.0
@export var noise_speed := 25.0

var trauma := 0.0
var noise := FastNoiseLite.new()
var noise_time := 0.0

func _ready():
	noise.seed = randi()
	noise.frequency = 1.0

func _process(delta):
	if trauma > 0.0:
		trauma = max(trauma - shake_decay * delta, 0.0)
		noise_time += delta * noise_speed
		_apply_shake()
	else:
		offset = Vector2.ZERO
		rotation_degrees = 0.0

func _apply_shake():
	var shake = trauma * trauma * intensity

	offset.x = noise.get_noise_2d(noise_time, 0.0) * max_offset * shake
	offset.y = noise.get_noise_2d(0.0, noise_time) * max_offset * shake
	rotation_degrees = noise.get_noise_2d(noise_time, noise_time) * max_roll * shake

func shake(amount: float):
	trauma = clamp(trauma + amount, 0.0, 1.0)
