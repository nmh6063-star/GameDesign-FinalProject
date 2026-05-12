extends Node

static func play_sound_from_string(name: String, volume = null, loop = false, vary = true, pitcher = 0.0) -> void:
	var path = "res://assets/sounds/%s.wav" % name
	
	var sound = load(path)
	if sound == null:
		push_error("Sound not found at path: " + path)
		return
	
	var player = AudioStreamPlayer.new()
	player.process_mode = Node.PROCESS_MODE_ALWAYS
	Engine.get_main_loop().root.add_child(player)
	
	player.stream = sound
	if !loop and vary:
		player.pitch_scale = randf_range(0.9 + pitcher, 1.1 + pitcher)
	if volume:
		player.volume_db = linear_to_db(volume)
	player.play()
	
	player.name = "player"
	
	if !loop:
		player.finished.connect(func():
			player.queue_free()
		)
	else:
		player.finished.connect(func():
			player.play()
		)
