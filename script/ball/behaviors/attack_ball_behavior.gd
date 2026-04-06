extends BallBehavior
class_name AttackBallBehavior


func participates_in_level_merge() -> bool:
	return true


func display_label(level: int) -> String:
	return str(level)


func display_color(level: int) -> Color:
	return Color(0.3 + 0.05 * level, 0.8 - 0.06 * level, 0.3)
