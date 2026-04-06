extends BallBehavior
class_name SpecialBallBehavior

enum Effect { DUPLICATION, MULTIPLICATION, HEAL }

@export var effect: Effect = Effect.DUPLICATION


func participates_in_level_merge() -> bool:
	return false


func display_label(_level: int) -> String:
	match effect:
		Effect.DUPLICATION:
			return "D"
		Effect.MULTIPLICATION:
			return "M"
		Effect.HEAL:
			return "H"
		_:
			return "?"


func display_color(_level: int) -> Color:
	match effect:
		Effect.DUPLICATION:
			return Color(0.75, 0.35, 0.95)
		Effect.MULTIPLICATION:
			return Color(0.25, 0.55, 1.0)
		Effect.HEAL:
			return Color(0.35, 0.92, 0.55)
		_:
			return Color.WHITE
