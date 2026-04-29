extends RefCounted
class_name RankAbilityEffects


static func execute(ctx: BattleContext, source: BallBase, kind: String, rank: int) -> void:
	match kind:
		"strike":
			_deal_all(ctx, 1)
		"mend":
			ctx.heal_player(3)
		"venom":
			ctx.add_enemy_status(ctx.active_enemy(), "poison", 10, 1)
		"ember":
			ctx.add_enemy_status(ctx.active_enemy(), "burn", 10, 2)
		"guard":
			ctx.add_player_shield(5)
		"critical":
			_deal_single(ctx, 5 if randi_range(1, 2) == 1 else 1)
		"refresh":
			ctx.mana_pipes = min(ctx.MAX_MANA_PIPES, ctx.mana_pipes + 1)
		"heavy_strike":
			_deal_single(ctx, 10)
		"recovery":
			var lost: int = maxi(0, PlayerState.player_max_health - PlayerState.player_health)
			ctx.heal_player(int(round(lost * 0.25)))
		"frost_touch":
			ctx.add_enemy_status(ctx.active_enemy(), "freeze", 5, 0)
		"iron_guard":
			ctx.add_player_shield(20)
		"triple_shot":
			for _i in range(3):
				_deal_random_enemy(ctx, 5)
		"scatter_drop":
			for _i in range(2):
				_spawn_random_ball_rank_1_to_3(ctx, source)
		"critical_strike":
			if randi_range(1, 2) == 1:
				_deal_all(ctx, 5)
			else:
				_deal_single(ctx, 5)
		"pollution":
			var st := ctx.status_for_enemy(ctx.active_enemy())
			if not st.is_empty():
				st["poison_strength"] = int(st.get("poison_strength", 0)) * 2
		"fireburn":
			ctx.add_enemy_status(ctx.active_enemy(), "burn", 10, 5)
		"power_slash":
			_deal_single(ctx, 30)
		"toxic_burst":
			ctx.add_enemy_status(ctx.active_enemy(), "poison", 30, 1)
		"fireball":
			_deal_single(ctx, 5)
			ctx.add_enemy_status(ctx.active_enemy(), "burn", 5, 10)
		"ice_lance":
			_deal_single(ctx, 5)
			ctx.add_enemy_status(ctx.active_enemy(), "freeze", 5, 0)
		"reinforce":
			ctx.add_player_attack_bonus(3)
		"convert":
			_upgrade_random_ball(ctx, 1)
		"echo_shot":
			_reapply_last(ctx, source)
		"charm":
			ctx.add_enemy_status(ctx.active_enemy(), "charm", 5, 0)
		"cleave":
			_deal_all(ctx, 20)
		"greater_heal":
			var lost_g: int = maxi(0, PlayerState.player_max_health - PlayerState.player_health)
			ctx.heal_player(int(round(lost_g * 0.5)))
		"bomb_orb":
			_schedule_damage_all(ctx, 10.0, 50)
		"chain_spark":
			_chain_spark(ctx)
		"mirror_shield":
			ctx.set_player_reflect_hits(1)
		"corrupt_field":
			# Hazard zone: all active enemies immediately receive the poison aura
			for e in _alive_enemies(ctx):
				ctx.add_enemy_status(e, "poison", 10, 2)
		"critical_edge":
			var pool := [5, 10, 20, 100]
			_deal_single(ctx, int(pool[randi() % pool.size()]))
		"freeze_wave":
			for e in _alive_enemies(ctx):
				ctx.add_enemy_status(e, "freeze", 5, 0)
		"giant_orb":
			_apply_giant_to_random_ball(ctx, 2.0)
		"consume_core":
			_consume_random_ball_and_deal(ctx, 100, source)
		"upgrade_pulse":
			_upgrade_random_ball(ctx, 1)
		"poison_rain":
			for e in _alive_enemies(ctx):
				ctx.add_enemy_status(e, "poison", 20, 1)
		"time_drift":
			_slow_time_for_seconds(ctx, 10.0)
		"meteor_crash":
			_deal_all(ctx, 100)
		"full_recovery":
			ctx.heal_player(PlayerState.player_max_health)
		"chaos_rain":
			for _i in range(5):
				_spawn_random_ball_rank_1_to_3(ctx, source)
			ctx.mana_pipes = max(0, ctx.mana_pipes - 1)
		"overcharge":
			ctx.add_player_attack_bonus(10)
		"mass_morph":
			_mass_morph(ctx)
		"reflect_wall":
			ctx.set_player_reflect_for_seconds(20.0)
		"giant_core":
			_apply_giant_to_random_ball(ctx, 3.0)
		"final_judgment":
			_deal_single(ctx, 1000)
		"apocalypse":
			_deal_all(ctx, 100)
		"resurrection":
			ctx.set_resurrection_ready()
		"time_stop":
			_delete_half_balls(ctx)
			for e in _alive_enemies(ctx):
				ctx.set_enemy_freeze_seconds(e, 20.0)
		"magic_flood":
			_magic_flood(ctx)
		"miracle_cascade":
			_miracle_cascade(ctx, source)
		"sacrifice_nova":
			_sacrifice_nova(ctx)
		"one_shower":
			_one_shower(ctx, source)
	# echo_shot preserves the last non-echo effect so chaining works
	if kind != "echo_shot":
		ctx.battle_flags["last_effect_id"] = "%s_%d" % [kind, rank]


