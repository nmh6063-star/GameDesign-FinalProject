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
	"dot_damage_heal_ratio": 0.0,
	"dot_triggers_twice": false,
}
var battle_flags := {
	"last_damage": 0,
	"last_effect_id": "",
	"time_slow_until_ms": 0,
	"sacrifice_pending": false,
	"max_combo_reached": 0,
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
		"dot_damage_heal_ratio": 0.0,
		"dot_triggers_twice": false,
	}
	battle_flags = {
		"last_damage": 0,
		"last_effect_id": "",
		"time_slow_until_ms": 0,
		"sacrifice_pending": false,
		"max_combo_reached": 0,
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
	if combo > int(battle_flags.get("max_combo_reached", 0)):
		battle_flags["max_combo_reached"] = combo
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


func drop_zone_global() -> Vector2:
	return controller.drop_zone_global() if controller != null else Vector2.ZERO


func drop_ball_in_box(ball_id: String, rank: int = 1) -> BallBase:
	return controller.drop_ball_in_box(ball_id, rank) if controller != null else null


## Drop a ball with the player's current element textures at a specific X inside the box.
func drop_element_ball_in_box(rank: int, x: float = INF) -> BallBase:
	if controller == null or not controller.has_method("drop_element_ball_in_box"):
		return null
	return controller.drop_element_ball_in_box(rank, x)


func heal_player(amount: int) -> void:
	if controller != null:
		controller.heal_player(amount)


## Direct damage (benefits from attack_bonus, poison_apple, and clone stacks).
func damage_enemy(amount: int, enemy: EnemyBase = null) -> void:
	if controller == null:
		return
	var base := amount + int(player_statuses.get("attack_bonus", 0))
	# Time Stop: struck enemies take 50% more damage.
	var target_for_check := enemy if enemy != null else active_enemy()
	if target_for_check != null:
		var ts_st := status_for_enemy(target_for_check)
		if now_ms() <= int(ts_st.get("time_stop_until_ms", 0)):
			base = int(round(float(base) * 1.5))
	# Poison Apple: +10% per charge, consumes charge, costs a bit of self-HP
	var pa := int(player_statuses.get("poison_apple_charges", 0))
	if pa > 0:
		base = int(round(base * 1.1))
		player_statuses["poison_apple_charges"] = pa - 1
		_damage_player_raw(2)
	# Clone stacks: each stack doubles all direct damage (max 4 stacks)
	var clones := int(player_statuses.get("clone_stacks", 0))
	for _i in range(mini(clones, 4)):
		base *= 2
	controller.damage_enemy(base, enemy, self)
	battle_flags["last_damage"] = amount
	# Poison Rain: each direct hit adds 2 poison stacks to the struck enemy.
	if int(battle_flags.get("poison_rain_shoots", 0)) > 0:
		var target := enemy if enemy != null else active_enemy()
		if target != null and is_instance_valid(target) and target.is_alive():
			add_enemy_status(target, "poison", 2)


## Player takes damage. During Time Drift, incoming damage is stored
## and will be reflected back to enemies as continuous DOT.
func damage_player(amount: int) -> void:
	if bool(battle_flags.get("time_drift_active", false)):
		battle_flags["time_drift_stored"] = \
				int(battle_flags.get("time_drift_stored", 0)) + amount
		return
	_damage_player_raw(amount)


## Damage to player that bypasses Time Drift storage (e.g. self-inflicted costs).
func _damage_player_raw(amount: int) -> void:
	if controller != null:
		var reduced := _consume_player_shield(amount)
		if reduced > 0:
			controller.damage_player(reduced)


## DOT damage: bypasses attack_bonus and clone multipliers.
func _damage_enemy_dot(amount: int, enemy: EnemyBase) -> void:
	if controller == null or enemy == null or amount <= 0:
		return
	var repeat := 2 if bool(player_statuses.get("dot_triggers_twice", false)) else 1
	var total_dealt := 0
	for _i in range(repeat):
		controller.damage_enemy(amount, enemy, self)
		total_dealt += amount
	var ratio := float(player_statuses.get("dot_damage_heal_ratio", 0.0))
	if ratio > 0.0 and total_dealt > 0:
		var heal_amt := maxi(1, int(round(float(total_dealt) * ratio)))
		heal_player(heal_amt)


## Copies poison/burn/charm stacks and remaining freeze duration from one enemy onto another (additive).
func copy_enemy_debuffs(from_enemy: EnemyBase, to_enemy: EnemyBase) -> void:
	if from_enemy == null or to_enemy == null or from_enemy == to_enemy:
		return
	var sf := status_for_enemy(from_enemy)
	var st := status_for_enemy(to_enemy)
	st["poison_stack"] = int(st.get("poison_stack", 0)) + int(sf.get("poison_stack", 0))
	st["burn_stack"] = int(st.get("burn_stack", 0)) + int(sf.get("burn_stack", 0))
	st["charm_stack"] = int(st.get("charm_stack", 0)) + int(sf.get("charm_stack", 0))
	var now := now_ms()
	var src_until := int(sf.get("freeze_until_ms", 0))
	var src_remain := maxi(0, src_until - now)
	if src_remain > 0:
		var tgt_base := maxi(now, int(st.get("freeze_until_ms", 0)))
		st["freeze_until_ms"] = tgt_base + src_remain


func spread_debuffs_from_active_to_random_other() -> void:
	var from_enemy := active_enemy()
	if from_enemy == null or not from_enemy.is_alive():
		return
	var candidates: Array = []
	for e in _alive_enemies():
		if e != from_enemy and e.is_alive():
			candidates.append(e)
	if candidates.is_empty():
		return
	var to_enemy: EnemyBase = candidates[randi() % candidates.size()]
	copy_enemy_debuffs(from_enemy, to_enemy)


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
			"burn_stack": 0,
			"burn_accum": 0.0,
			"freeze_until_ms": 0,
			"charm_stack": 0,
			"time_stop_until_ms": 0,
		}
	return enemy_statuses[key]


