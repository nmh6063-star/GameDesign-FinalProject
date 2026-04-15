extends Node

var primed = false

#camera related variables
var trauma := 0.0
var noise := FastNoiseLite.new()
var noise_time := 0.0
var intensity := 1.0
var shake_decay := 1.5
var max_offset := 60.0
var max_roll := 10.0
var noise_speed := 25.0
@onready var camera = get_viewport().get_camera_2d()

#freeze related
var frozen = false

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	noise.seed = randi()
	noise.frequency = 1.0

func _process(delta):
	if frozen and !get_tree().paused:
		get_tree().paused = true
	if trauma > 0.0:
		trauma = max(trauma - shake_decay * delta, 0.0)
		noise_time += delta * noise_speed
		_apply_shake()
		primed = true
	else:
		if primed:
			self.queue_free()
		camera.offset = Vector2.ZERO
		camera.rotation_degrees = 0.0

func _apply_shake():
	var shake = trauma * trauma * intensity
	camera.offset.x = noise.get_noise_2d(noise_time, 0.0) * max_offset * shake
	camera.offset.y = noise.get_noise_2d(0.0, noise_time) * max_offset * shake
	camera.rotation_degrees = noise.get_noise_2d(noise_time, noise_time) * max_roll * shake

func shake(amount: float):
	trauma = clamp(trauma + amount, 0.0, 1.0)

func freeze_frame(time: float):
	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = time
	timer.one_shot = true
	timer.timeout.connect(_on_timer_timeout)
	timer.start()
	frozen = true

func _on_timer_timeout():
	get_tree().paused = false
	frozen = false
	self.queue_free()
