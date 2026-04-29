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
var enemy_statuses := {}
var player_statuses := {
	"shield": 0,
	"attack_bonus": 0,
	"reflect_hits": 0,
	"reflect_until_ms": 0,
	"resurrect_ready": false,
	"resurrect_used": false,
	"burn_stacks": 0,
	"freeze_stacks": 0,
}
var battle_flags := {
	"last_damage": 0,
	"last_effect_id": "",
	"time_slow_until_ms": 0,
	"sacrifice_pending": false,
}
var ball_statuses := {}

# Enemy whose attack is currently being redirected by Charm
var _charm_redirect_source: EnemyBase = null


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
	enemy_statuses.clear()
	ball_statuses.clear()
	player_statuses = {
		"shield": 0,
		"attack_bonus": 0,
		"reflect_hits": 0,
		"reflect_until_ms": 0,
		"resurrect_ready": false,
		"resurrect_used": false,
		"burn_stacks": 0,
		"freeze_stacks": 0,
	}
	battle_flags = {
		"last_damage": 0,
		"last_effect_id": "",
		"time_slow_until_ms": 0,
		"sacrifice_pending": false,
	}
	_charm_redirect_source = null


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


func spawn_ball(ball_id: String, origin_global: Vector2, impulse: Vector2 = Vector2.ZERO, rank: int = 1) -> BallBase:
	return controller.spawn_ball(ball_id, origin_global, impulse, rank) if controller != null else null


func drop_ball_in_box(ball_id: String, rank: int = 1) -> BallBase:
	return controller.drop_ball_in_box(ball_id, rank) if controller != null else null


func heal_player(amount: int) -> void:
	if controller != null:
		controller.heal_player(amount)


func damage_enemy(amount: int, enemy: EnemyBase = null) -> void:
	if controller != null:
		controller.damage_enemy(amount + int(player_statuses.get("attack_bonus", 0)), enemy, self)


func damage_player(amount: int) -> void:
	if controller != null:
		var reduced := _consume_player_shield(amount)
		if reduced > 0:
			controller.damage_player(reduced)


func burst(origin_global: Vector2, strength_scale: float = 1.0) -> void:
	if controller != null:
		controller.burst_knock_on_balls(origin_global, strength_scale)


func now_ms() -> int:
	return Time.get_ticks_msec()


func status_for_enemy(enemy: EnemyBase) -> Dictionary:
	if enemy == null:
		return {}
	var key := enemy.get_instance_id()
	if not enemy_statuses.has(key):
		enemy_statuses[key] = {
			"poison_stack": 0,
			"poison_strength": 0,
			"burn_stack": 0,
			"burn_strength": 0,
			"freeze_stack": 0,
			"freeze_until_ms": 0,
			"charm_stack": 0,
		}
	return enemy_statuses[key]


func add_enemy_status(enemy: EnemyBase, key: String, stack: int, strength: int = 0) -> void:
	if enemy == null:
		return
	var st := status_for_enemy(enemy)
	st[key + "_stack"] = int(st.get(key + "_stack", 0)) + max(0, stack)
	if strength > 0:
		st[key + "_strength"] = max(int(st.get(key + "_strength", 0)), strength)
	if key == "poison" and not st.has("poison_accum"):
		st["poison_accum"] = 0.0


func consume_enemy_stack(enemy: EnemyBase, key: String, amount: int = 1) -> void:
	var st := status_for_enemy(enemy)
	var k := key + "_stack"
	st[k] = max(0, int(st.get(k, 0)) - max(0, amount))


func tick_enemy_poison(delta: float) -> void:
	for enemy in _alive_enemies():
		var st := status_for_enemy(enemy)
		if int(st.get("poison_stack", 0)) <= 0:
			continue
		st["poison_accum"] = float(st.get("poison_accum", 0.0)) + max(0.0, delta)
		while float(st.get("poison_accum", 0.0)) >= 1.0 and int(st.get("poison_stack", 0)) > 0:
			st["poison_accum"] = float(st.get("poison_accum", 0.0)) - 1.0
			var dmg := int(st.get("poison_strength", 0))
			if dmg > 0:
				damage_enemy(dmg, enemy)
			st["poison_stack"] = max(0, int(st.get("poison_stack", 0)) - 1)


