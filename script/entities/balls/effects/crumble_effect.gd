extends BallEffectBase
class_name CrumbleEffect

const ZERO_EPSILON := 0.0001

@export var ball_spawns := 6

func can_trigger(ctx: BattleContext, source: BallBase) -> bool:
	return false


func apply(ctx: BattleContext, source: BallBase) -> void:
	pass

func on_shot(_ctx: BattleContext, _source: BallBase) -> void:
	for i in range(ball_spawns):
		_ctx.spawn_ball("ball_normal", _source.global_position, Vector2.ZERO, randi_range(1, 2))
	_ctx.consume_ball(_source)