static func _deal_single(ctx: BattleContext, amount: int) -> void:
	var ae := ctx.active_enemy()
	if ae != null:
		ctx.damage_enemy(amount, ae)
		ctx.battle_flags["last_damage"] = amount


static func _deal_all(ctx: BattleContext, amount: int) -> void:
	if ctx.controller != null and ctx.controller.has_method("damage_all_enemies"):
		ctx.controller.damage_all_enemies(amount, ctx)
		ctx.battle_flags["last_damage"] = amount


static func _deal_random_enemy(ctx: BattleContext, amount: int) -> void:
	var enemies := _alive_enemies(ctx)
	if enemies.is_empty():
		return
	ctx.damage_enemy(amount, enemies[randi() % enemies.size()])
	ctx.battle_flags["last_damage"] = amount


static func _spawn_random_ball_rank_1_to_3(ctx: BattleContext, source: BallBase) -> void:
	var ids := ["ball_normal", "ball_heavy", "ball_bomb"]
	var id: String = ids[randi() % ids.size()]
	var ball_rank := randi_range(1, 3)
	var origin: Vector2 = source.global_position if is_instance_valid(source) else Vector2(200.0, 100.0)
	ctx.spawn_ball(id, origin + Vector2(randf_range(-30.0, 30.0), -20.0), Vector2(randf_range(-30.0, 30.0), 0.0), ball_rank)


static func _upgrade_random_ball(ctx: BattleContext, by: int) -> void:
	var balls := ctx.active_balls()
	if balls.is_empty():
		return
	var ball := balls[randi() % balls.size()] as BallBase
	ball.rank = clampi(ball.rank + by, 1, 7)
	ball.refresh()


static func _reapply_last(ctx: BattleContext, source: BallBase) -> void:
	var last_id := String(ctx.battle_flags.get("last_effect_id", ""))
	if last_id.is_empty():
		return
	var idx := last_id.rfind("_")
	if idx < 0:
		return
	var kind := last_id.substr(0, idx)
	var rank := last_id.substr(idx + 1).to_int()
	if kind == "echo_shot":
		return
	execute(ctx, source, kind, rank)


static func _schedule_damage_all(ctx: BattleContext, seconds: float, amount: int) -> void:
	if ctx.controller == null:
		return
	var tree: SceneTree = ctx.controller.get_tree() as SceneTree
	if tree == null:
		return
	# Use real-time timer so game-speed changes don't affect the delay
	var timer: SceneTreeTimer = tree.create_timer(seconds, true, false, true)
	timer.timeout.connect(func():
		if ctx.controller != null and ctx.controller.has_method("damage_all_enemies"):
			ctx.controller.damage_all_enemies(amount, ctx)
	)


static func _chain_spark(ctx: BattleContext) -> void:
	var enemies := _alive_enemies(ctx)
	if enemies.is_empty():
		return
	var dmg := 10
	var last_idx := -1
	for _i in range(3):
		var idx: int
		if enemies.size() == 1:
			idx = 0
		else:
			idx = randi() % enemies.size()
			if idx == last_idx:
				idx = (idx + 1) % enemies.size()
		last_idx = idx
		ctx.damage_enemy(dmg, enemies[idx])
		dmg *= 2
	ctx.battle_flags["last_damage"] = 10


static func _apply_giant_to_random_ball(ctx: BattleContext, attack_mult: float) -> void:
	var balls := ctx.active_balls()
	if balls.is_empty():
		return
	var ball := balls[randi() % balls.size()] as BallBase
	var st := ctx.ball_status_for(ball)
	if bool(st.get("is_giant", false)):
		return
	if not st.has("base_scale"):
		st["base_scale"] = ball.scale
	st["attack_mult"] = attack_mult
	st["trigger_twice"] = true
	st["is_giant"] = true
	ball.scale = (st["base_scale"] as Vector2) * 3.0
	ball.refresh()


