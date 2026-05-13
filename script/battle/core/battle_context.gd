extends RefCounted
class_name BattleContext

enum Phase { PLAY, RESOLVE }

const MAX_MANA_PIPES := 3
const MERGES_PER_MANA_PIPE := 10
var COMBO_TIMEOUT := 5.0
var BACK_TO_BACK_TIMEOUT := 0.25

var controller
var phase := Phase.PLAY
var resolving_board := true
var mana_pipes := 0
var current_ball: BallBase = null
var merge_progress := 0
var battle_result_text := ""
var slow_mo_active := false
var combo := 0
var back2back := 0
var combo_timer := 0.0
var b2b_timer := BACK_TO_BACK_TIMEOUT
var enemy_statuses := {}
var internal_combo_track = 0
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
# Guard to prevent infinite recursion in thunder chain propagation
var _thunder_propagating := false

const sound := preload("res://script/game_manager/sound_manager.gd")


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
	internal_combo_track = 0
	combo_timer = 0.0
	back2back = 0
	b2b_timer = 0.0
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
		"direct_damage_heal_ratio": 0.0,
		"second_wind_ready": false,
		"second_wind_main_used": false,
		"second_wind_cooldown": false,
	}
	battle_flags = {
		"last_damage": 0,
		"last_effect_id": "",
		"time_slow_until_ms": 0,
		"sacrifice_pending": false,
		"max_combo_reached": 0,
	}
	_charm_redirect_source = null
	_thunder_propagating = false
	PlayerState.reset_battle_damage_stats()


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
	return 1.0 + snapped(float(combo) / 7.0, 0.01)
	"""
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
	"""


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
		internal_combo_track = 0
		COMBO_TIMEOUT = 5.0
	if controller != null:
		controller.sync_combo_hud()

func tick_b2b(delta: float) -> void:
	if back2back <= 0:
		return
	b2b_timer -= delta
	if b2b_timer <= 0.0:
		b2b_timer = 0
		back2back = 0
	
func create_floating_text(text: int, global_pos: Vector2):
	var label = Label.new()
	
	label.text = str(text) + "x"
	#remember to change font
	#label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", text * 5.0)
	label.add_theme_color_override("font_color", Color.WHITE)
	
	# Yellow outline/highlight
	label.add_theme_color_override("font_outline_color", Color.YELLOW)
	label.add_theme_constant_override("outline_size", 3)
	
	label.z_index = 100
	
	label.modulate = Color(1, 1, 1, 1)
	if Engine.get_main_loop().root.get_node_or_null("Tutorial"):
		Engine.get_main_loop().root.get_node("Tutorial").add_child(label)
	else:
		Engine.get_main_loop().root.get_node("Main").add_child(label)
	
	# Wait for the label to size itself
	await Engine.get_main_loop().process_frame
	
	# Center the text on the position
	label.global_position = global_pos - (label.size / 2)
	
	# Create tween
	var tween = Engine.get_main_loop().create_tween()
	
	# Move upward
	tween.parallel().tween_property(
		label,
		"global_position:y",
		label.global_position.y - 50,
		1.0
	)
	
	# Fade out
	tween.parallel().tween_property(
		label,
		"modulate:a",
		0.0,
		1.0
	)
	
	# Delete when finished
	tween.finished.connect(func():
		label.queue_free()
	)

func register_merge(ball: Node2D) -> void:
	sound.play_sound_from_string("merge", null, false, true, float(back2back) / 10.0)
	combo += 1
	internal_combo_track += 1
	COMBO_TIMEOUT -= clampf(0.1 / (float(combo)/2.0), 0.25, 5.0)
	combo_timer = COMBO_TIMEOUT
	back2back += 1
	b2b_timer = BACK_TO_BACK_TIMEOUT
	if(back2back > 1):
		combo += back2back
		internal_combo_track += back2back
		create_floating_text(back2back, ball.global_position)
	if combo > int(battle_flags.get("max_combo_reached", 0)):
		battle_flags["max_combo_reached"] = combo
	"""
	if mana_pipes < MAX_MANA_PIPES:
		var progress_gain := maxi(1, int(combo_multiplier()))
		merge_progress += progress_gain
		while merge_progress >= MERGES_PER_MANA_PIPE and mana_pipes < MAX_MANA_PIPES:
			merge_progress -= MERGES_PER_MANA_PIPE
			mana_pipes = mini(mana_pipes + 1, MAX_MANA_PIPES)
	"""
	if controller != null:
		controller.sync_mana_hud()
		controller.sync_combo_hud()
	# Poison Rain: each board merge adds +3 poison stacks to all living enemies.
	if int(battle_flags.get("poison_rain_shoots", 0)) > 0:
		for e in _alive_enemies():
			add_enemy_status(e, "poison", 3)


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
	# Weakness Brand: marked target takes 30% more direct damage
	var actual_target := enemy if enemy != null else active_enemy()
	if actual_target != null:
		var wb := int(status_for_enemy(actual_target).get("weakness_brand_shoots", 0))
		if wb > 0:
			base = int(round(float(base) * 1.30))
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
	# Lifesteal Field: heal 10% of direct damage dealt
	var ls := float(player_statuses.get("direct_damage_heal_ratio", 0.0))
	if ls > 0.0:
		var ls_heal := maxi(1, int(round(float(base) * ls)))
		heal_player(ls_heal)
	# Accumulate shoot damage for Tide Turner
	battle_flags["shoot_damage_acc"] = int(battle_flags.get("shoot_damage_acc", 0)) + base
	# Thunder chain: the struck enemy's stacks echo damage to all other thundered enemies
	if actual_target != null:
		_propagate_thunder(base, actual_target)


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
	# Fragile: +20% damage taken per stack (cleared at end of shoot)
	var fragile := int(battle_flags.get("fragile_stacks", 0))
	if fragile > 0:
		amount = int(round(float(amount) * (1.0 + 0.2 * float(fragile))))
	# Gatekeeper: convert a portion of each hit into Shield (ratio set when equipped)
	var gk := int(battle_flags.get("gatekeeper_charges", 0))
	if gk > 0:
		var gk_ratio := float(battle_flags.get("gatekeeper_ratio", 0.25))
		var shield_gain := int(round(float(amount) * gk_ratio))
		amount -= shield_gain
		add_player_shield(shield_gain)
		battle_flags["gatekeeper_charges"] = gk - 1
	if controller != null:
		var reduced := _consume_player_shield(amount)
		if reduced > 0:
			controller.damage_player(reduced)


