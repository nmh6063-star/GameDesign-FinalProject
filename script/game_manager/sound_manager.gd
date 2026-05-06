extends Node

static func play_sound_from_string(name: String, volume = null) -> void:
	var path = "res://assets/sounds/%s.wav" % name
	
	var sound = load(path)
	if sound == null:
		push_error("Sound not found at path: " + path)
		return
	
	var player = AudioStreamPlayer.new()
	Engine.get_main_loop().root.add_child(player)
	
	player.stream = sound
	player.pitch_scale = randf_range(0.9, 1.1)
	if volume:
		player.volume_db = linear_to_db(volume)
	player.play()
	
	player.finished.connect(func():
		player.queue_free()
	)