static func _consume_random_ball_and_deal(ctx: BattleContext, amount: int, source: BallBase) -> void:
	var balls := ctx.active_balls()
	if balls.is_empty():
		return
	var victim := balls[randi() % balls.size()] as BallBase
	if victim != source:
		ctx.consume_ball(victim)
	_deal_single(ctx, amount)


static func _slow_time_for_seconds(ctx: BattleContext, seconds: float) -> void:
	if ctx.controller == null:
		return
	Engine.time_scale = 0.4
	# Real-time timer so it expires after 'seconds' wall-clock seconds
	var tree: SceneTree = ctx.controller.get_tree() as SceneTree
	if tree == null:
		return
	var timer: SceneTreeTimer = tree.create_timer(seconds, true, false, true)
	timer.timeout.connect(func():
		Engine.time_scale = 1.0
	)


static func _mass_morph(ctx: BattleContext) -> void:
	for ball in ctx.active_balls():
		var b := ball as BallBase
		if b.rank <= 2:
			b.rank = mini(7, b.rank + 1)
			b.refresh()


static func _delete_half_balls(ctx: BattleContext) -> void:
	var balls := ctx.active_balls()
	balls.shuffle()
	var count := balls.size() / 2
	for i in range(count):
		ctx.consume_ball(balls[i])


static func _magic_flood(ctx: BattleContext) -> void:
	# Float every ball upward
	for ball in ctx.active_balls():
		(ball as BallBase).apply_central_impulse(Vector2(0.0, -300.0))
	# Apply a random enchantment status to each active enemy
	for e in _alive_enemies(ctx):
		var r := randi_range(1, 3)
		if r == 1:
			ctx.add_enemy_status(e, "poison", 10, 2)    # Poison enchant
		elif r == 2:
			ctx.add_enemy_status(e, "burn", 5, 5)       # Fire enchant
		else:
			ctx.add_enemy_status(e, "freeze", 5, 0)     # Ice enchant


static func _miracle_cascade(ctx: BattleContext, source: BallBase) -> void:
	# Trigger one random effect from EACH of rank 3, 4, and 5
	var r3: Array = [["power_slash", 3], ["toxic_burst", 3], ["fireball", 3], ["ice_lance", 3], ["charm", 3]]
	var r4: Array = [["cleave", 4], ["chain_spark", 4], ["bomb_orb", 4], ["greater_heal", 4], ["mirror_shield", 4]]
	var r5: Array = [["critical_edge", 5], ["poison_rain", 5], ["freeze_wave", 5], ["giant_orb", 5], ["time_drift", 5]]
	var p3: Array = r3[randi() % r3.size()] as Array
	var p4: Array = r4[randi() % r4.size()] as Array
	var p5: Array = r5[randi() % r5.size()] as Array
	execute(ctx, source, String(p3[0]), int(p3[1]))
	execute(ctx, source, String(p4[0]), int(p4[1]))
	execute(ctx, source, String(p5[0]), int(p5[1]))


static func _sacrifice_nova(ctx: BattleContext) -> void:
	var self_damage := int(round(PlayerState.player_health * 0.5))
	ctx.damage_player(self_damage)
	_schedule_damage_all(ctx, 10.0, 500)


static func _one_shower(ctx: BattleContext, source: BallBase) -> void:
	if ctx.controller == null:
		return
	var tree: SceneTree = ctx.controller.get_tree() as SceneTree
	if tree == null:
		return
	# Capture spawn origin now — source will be gone by the time timers fire
	var origin: Vector2 = source.global_position if is_instance_valid(source) else Vector2(200.0, 100.0)
	for i in range(30):
		var t: SceneTreeTimer = tree.create_timer(float(i), true, false, true)
		t.timeout.connect(func():
			if ctx.controller != null:
				ctx.spawn_ball(
					"ball_normal",
					origin + Vector2(randf_range(-60.0, 60.0), -50.0),
					Vector2(randf_range(-20.0, 20.0), 0.0),
					1
				)
		)


static func _alive_enemies(ctx: BattleContext) -> Array:
	var out: Array = []
	if ctx.controller == null or not ctx.controller.has_method("_alive_enemy_slots"):
		return out
	for slot in ctx.controller._alive_enemy_slots():
		if slot != null and slot.enemy != null and slot.enemy.is_alive():
			out.append(slot.enemy)
	return out
