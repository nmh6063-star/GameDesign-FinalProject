extends BallEffectBase
class_name VirusEffect

@export var tolerance := 12.0
@export var max_damage := 500
@export var blink_speed: float = 10.0
@export var min_alpha: float = 0.35

@export var first_pass: float = 3
@export var second_pass: float = 5

@export var jitter := 8.0

var currentTouching = []

const ARMED_AT_META := "bomb_armed_at"

func _targets(ctx: BattleContext, source: BallBase) -> Array:
	var out: Array = []
	#for ball in ctx.touching_balls(source, tolerance):
	#	if ball.is_elemental():
	#		out.append(ball)
	return out


func can_trigger(ctx: BattleContext, source: BallBase) -> bool:
	return _targets(ctx, source).size() >= 1


func apply(ctx: BattleContext, source: BallBase) -> void:
	pass
	#for ball in _targets(ctx, source):
		#damage += ball.rank
		#ctx.consume_ball(ball)
	#if damage > max_damage:
	#	damage = max_damage
	#source.rank = damage
	#source.get_node("Sprite2D").modulate = Color.from_hsv(0.0, 0.0, inverse_lerp(0, max_damage, damage))
	
func tick(ctx: BattleContext, source: BallBase) -> void:
	#I gave up, someone else can look at this
	pass
	var currentSet = []
	var elapsed: float = (Time.get_ticks_msec()) / 1000.0
	for ball in ctx.active_balls():
		if ball == source:
			for b in ctx.touching_balls(ball, tolerance):
				if b.data.id != "ball_virus" and !b.is_queued_for_deletion():
					if !currentSet.has(b):
						currentSet.append(b)
					for base in currentTouching:
						var found = false
						if base[0] == b:
							found = true
							break
						if !found:
							currentTouching.append([b, elapsed, elapsed])
							print("ADD")
	var index = 0
	for b in currentSet:
		var ball = null
		for base in currentTouching:
			if base[0] == b:
				ball = base
		if !ball[0]:
			currentTouching.erase(ball)
			print("deleted")
			continue
		if ball[0].is_queued_for_deletion() or not ball[0].visible:
			continue
		if ball[0].is_setup_ball():
			ball[0].modulate = Color.WHITE
			continue
		if elapsed-ball[2] >= first_pass:
			ball[1] = elapsed
			print("resetting time")
		ball[2] = elapsed
		if ball[2]-ball[1] >= first_pass:
			ctx.spawn_ball("ball_virus", ball[0].global_position, Vector2.ZERO, randi_range(1, 2))
			ctx.consume_ball(ball[0])
			currentTouching.remove_at(index)
			print("ball created from")
			print(source)
		ball[0].modulate = Color(1, 1, 1, _blink_alpha(elapsed))
		index += 1
		print(ball[0])
		print(ball[1])
		print(ball[2])
		print("WHYYYY")


func _blink_alpha(elapsed: float) -> float:
	var phase: float = 0.5 + 0.5 * sin(elapsed * TAU * blink_speed)
	return lerpf(min_alpha, 1.0, phase)
