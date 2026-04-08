extends BallEffect
class_name HeavyTouchingEffect

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
	var counter = 0
	for ball in _targets(ctx, source):
		counter += ball.level
		ctx.consume_ball(ball)
	source.level += counter
	ctx.wake_playfield()
