extends BallEffect
class_name ExplodingTouchingEffect

@export var tolerance := 12.0
@export var copies_per_target := 2
@export var min_targets := 1
@export var jitter := 8.0


func _targets(ctx: BattleContext, source) -> Array:
	var out: Array = []
	for ball in ctx.active_balls():
		if ball.exploded:
			out.append(ball)
	return out


func can_trigger(ctx: BattleContext, source) -> bool:
	return _targets(ctx, source).size() >= min_targets


func apply(ctx: BattleContext, source) -> void:
	for ball in _targets(ctx, source):
		for _copy in range(copies_per_target):
			ctx.explode_ball(
				ball,
				Vector2(randf_range(-jitter, jitter), randf_range(-jitter, jitter))
			)
	ctx.consume_ball(source)
	ctx.wake_playfield()
