extends RefCounted
class_name BattleResolver


func resolve_frame(ctx: BattleContext) -> void:
	_resolve_one_merge(ctx)
	_resolve_triggered_ball_behaviors(ctx)
	_tick_ball_behaviors(ctx)


func _resolve_one_merge(ctx: BattleContext) -> BallBase:
	var balls := ctx.active_balls()
	for i in range(balls.size()):
		var ball := balls[i] as BallBase
		for j in range(i + 1, balls.size()):
			var other := balls[j] as BallBase
			if ball.check_merge(ctx, other):
				ball.merge_with(ctx, other)
				return ball
	return null


func _resolve_triggered_ball_behaviors(ctx: BattleContext) -> void:
	while true:
		var applied := false
		for ball in ctx.active_balls():
			if ball.try_apply_board_behavior(ctx):
				applied = true
				break
		if not applied:
			return


func _tick_ball_behaviors(ctx: BattleContext) -> void:
	for ball in ctx.effect_balls():
		ball.tick_board_behavior(ctx)
