extends Control

@onready var text = $RichTextLabel
@onready var limit = get_node("/root/Main/Background/Limit")

var lastStatus = false
var timer = 10

func _physics_process(delta: float) -> void:
	if limit.touching:
		self.visible = true
	else:
		self.visible = false
	if lastStatus != limit.touching:
		lastStatus = limit.touching
		if limit.touching:
			text.text = str(timer)
			_pop_animation()

	
		
func _pop_animation() -> void:
	var tween := create_tween()
	if timer > 10:
		$Timer.start()
	tween.tween_property($RichTextLabel, "scale", Vector2(5.0, 5.0), 0.06).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property($RichTextLabel, "scale", (Vector2.ZERO), 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _on_timer_timeout() -> void:
	timer -= 1
	_pop_animation()
