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

const sound := preload("res://script/game_manager/sound_manager.gd")

#Overlay related
@onready var effects_ui = get_node_or_null("/root/Main/UI/Effects")
@onready var image = get_node_or_null("/root/Main/UI/Effects/Image")
@onready var color = get_node_or_null("/root/Main/UI/Effects/Color")
@onready var over_effects_ui = get_node_or_null("/root/Main/UI/OverEffects")
@onready var color_over = get_node_or_null("/root/Main/UI/OverEffects/Color")
@onready var ui = get_node_or_null("/root/Main/UI")

var music = ["BattleJazz", "PersonaJazz", "MoonlitMelee"]

var overlays = {
	"frozen": preload("res://assets/frost.png")
}

#freeze related
var frozen = false

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	noise.seed = randi()
	noise.frequency = 1.0
	camera.process_mode = Node.PROCESS_MODE_ALWAYS

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

func _color(type):
	color.visible = true
	if type == "damage":
		color.modulate = Color(1.0, 0.0, 0.0, 0.25)
	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = 0.1
	timer.one_shot = true
	timer.timeout.connect(_on_ui_timer_timeout.bind(color))
	timer.start()

func _image(type):
	image.visible = true
	image.texture = overlays[type]
	image.modulate = Color(1.0, 1.0, 1.0, 0.35)
	var timer = Timer.new()
	add_child(timer)
	get_node("/root/Main/BallHolder/BattleController").status_met.connect(_on_ui_timer_timeout.bind(image))
	#timer.timeout.connect(_on_ui_timer_timeout)
	#timer.start()

func _on_ui_timer_timeout(obj):
	obj.visible = false
	self.queue_free()

func _starter():
	get_tree().paused = true
	over_effects_ui.visible = true
	color_over.visible = true
	color_over.modulate = Color(0, 0, 0, 0.5)
	
	var control = Control.new()
	over_effects_ui.add_child(control)

	# Create Label
	var label = Label.new()
	label.text = "Ready?"
	label.position = Vector2(-300, 200)
	label.add_theme_font_size_override("font_size", 48)

	# Black outline / highlight
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 8)

	# White text
	label.add_theme_color_override("font_color", Color.WHITE)
	
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	control.add_child(label)

	# Tween movement across screen
	var tween = create_tween()

	tween.tween_property(
		label,
		"position:x",
		camera.get_screen_center_position().x,
		1.0
	)
	
	tween.finished.connect(_on_ready_finished)
	
func _on_ready_finished():
	await get_tree().create_timer(1.0).timeout
	var control = Control.new()
	over_effects_ui.add_child(control)

	# Create Label
	var label = Label.new()
	label.text = "Go!"
	label.position = Vector2(-300, 300)
	label.add_theme_font_size_override("font_size", 48)

	# Black outline / highlight
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 8)

	# White text
	label.add_theme_color_override("font_color", Color.WHITE)
	
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	control.add_child(label)

	# Tween movement across screen
	var tween = create_tween()

	tween.tween_property(
		label,
		"position:x",
		camera.get_screen_center_position().x,
		0.25
	)
	sound.play_sound_from_string("start")
	tween.finished.connect(_on_go_finished)

func _on_go_finished():
	await get_tree().create_timer(2.0).timeout
	over_effects_ui.queue_free()
	var index = randi() % music.size()
	sound.play_sound_from_string(music[index], 0.25, true)
	get_tree().paused = false
	self.queue_free()
	
func _top_out():
	sound.play_sound_from_string("topout")
	get_tree().paused = true
	
	var control = Control.new()
	ui.add_child(control)

	# Create Label
	var label = Label.new()
	label.text = "TOPPED OUT!"
	label.position = camera.get_screen_center_position()
	label.add_theme_font_size_override("font_size", 48)
	control.add_child(label)
	await get_tree().create_timer(1.0).timeout
	control.queue_free()
	get_tree().paused = false
	self.queue_free()
