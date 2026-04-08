extends BallEffect
class_name BombTouchingEffect

@export var tolerance := 12.0


func _targets(ctx: BattleContext, source) -> Array:
	var out: Array = []
	for ball in ctx.touching_balls(source, tolerance):
		if ball.participates_in_level_merge():
			out.append(ball)
	return out


func can_trigger(ctx: BattleContext, source) -> bool:
	return _targets(ctx, source).size() > 0


func apply(ctx: BattleContext, source) -> void:
	for ball in _targets(ctx, source):
		ball.level *= 2
		ball.refresh()
	ctx.consume_ball(source)
	ctx.wake_playfield()