## Stacks = total damage charges. Freeze: each stack = 1 second freeze (additive).
func add_enemy_status(enemy: EnemyBase, key: String, stack: int, _strength: int = 0) -> void:
	if enemy == null:
		return
	var st := status_for_enemy(enemy)
	if key == "freeze":
		var current_until := maxi(now_ms(), int(st.get("freeze_until_ms", 0)))
		st["freeze_until_ms"] = current_until + stack * 1000
	else:
		st[key + "_stack"] = int(st.get(key + "_stack", 0)) + max(0, stack)


func consume_enemy_stack(enemy: EnemyBase, key: String, amount: int = 1) -> void:
	var st := status_for_enemy(enemy)
	var k := key + "_stack"
	st[k] = max(0, int(st.get(k, 0)) - max(0, amount))


## Burn ticks every second
func tick_enemy_burn(delta: float) -> void:
	for enemy in _alive_enemies():
		var st := status_for_enemy(enemy)
		if int(st.get("burn_stack", 0)) <= 0:
			continue
		st["burn_accum"] = float(st.get("burn_accum", 0.0)) + maxf(0.0, delta)
		while float(st.get("burn_accum", 0.0)) >= 1.0 and int(st.get("burn_stack", 0)) > 0:
			st["burn_accum"] -= 1.0
			var burn_stacks := int(st.get("burn_stack", 0))
			_damage_enemy_dot(burn_stacks, enemy)
			st["burn_stack"] = burn_stacks - 1


## Poison fires before each enemy attack (1 dmg, 1 stack consumed).
## During Poison Rain the stack GROWS instead of shrinking.
## Returns false if enemy is frozen (attack blocked).
func on_enemy_attack_started(enemy: EnemyBase) -> bool:
	var st := status_for_enemy(enemy)
	if now_ms() <= int(st.get("freeze_until_ms", 0)):
		return false
	if now_ms() <= int(st.get("time_stop_until_ms", 0)):
		return false
	var poison_stacks := int(st.get("poison_stack", 0))
	if poison_stacks > 0:
		_damage_enemy_dot(poison_stacks, enemy)
		if int(battle_flags.get("poison_rain_shoots", 0)) > 0:
			st["poison_stack"] = poison_stacks + 1  # Rain: stacks bloom
		else:
			st["poison_stack"] = poison_stacks - 1
	return true


## Called after enemy resolves its attack. Charm stack consumed here.
func on_enemy_attack_resolved(enemy: EnemyBase) -> void:
	var st := status_for_enemy(enemy)
	if int(st.get("charm_stack", 0)) > 0:
		consume_enemy_stack(enemy, "charm", 1)


func consume_freeze_on_ball_drop() -> void:
	pass


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
