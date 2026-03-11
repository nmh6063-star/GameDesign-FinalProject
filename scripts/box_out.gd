extends StaticBody2D

@export var cup_angle_degrees: float = 360.0
@export var duration: float = 2.4

func rotate_cup() -> void:
	var end := rotation - deg_to_rad(cup_angle_degrees)
	var tween := create_tween()
	tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "rotation", end, duration)
