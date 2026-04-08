extends BallEffect
class_name MagnetTouchingEffect

@export var tolerance := 25.0
@export var copies_per_target := 2
@export var min_targets := 1
@export var jitter := 8.0


func _targets(ctx: BattleContext, source) -> Array:
	var out: Array = []
	for ball in ctx.touching_balls(source, tolerance):
		if not ball.has_tag("magnet"):
			out.append(ball)
	return out


func can_trigger(ctx: BattleContext, source) -> bool:
	return _targets(ctx, source).size() >= min_targets

func apply(ctx: BattleContext, source) -> void:
	for ball in _targets(ctx, source):
		ctx.magnetize(ball, source)
