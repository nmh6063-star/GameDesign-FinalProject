extends BallEffect
class_name MagnetPullEffect

@export var pull_radius := 140.0
@export var pull_strength := 50.0


func _pull_targets(ctx: BattleContext, source) -> Array:
	var out: Array = []
	var radius_squared := pull_radius * pull_radius
	for ball in ctx.active_balls():
		if ball == source or not ball.has_tag("normal"):
			continue
		if source.global_position.distance_squared_to(ball.global_position) <= radius_squared:
			out.append(ball)
	return out


func can_trigger(ctx: BattleContext, source) -> bool:
	return false


func apply(ctx: BattleContext, source) -> void:
	pass


func tick(ctx: BattleContext, source) -> void:
	for ball in _pull_targets(ctx, source):
		var offset: Vector2 = source.global_position - ball.global_position
		if offset.length_squared() == 0.0:
			continue
		ball.apply_central_impulse(offset.normalized() * pull_strength)
