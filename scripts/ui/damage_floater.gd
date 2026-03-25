extends Label

@export var rise_px := 60.0
@export var duration := 0.8
@export var font_px := 46

func play(amount: int, color: Color = Color(0.92, 0.58, 0.06)) -> void:
	text = str(amount)
	modulate = color
	modulate.a = 1.0
	scale = Vector2.ONE
	add_theme_font_size_override("font_size", font_px)

	var start_pos := position
	var end_pos := start_pos + Vector2(0, -rise_px)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position", end_pos, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1.48, 1.48), duration * 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, duration).set_delay(duration * 0.15)
	tween.set_parallel(false)
	tween.tween_callback(queue_free)
