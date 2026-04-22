extends BallEffectBase
class_name ExplodeEffect

const ARMED_AT_META := "bomb_armed_at"

@export var blast_radius: float = 60.0
@export var fuse_seconds: float = 3.0
@export var blink_speed: float = 10.0
@export var min_alpha: float = 0.35

var inRadius = []
var inst


func can_trigger(_ctx: BattleContext, _source: BallBase) -> bool:
	return false


func apply(_ctx: BattleContext, _source: BallBase) -> void:
	pass

func tick(ctx: BattleContext, source: BallBase) -> void:
	if source.get_children().size() < 5:
		inst = Area2D.new()
		inst.position = source.get_node("Sprite2D").position
		source.add_child(inst)
		var collision = CollisionShape2D.new()
		inst.add_child(collision)
		var circle_shape = CircleShape2D.new()
		circle_shape.radius = 50.0
		collision.shape = circle_shape
		inst.body_entered.connect(_on_body_entered)
	if source.is_queued_for_deletion() or not source.visible:
		return
	if source.is_setup_ball():
		source.modulate = Color.WHITE
		return
	var armed_at: int = _armed_at(source)
	if armed_at == 0:
		armed_at = Time.get_ticks_msec()
		source.set_meta(ARMED_AT_META, armed_at)
	var elapsed: float = (Time.get_ticks_msec() - armed_at) / 1000.0
	source.modulate = Color(1, 1, 1, _blink_alpha(elapsed))
	if elapsed >= fuse_seconds:
		_explode(ctx, source)


func _armed_at(source: BallBase) -> int:
	return int(source.get_meta(ARMED_AT_META, 0))


func _blink_alpha(elapsed: float) -> float:
	var phase: float = 0.5 + 0.5 * sin(elapsed * TAU * blink_speed)
	return lerpf(min_alpha, 1.0, phase)


func _explode(ctx: BattleContext, source: BallBase) -> void:
	var victims: Array = [source]
	var radius_squared: float = blast_radius * blast_radius
	var damage = 0
	for ball in ctx.active_balls():
		if ball == source or ball.is_queued_for_deletion():
			continue
		#if source.global_position.distance_squared_to(ball.global_position) <= radius_squared:
		#	victims.append(ball)
		if ball in inRadius:
			victims.append(ball)
			damage += ball.level
	for ball in victims:
		ctx.consume_ball(ball)
	source.remove_child(inst)

func _on_body_entered(body):
	inRadius.append(body)

func _on_body_exited(body):
	inRadius.erase(body)
	