## Directly reduces player HP, bypassing shield, Gatekeeper, and Fragile.
## Used for self-inflicted costs that are conceptually "internal" (e.g. Fortress).
## Cannot reduce HP below 1.
func _damage_player_hp_only(amount: int) -> void:
	if controller == null or amount <= 0:
		return
	var safe := mini(amount, PlayerState.player_health - 1)
	if safe <= 0:
		return
	PlayerState.damage(safe)
	if controller.has_method("_sync_player_bar_public"):
		controller._sync_player_bar_public()


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
	# Thunder chain: DOT damage also propagates through thunder links
	if not _thunder_propagating and total_dealt > 0:
		_propagate_thunder(total_dealt, enemy)


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
			"thunder_stack": 0,
		}
	return enemy_statuses[key]


## Stacks = total damage charges. Freeze: each stack = 1 second freeze (additive).
## weakness_brand stores remaining shoot count directly (not "_stack" suffix).
func add_enemy_status(enemy: EnemyBase, key: String, stack: int, _strength: int = 0) -> void:
	if enemy == null:
		return
	var st := status_for_enemy(enemy)
	if key == "freeze":
		var current_until := maxi(now_ms(), int(st.get("freeze_until_ms", 0)))
		st["freeze_until_ms"] = current_until + stack * 1000
	elif key == "weakness_brand":
		# Overwrite (not additive) — only one brand at a time
		st["weakness_brand_shoots"] = max(0, stack)
	else:
		st[key + "_stack"] = int(st.get(key + "_stack", 0)) + max(0, stack)


func consume_enemy_stack(enemy: EnemyBase, key: String, amount: int = 1) -> void:
	var st := status_for_enemy(enemy)
	var k := key + "_stack"
	st[k] = max(0, int(st.get(k, 0)) - max(0, amount))


## Burn ticks every 1 second; each tick deals current stacks as damage then removes
## max(1, round(25% of stacks)) stacks.
func tick_enemy_burn(delta: float) -> void:
	const BURN_TICK_SEC := 1.0
	for enemy in _alive_enemies():
		var st := status_for_enemy(enemy)
		if int(st.get("burn_stack", 0)) <= 0:
			continue
		st["burn_accum"] = float(st.get("burn_accum", 0.0)) + maxf(0.0, delta)
		while float(st.get("burn_accum", 0.0)) >= BURN_TICK_SEC and int(st.get("burn_stack", 0)) > 0:
			st["burn_accum"] -= BURN_TICK_SEC
			var burn_stacks := int(st.get("burn_stack", 0))
			_damage_enemy_dot(burn_stacks, enemy)
			var lost := maxi(1, int(round(float(burn_stacks) * 0.25)))
			st["burn_stack"] = maxi(0, burn_stacks - lost)


## Poison fires before each enemy attack (1 dmg, 1 stack consumed).
## Returns false if enemy is frozen (attack blocked).
func on_enemy_attack_started(enemy: EnemyBase) -> bool:
	var st := status_for_enemy(enemy)
	if now_ms() <= int(st.get("freeze_until_ms", 0)):
		return false
	if now_ms() <= int(st.get("time_stop_until_ms", 0)):
		return false
	# Time Drift: enemy actions are blocked for its full duration
	if now_ms() < int(battle_flags.get("time_drift_enemy_until_ms", 0)):
		return false
	var poison_stacks := int(st.get("poison_stack", 0))
	if poison_stacks > 0:
		_damage_enemy_dot(poison_stacks, enemy)
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


## Thunder chain: when a thundered enemy takes damage, every other enemy that
## also has thunder stacks receives (their_stacks %) of that damage as DOT.
## The struck enemy itself also takes (its_stacks %) extra damage.
func _propagate_thunder(damage: int, source_enemy: EnemyBase) -> void:
	if _thunder_propagating or damage <= 0 or source_enemy == null:
		return
	_thunder_propagating = true
	# Extra resonance damage on the struck enemy itself
	var src_stacks := int(status_for_enemy(source_enemy).get("thunder_stack", 0))
	if src_stacks > 0:
		var self_dmg := maxi(1, int(round(float(damage) * float(src_stacks) / 100.0)))
		_damage_enemy_dot(self_dmg, source_enemy)
	# Chain to every other thundered enemy
	for other in _alive_enemies():
		if other == source_enemy:
			continue
		var other_stacks := int(status_for_enemy(other).get("thunder_stack", 0))
		if other_stacks <= 0:
			continue
		var chain_dmg := maxi(1, int(round(float(damage) * float(other_stacks) / 100.0)))
		_damage_enemy_dot(chain_dmg, other)
	_thunder_propagating = false


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