func on_enemy_attack_started(enemy: EnemyBase) -> bool:
	var st := status_for_enemy(enemy)
	if int(st.get("freeze_stack", 0)) > 0:
		return false
	if now_ms() <= int(st.get("freeze_until_ms", 0)):
		return false
	return true


func on_enemy_attack_resolved(enemy: EnemyBase) -> void:
	var st := status_for_enemy(enemy)
	if int(st.get("burn_stack", 0)) > 0:
		var burn := int(st.get("burn_strength", 0))
		if burn > 0:
			damage_enemy(burn, enemy)
		consume_enemy_stack(enemy, "burn", 1)
	if int(st.get("charm_stack", 0)) > 0:
		consume_enemy_stack(enemy, "charm", 1)


func consume_freeze_on_ball_drop() -> void:
	for enemy in _alive_enemies():
		var st := status_for_enemy(enemy)
		if int(st.get("freeze_stack", 0)) > 0:
			st["freeze_stack"] = max(0, int(st.get("freeze_stack", 0)) - 1)


func add_player_shield(amount: int) -> void:
	player_statuses["shield"] = int(player_statuses.get("shield", 0)) + max(0, amount)


func add_player_attack_bonus(amount: int) -> void:
	player_statuses["attack_bonus"] = int(player_statuses.get("attack_bonus", 0)) + max(0, amount)


func set_player_reflect_hits(hits: int) -> void:
	player_statuses["reflect_hits"] = max(0, hits)


func set_player_reflect_for_seconds(seconds: float) -> void:
	player_statuses["reflect_until_ms"] = now_ms() + int(seconds * 1000.0)


func set_resurrection_ready() -> void:
	player_statuses["resurrect_ready"] = true


func can_resurrect() -> bool:
	return bool(player_statuses.get("resurrect_ready", false)) and not bool(player_statuses.get("resurrect_used", false))


func mark_resurrect_used() -> void:
	player_statuses["resurrect_used"] = true


func should_reflect_damage() -> bool:
	if int(player_statuses.get("reflect_hits", 0)) > 0:
		player_statuses["reflect_hits"] = int(player_statuses.get("reflect_hits", 0)) - 1
		return true
	return now_ms() <= int(player_statuses.get("reflect_until_ms", 0))


func has_reflect_active() -> bool:
	return int(player_statuses.get("reflect_hits", 0)) > 0 or now_ms() <= int(player_statuses.get("reflect_until_ms", 0))


func set_enemy_freeze_seconds(enemy: EnemyBase, seconds: float) -> void:
	if enemy == null:
		return
	var st := status_for_enemy(enemy)
	st["freeze_until_ms"] = now_ms() + int(seconds * 1000.0)


func set_charm_redirect(enemy: EnemyBase) -> void:
	_charm_redirect_source = enemy


func clear_charm_redirect() -> void:
	_charm_redirect_source = null


func charm_redirect_source() -> EnemyBase:
	return _charm_redirect_source


func _consume_player_shield(amount: int) -> int:
	var shield := int(player_statuses.get("shield", 0))
	if shield <= 0 or amount <= 0:
		return amount
	var absorbed := mini(shield, amount)
	player_statuses["shield"] = shield - absorbed
	return amount - absorbed


func _alive_enemies() -> Array:
	var out: Array = []
	if controller == null:
		return out
	if not controller.has_method("_alive_enemy_slots"):
		return out
	for slot in controller._alive_enemy_slots():
		if slot != null and slot.enemy != null and slot.enemy.is_alive():
			out.append(slot.enemy)
	return out


func ball_status_for(ball: BallBase) -> Dictionary:
	if ball == null:
		return {}
	var key := ball.get_instance_id()
	if not ball_statuses.has(key):
		ball_statuses[key] = {
			"attack_mult": 1.0,
			"trigger_twice": false,
			"size_mult": 1.0,
		}
	return ball_statuses[key]


func set_ball_status(ball: BallBase, key: String, value) -> void:
	if ball == null:
		return
	var st := ball_status_for(ball)
	st[key] = value
