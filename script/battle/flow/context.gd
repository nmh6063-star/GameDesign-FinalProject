extends RefCounted
class_name BattleContext

var controller
var state


func _init(p_controller, p_state) -> void:
	controller = p_controller
	state = p_state


func active_balls() -> Array:
	return controller.active_balls()


func effect_balls() -> Array:
	return controller.effect_balls()


func active_enemy():
	return controller.active_enemy()


func are_touching(a, b, tolerance: float = 0.0) -> bool:
	var radius: float = a.get_radius() + b.get_radius() + tolerance
	return a.global_position.distance_squared_to(b.global_position) <= radius * radius


func touching_balls(source, tolerance: float = 0.0) -> Array:
	var out: Array = []
	for ball in active_balls():
		if ball != source and are_touching(source, ball, tolerance):
			out.append(ball)
	return out


func consume_ball(ball) -> void:
	controller.consume_ball(ball)


func duplicate_ball(source, offset: Vector2 = Vector2.ZERO):
	return controller.spawn_ball_copy(source, offset)


func wake_playfield() -> void:
	controller.wake_playfield()


func heal_player(amount: int) -> void:
	controller.heal_player(amount)


func damage_enemy(amount: int) -> void:
	controller.damage_enemy(amount)


func damage_player(amount: int) -> void:
	controller.damage_player(amount)


func burst(origin_global: Vector2, strength_scale: float = 1.0) -> void:
	controller.burst_knock_on_balls(origin_global, strength_scale)


func register_merge() -> void:
	state.register_merge()
	controller.sync_shoot_ammo_hud()
