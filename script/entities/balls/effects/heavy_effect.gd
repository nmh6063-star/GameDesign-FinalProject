extends BallEffectBase
class_name HeavyEffect

@export var tolerance := 12.0
@export var max_damage := 500

var damage = 0



func _targets(ctx: BattleContext, source: BallBase) -> Array:
	var out: Array = []
	for ball in ctx.touching_balls(source, tolerance):
		if ball.is_elemental():
			out.append(ball)
	return out


func can_trigger(ctx: BattleContext, source: BallBase) -> bool:
	return _targets(ctx, source).size() >= 1


func apply(ctx: BattleContext, source: BallBase) -> void:
	for ball in _targets(ctx, source):
		damage += ball.level
		ctx.consume_ball(ball)
	if damage > max_damage:
		damage = max_damage
	source.level = damage
	source.get_node("Sprite2D").modulate = Color.from_hsv(0.0, 0.0, inverse_lerp(0, max_damage, damage))
