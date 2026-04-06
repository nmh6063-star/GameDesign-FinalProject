extends Resource
class_name BallBehavior

enum Kind { NORMAL, DUPLICATION, MULTIPLICATION, HEAL }

const _PATH_ATTACK := "res://script/ball/behaviors/attack_ball_behavior.gd"
const _PATH_SPECIAL := "res://script/ball/behaviors/special_ball_behavior.gd"


func participates_in_level_merge() -> bool:
	return false


func display_label(level: int) -> String:
	return str(level)


func display_color(level: int) -> Color:
	return Color(0.5, 0.5, 0.5)


static func from_kind(k: Kind) -> BallBehavior:
	if k == Kind.NORMAL:
		return load(_PATH_ATTACK).new() as BallBehavior
	var inst: Resource = load(_PATH_SPECIAL).new() as Resource
	match k:
		Kind.DUPLICATION:
			inst.set("effect", 0)
		Kind.MULTIPLICATION:
			inst.set("effect", 1)
		Kind.HEAL:
			inst.set("effect", 2)
		_:
			pass
	return inst as BallBehavior
