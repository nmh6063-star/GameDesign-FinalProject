extends RefCounted
class_name BattleContext

enum Phase { PLAY, RESOLVE }

const MAX_BULLETS := 5
const MERGES_PER_BULLET := 5

var controller
var phase := Phase.PLAY
var resolving_board := true
var player_energy_max := 1000
var player_energy := 1000
var current_ball: BallBase = null
var merge_progress := 0
var bullets := 0
var battle_result_text := ""


func _init(p_controller = null) -> void:
	controller = p_controller
	reset_for_battle()


func reset_for_battle() -> void:
	phase = Phase.PLAY
	resolving_board = true
	player_energy = player_energy_max
	current_ball = null
	merge_progress = 0
	bullets = 0
	battle_result_text = ""


func start_turn() -> void:
	phase = Phase.PLAY
	resolving_board = true
	current_ball = null
	player_energy = min(player_energy + 5, player_energy_max)


func begin_resolution() -> void:
	phase = Phase.RESOLVE
	resolving_board = true


func lock_resolution() -> void:
	resolving_board = false


func clear_battle_result() -> void:
	battle_result_text = ""


func finish_battle(text: String) -> void:
	battle_result_text = text


func has_battle_result() -> bool:
	return battle_result_text != ""


func register_merge() -> void:
	if bullets < MAX_BULLETS:
		merge_progress += 1
		if merge_progress >= MERGES_PER_BULLET:
			merge_progress = 0
			bullets = mini(bullets + 1, MAX_BULLETS)
	if controller != null:
		controller.sync_shoot_ammo_hud()


func can_shoot() -> bool:
	return bullets > 0


func try_consume_shot() -> bool:
	if bullets <= 0:
		return false
	bullets -= 1
	return true


func active_balls() -> Array:
	return controller.active_balls() if controller != null else []


func effect_balls() -> Array:
	return controller.effect_balls() if controller != null else []


func active_enemy() -> EnemyBase:
	return controller.active_enemy() if controller != null else null


func are_touching(a: BallBase, b: BallBase, tolerance: float = 0.0) -> bool:
	var radius: float = a.get_radius() + b.get_radius() + tolerance
	return a.global_position.distance_squared_to(b.global_position) <= radius * radius


func touching_balls(source: BallBase, tolerance: float = 0.0) -> Array:
	var out: Array = []
	for ball in active_balls():
		if ball != source and are_touching(source, ball, tolerance):
			out.append(ball)
	return out


func consume_ball(ball: BallBase) -> void:
	if controller != null:
		controller.consume_ball(ball, self)


func duplicate_ball(source: BallBase, offset: Vector2 = Vector2.ZERO) -> BallBase:
	return controller.spawn_ball_copy(source, offset) if controller != null else null


func spawn_ball(ball_id: String, origin_global: Vector2, impulse: Vector2 = Vector2.ZERO, level: int = 1) -> BallBase:
	return controller.spawn_ball(ball_id, origin_global, impulse, level) if controller != null else null


func drop_ball_in_box(ball_id: String, level: int = 1) -> BallBase:
	return controller.drop_ball_in_box(ball_id, level) if controller != null else null


func heal_player(amount: int) -> void:
	if controller != null:
		controller.heal_player(amount)


func damage_enemy(amount: int, enemy: EnemyBase = null) -> void:
	if controller != null:
		controller.damage_enemy(amount, enemy, self)


func damage_player(amount: int) -> void:
	if controller != null:
		controller.damage_player(amount)


func burst(origin_global: Vector2, strength_scale: float = 1.0) -> void:
	if controller != null:
		controller.burst_knock_on_balls(origin_global, strength_scale)
