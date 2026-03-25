extends Resource
class_name BallBehavior

enum Kind { NORMAL, DUPLICATION, MULTIPLICATION, HEAL }

@export var kind: Kind = Kind.NORMAL

const _PATH := "res://script/ball/behaviors/ball_behavior.gd"


static func from_kind(k: Kind) -> BallBehavior:
	var scr := load(_PATH) as GDScript
	var b: BallBehavior = scr.new() as BallBehavior
	b.kind = k
	return b


func participates_in_level_merge() -> bool:
	return kind == Kind.NORMAL


func display_label(lv: int) -> String:
	match kind:
		Kind.DUPLICATION:
			return "D"
		Kind.MULTIPLICATION:
			return "M"
		Kind.HEAL:
			return "H"
		_:
			return str(lv)
