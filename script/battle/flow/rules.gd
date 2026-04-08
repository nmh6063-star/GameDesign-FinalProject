extends RefCounted
class_name BattleRules


func step_merge(ctx: BattleContext):
	var balls := ctx.active_balls()
	for i in range(balls.size()):
		var a = balls[i]
		for j in range(i + 1, balls.size()):
			var b = balls[j]
			if a.data.merge_rule.can_merge(ctx, a, b):
				a.data.merge_rule.resolve(ctx, a, b)
				ctx.register_merge()
				ctx.burst(a.global_position)
				return a
	return null


func resolve_ball_effects(ctx: BattleContext) -> void:
	while true:
		var applied := false
		for ball in ctx.active_balls():
			for effect in ball.data.effects:
				if effect.can_trigger(ctx, ball):
					effect.apply(ctx, ball)
					applied = true
					break
			if applied:
				break
		if not applied:
			return


func resolve_enemy_turn(ctx: BattleContext, enemy = null) -> void:
	enemy = ctx.active_enemy() if enemy == null else enemy
	if enemy == null or enemy.current_health <= 0:
		return
	for action in enemy.data.actions:
		if action.can_use(ctx, enemy):
			action.execute(ctx, enemy)
			return
