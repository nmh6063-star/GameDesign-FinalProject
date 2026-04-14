extends BallEffectBase
class_name MultiplyEffect

@export var tolerance := 12.0


func _targets(ctx: BattleContext, source: BallBase) -> Array:
	var out: Array = []
	for ball in ctx.touching_balls(source, tolerance):
		if ball.is_elemental():
			out.append(ball)
	return out


func can_trigger(ctx: BattleContext, source: BallBase) -> bool:
	return _targets(ctx, source).size() > 0


func apply(ctx: BattleContext, source: BallBase) -> void:
	for ball in _targets(ctx, source):
		ball.multiply_level()
	ctx.consume_ball(source)
