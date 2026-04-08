extends BallEffect
class_name HealTouchingEffect

@export var tolerance := 12.0


func _targets(ctx: BattleContext, source) -> Array:
	var out: Array = []
	for ball in ctx.touching_balls(source, tolerance):
		if ball.has_tag("normal"):
			out.append(ball)
	return out


func can_trigger(ctx: BattleContext, source) -> bool:
	return _targets(ctx, source).size() > 0


func apply(ctx: BattleContext, source) -> void:
	var heal_amount := 0
	for ball in _targets(ctx, source):
		heal_amount += ball.level
		ctx.consume_ball(ball)
	ctx.consume_ball(source)
	ctx.heal_player(heal_amount)
	ctx.wake_playfield()
