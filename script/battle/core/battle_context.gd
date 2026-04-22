extends RefCounted
class_name BattleContext

enum Phase { PLAY, RESOLVE }

const MAX_MANA_PIPES := 5
const MERGES_PER_MANA_PIPE := 5
var COMBO_TIMEOUT := 5.0

var controller
var phase := Phase.PLAY
var resolving_board := true
var mana_pipes := 0
var current_ball: BallBase = null
var merge_progress := 0
var battle_result_text := ""
var slow_mo_active := false
var combo := 0
var combo_timer := 0.0


func _init(p_controller = null) -> void:
	controller = p_controller
	reset_for_battle()


func reset_for_battle() -> void:
	phase = Phase.PLAY
	resolving_board = true
	mana_pipes = 0
	current_ball = null
	merge_progress = 0
	battle_result_text = ""
	slow_mo_active = false
	combo = 0
	combo_timer = 0.0


func start_turn() -> void:
	phase = Phase.PLAY
	resolving_board = true
	current_ball = null
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


func combo_multiplier() -> float:
	if combo < 3:
		return 1.0
	if combo < 5:
		return 1.1
	if combo < 7:
		return 1.3
	if combo < 10:
		return 1.6
	if combo < 13:
		return 2.0
	if combo < 16:
		return 2.4
	if combo < 20:
		return 2.7
	return 3


func combo_timer_ratio() -> float:
	if combo <= 0:
		return 0.0
	return clampf(combo_timer / COMBO_TIMEOUT, 0.0, 1.0)


func tick_combo(delta: float) -> void:
	if combo <= 0:
		return
	combo_timer -= delta
	if combo_timer <= 0.0:
		combo_timer = 0.0
		combo = 0
		COMBO_TIMEOUT = 5.0
	if controller != null:
		controller.sync_combo_hud()


func register_merge() -> void:
	combo += 1
	COMBO_TIMEOUT -= clampf(0.1 / (combo/2.0), 0.25, 5.0)
	combo_timer = COMBO_TIMEOUT
	if mana_pipes < MAX_MANA_PIPES:
		var progress_gain := maxi(1, int(combo_multiplier()))
		merge_progress += progress_gain
		while merge_progress >= MERGES_PER_MANA_PIPE and mana_pipes < MAX_MANA_PIPES:
			merge_progress -= MERGES_PER_MANA_PIPE
			mana_pipes = mini(mana_pipes + 1, MAX_MANA_PIPES)
	if controller != null:
		controller.sync_mana_hud()
		controller.sync_combo_hud()


func can_shoot() -> bool:
	return mana_pipes > 0


func can_spend_mana(amount: int) -> bool:
	return amount <= mana_pipes


func try_spend_mana(amount: int) -> bool:
	if not can_spend_mana(amount):
		return false
	mana_pipes -= amount
	if controller != null:
		controller.sync_mana_hud()
	return true


func try_consume_shot() -> bool:
	if mana_pipes <= 0:
		return false
	mana_pipes -= 1
	if controller != null:
		controller.sync_mana_hud()
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
