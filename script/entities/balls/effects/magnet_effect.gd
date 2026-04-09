extends BallEffectBase
class_name MagnetEffect

const ZERO_EPSILON := 0.0001

@export var pull_radius := 140.0
@export var max_pull_speed := 250.0
@export_range(0.0, 1.0) var steer_factor := 0.2
@export var settle_radius := 6.0
@export var settle_padding := 2.0


func _pull_targets(ctx: BattleContext, source: BallBase, field_center: Vector2) -> Array:
	var out: Array = []
	var radius_squared := pull_radius * pull_radius
	for ball in ctx.active_balls():
		if ball == source or not ball.is_elemental():
			continue
		if field_center.distance_squared_to(ball.global_position) <= radius_squared:
			out.append(ball)
	return out


func can_trigger(ctx: BattleContext, source: BallBase) -> bool:
	return false


func apply(ctx: BattleContext, source: BallBase) -> void:
	pass


func _surface_target(source: BallBase, target: BallBase, field_center: Vector2) -> Vector2:
	var offset := target.global_position - field_center
	if offset.length_squared() <= ZERO_EPSILON:
		offset = Vector2.RIGHT
	var target_distance := source.get_radius() + target.get_radius() + settle_padding
	return field_center + offset.normalized() * target_distance


func tick(ctx: BattleContext, source: BallBase) -> void:
	if source.is_setup_ball():
		return
	var field_center: Vector2 = source.global_position
	for ball in _pull_targets(ctx, source, field_center):
		var target_position := _surface_target(source, ball, field_center)
		var offset: Vector2 = target_position - ball.global_position
		var distance_squared := offset.length_squared()
		if distance_squared <= ZERO_EPSILON:
			continue
		var distance_to_target := sqrt(distance_squared)
		if distance_to_target <= settle_radius:
			ball.global_position = target_position
			ball.linear_velocity = Vector2.ZERO
			ball.angular_velocity = 0.0
			continue
		var desired_velocity := offset.normalized() * max_pull_speed
		ball.sleeping = false
		ball.linear_velocity = ball.linear_velocity.lerp(desired_velocity, steer_factor)
