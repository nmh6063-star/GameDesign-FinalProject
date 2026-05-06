extends RefCounted
class_name RankAbilityEffects


static func execute(ctx: BattleContext, source: BallBase, kind: String, rank: int) -> void:
	match kind:
		# ── Rank 1 ────────────────────────────────────────────────────────────
		"strike":
			_deal_single(ctx, 5)
		"mend":
			ctx.heal_player(5)
		"venom":
			ctx.add_enemy_status(ctx.active_enemy(), "poison", 8)
		"ember":
			for e in _alive_enemies(ctx):
				ctx.add_enemy_status(e, "burn", 3)
		"guard":
			ctx.add_player_shield(5)
		"critical":
			# 50%: deal 5 to all enemies; else: deal 5 to current target
			if randi_range(1, 2) == 1:
				_deal_all(ctx, 5)
			else:
				_deal_single(ctx, 5)
		"refresh":
			ctx.mana_pipes = min(ctx.MAX_MANA_PIPES, ctx.mana_pipes + 1)

		# ── Rank 2 ────────────────────────────────────────────────────────────
		"heavy_strike":
			_deal_single(ctx, 10)
		"recovery":
			var lost: int = maxi(0, PlayerState.player_max_health - PlayerState.player_health)
			ctx.heal_player(int(round(lost * 0.15)))
		"frost_touch":
			# Flat 5-second freeze on all enemies (5 stacks × 1 s each)
			for e in _alive_enemies(ctx):
				ctx.add_enemy_status(e, "freeze", 5)
		"iron_guard":
			ctx.add_player_shield(25)
		"triple_shot":
			for _i in range(3):
				_deal_random_enemy(ctx, 8)
		"scatter_drop":
			for _i in range(2):
				_spawn_random_ball_rank_1_to_3(ctx, source)
		"critical_strike":
			if randi_range(1, 2) == 1:
				_deal_all(ctx, 8)
			else:
				_deal_single(ctx, 8)
		"pollution":
			# Doubles poison stacks on current target
			var st := ctx.status_for_enemy(ctx.active_enemy())
			if not st.is_empty():
				st["poison_stack"] = int(st.get("poison_stack", 0)) * 2
		"fireburn":
			for e in _alive_enemies(ctx):
				ctx.add_enemy_status(e, "burn", 5)

		# ── Rank 3 ────────────────────────────────────────────────────────────
		"power_slash":
			_deal_single(ctx, 18)
		"toxic_burst":
			for e in _alive_enemies(ctx):
				ctx.add_enemy_status(e, "poison", 15)
		"fireball":
			# Two hits on random enemies, each also applies 5 burn stacks
			for _i in range(2):
				var enemies := _alive_enemies(ctx)
				if enemies.is_empty():
					break
				var target := enemies[randi() % enemies.size()] as EnemyBase
				ctx.damage_enemy(8, target)
				ctx.add_enemy_status(target, "burn", 8)
			ctx.battle_flags["last_damage"] = 5
		"ice_shield":
			ctx.add_player_shield(10)
			ctx.add_enemy_status(ctx.active_enemy(), "freeze", 5)
		"reinforce":
			ctx.add_player_attack_bonus(2)
		"convert":
			_upgrade_random_ball(ctx, 1)
		"echo_shot":
			_reapply_last(ctx, source)
		"charm":
			# All enemies redirect their next attack at each other (1 stack)
			for e in _alive_enemies(ctx):
				ctx.add_enemy_status(e, "charm", 1)

		# ── Rank 4 ────────────────────────────────────────────────────────────
		"cleave":
			_deal_all(ctx, 15)
		"greater_heal":
			var lost_g: int = maxi(0, PlayerState.player_max_health - PlayerState.player_health)
			ctx.heal_player(int(round(lost_g * 0.30)))
		"bomb_orb":
			_schedule_damage_all(ctx, 10.0, 50)
		"chain_spark":
			_chain_spark(ctx)
		"mirror_shield":
			ctx.set_player_reflect_hits(2)
		"corrupt_field":
			for e in _alive_enemies(ctx):
				ctx.add_enemy_status(e, "poison", 20)

		# ── Rank 5 ────────────────────────────────────────────────────────────
		"critical_edge":
			var pool := [25, 30]
			_deal_single(ctx, int(pool[randi() % pool.size()]))
		"freeze_wave":
			for e in _alive_enemies(ctx):
				ctx.add_enemy_status(e, "freeze", 3)
		"giant_orb":
			# ×3 attack, ×2 size — no double-trigger
			_apply_giant_orb(ctx)
		"consume_core":
			_consume_random_ball_and_deal(ctx, 100, source)
		"upgrade_pulse":
			_upgrade_random_ball(ctx, 1)
		"poison_rain":
			for e in _alive_enemies(ctx):
				ctx.add_enemy_status(e, "poison", 25)
		"time_drift":
			_time_drift(ctx)
		"contagion":
			ctx.spread_debuffs_from_active_to_random_other()

		# ── Rank 6 ────────────────────────────────────────────────────────────
		"meteor_crash":
			_deal_all(ctx, 30)
		"full_recovery":
			ctx.heal_player(int(PlayerState.player_max_health * 0.30))
		"chaos_rain":
			if ctx.can_spend_mana(1):
				ctx.try_spend_mana(1)
				for _i in range(6):
					_spawn_random_ball_rank_1_to_3(ctx, source)
			else:
				for _i in range(3):
					_spawn_random_ball_rank_1_to_3(ctx, source)
		"overcharge":
			ctx.add_player_attack_bonus(5)
		"mass_morph":
			_mass_morph(ctx)
		"reflect_wall":
			ctx.set_player_reflect_for_seconds(12.0)
		"giant_core":
			# ×3 attack, ×2 trigger, ×2 size — only affects rank 1–5 balls
			_apply_giant_core(ctx)
		"dot_siphon":
			var cur_siphon := float(ctx.player_statuses.get("dot_damage_heal_ratio", 0.0))
			ctx.player_statuses["dot_damage_heal_ratio"] = maxf(cur_siphon, 0.2)

		# ── Rank 7 ────────────────────────────────────────────────────────────
		"final_judgment":
			_deal_single(ctx, 45)
		"apocalypse":
			_deal_all(ctx, 48)
		"resurrection":
			ctx.set_resurrection_ready()
		"time_stop":
			_clear_all_balls(ctx)
			for e in _alive_enemies(ctx):
				ctx.add_enemy_status(e, "freeze", 6)
		"magic_flood":
			_magic_flood(ctx)
		"miracle_cascade":
			_miracle_cascade(ctx, source)
		"sacrifice_nova":
			_sacrifice_nova(ctx)
		"one_shower":
			_one_shower(ctx, source)
		"dot_echo":
			ctx.player_statuses["dot_triggers_twice"] = true

	# Preserve last effect for Echo Shot (never record echo_shot itself)
	if kind != "echo_shot":
		ctx.battle_flags["last_effect_id"] = "%s_%d" % [kind, rank]


# ── Single / All / Random helpers ─────────────────────────────────────────────

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


# ── Ball spawning ──────────────────────────────────────────────────────────────

## Returns a sensible world origin for spawning balls.
## Prefers the source ball's position, then the controller's drop-zone centre,
## then a safe hard-coded fallback.
static func _safe_origin(ctx: BattleContext, source: BallBase) -> Vector2:
	if is_instance_valid(source):
		return source.global_position
	if ctx.controller != null and ctx.controller.has_method("drop_zone_global"):
		var dz: Vector2 = ctx.controller.drop_zone_global()
		if dz != Vector2.ZERO:
			return dz
	return Vector2(200.0, 100.0)


static func _spawn_random_ball_rank_1_to_3(ctx: BattleContext, source: BallBase) -> void:
	var ids := ["ball_normal", "ball_heavy", "ball_bomb"]
	var id: String = ids[randi() % ids.size()]
	var ball_rank := randi_range(1, 3)
	var origin: Vector2 = _safe_origin(ctx, source)
	ctx.spawn_ball(id, origin + Vector2(randf_range(-30.0, 30.0), -20.0),
			Vector2(randf_range(-30.0, 30.0), 0.0), ball_rank)


# ── Ball manipulation ─────────────────────────────────────────────────────────

static func _upgrade_random_ball(ctx: BattleContext, by: int) -> void:
	var balls := ctx.active_balls()
	if balls.is_empty():
		return
	var ball := balls[randi() % balls.size()] as BallBase
	ball.rank = clampi(ball.rank + by, 1, 7)
	ball.refresh()


static func _consume_random_ball_and_deal(ctx: BattleContext, amount: int, source: BallBase) -> void:
	var balls := ctx.active_balls()
	if balls.is_empty():
		return
	var victim := balls[randi() % balls.size()] as BallBase
	if victim != source:
		ctx.consume_ball(victim)
	_deal_single(ctx, amount)


static func _mass_morph(ctx: BattleContext) -> void:
	for ball in ctx.active_balls():
		var b := ball as BallBase
		if b.rank <= 2:
			b.rank = mini(7, b.rank + 1)
			b.refresh()


static func _clear_all_balls(ctx: BattleContext) -> void:
	for ball in ctx.active_balls():
		ctx.consume_ball(ball)


# ── Echo Shot ─────────────────────────────────────────────────────────────────

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


# ── Delayed / scheduled effects ───────────────────────────────────────────────

static func _schedule_damage_all(ctx: BattleContext, seconds: float, amount: int) -> void:
	if ctx.controller == null:
		return
	var tree: SceneTree = ctx.controller.get_tree() as SceneTree
	if tree == null:
		return
	var timer: SceneTreeTimer = tree.create_timer(seconds, true, false, true)
	timer.timeout.connect(func():
		if ctx.controller != null and ctx.controller.has_method("damage_all_enemies"):
			ctx.controller.damage_all_enemies(amount, ctx)
	)


# ── Chain Spark ───────────────────────────────────────────────────────────────

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


# ── Giant Orb / Giant Core ────────────────────────────────────────────────────

static func _apply_giant_orb(ctx: BattleContext) -> void:
	var balls := ctx.active_balls()
	if balls.is_empty():
		return
	var ball := balls[randi() % balls.size()] as BallBase
	var st := ctx.ball_status_for(ball)
	if bool(st.get("is_giant", false)):
		return
	if not st.has("base_scale"):
		st["base_scale"] = ball.scale
	st["attack_mult"]   = 3.0
	st["trigger_twice"] = false
	st["is_giant"]      = true
	ball.scale = (st["base_scale"] as Vector2) * 2.0
	ball.refresh()


static func _apply_giant_core(ctx: BattleContext) -> void:
	# Only affects rank 1–5 balls
	var eligible: Array = []
	for b in ctx.active_balls():
		var ball := b as BallBase
		if ball.rank <= 5 and not bool(ctx.ball_status_for(ball).get("is_giant", false)):
			eligible.append(ball)
	if eligible.is_empty():
		return
	var ball := eligible[randi() % eligible.size()] as BallBase
	var st := ctx.ball_status_for(ball)
	if not st.has("base_scale"):
		st["base_scale"] = ball.scale
	st["attack_mult"]   = 3.0
	st["trigger_twice"] = true
	st["is_giant"]      = true
	ball.scale = (st["base_scale"] as Vector2) * 2.0
	ball.refresh()


# ── Time Drift ────────────────────────────────────────────────────────────────

static func _time_drift(ctx: BattleContext) -> void:
	if ctx.controller == null:
		return
	var tree: SceneTree = ctx.controller.get_tree() as SceneTree
	if tree == null:
		return
	# Slow time for 10 seconds
	Engine.time_scale = 0.4
	var restore_timer: SceneTreeTimer = tree.create_timer(10.0, true, false, true)
	restore_timer.timeout.connect(func(): Engine.time_scale = 1.0)
	# First 5 seconds: incoming player damage is stored (handled in BattleContext.damage_player)
	ctx.battle_flags["time_drift_active"] = true
	ctx.battle_flags["time_drift_stored"] = 0
	var mid_timer: SceneTreeTimer = tree.create_timer(5.0, true, false, true)
	mid_timer.timeout.connect(func():
		ctx.battle_flags["time_drift_active"] = false
		var stored := int(ctx.battle_flags.get("time_drift_stored", 0))
		if stored <= 0:
			return
		# Deal stored damage back to enemies over the final 5 seconds (1 tick/sec)
		var per_tick := maxi(1, stored / 5)
		for i in range(5):
			var t: SceneTreeTimer = tree.create_timer(float(i), true, false, true)
			t.timeout.connect(func():
				for e in _alive_enemies(ctx):
					ctx._damage_enemy_dot(per_tick, e)
			)
	)


# ── Slow time helper ──────────────────────────────────────────────────────────

static func _slow_time_for_seconds(ctx: BattleContext, seconds: float) -> void:
	if ctx.controller == null:
		return
	Engine.time_scale = 0.4
	var tree: SceneTree = ctx.controller.get_tree() as SceneTree
	if tree == null:
		return
	var timer: SceneTreeTimer = tree.create_timer(seconds, true, false, true)
	timer.timeout.connect(func(): Engine.time_scale = 1.0)


# ── Magic Flood ───────────────────────────────────────────────────────────────

static func _magic_flood(ctx: BattleContext) -> void:
	for ball in ctx.active_balls():
		(ball as BallBase).apply_central_impulse(Vector2(0.0, -300.0))
	for e in _alive_enemies(ctx):
		var r := randi_range(1, 3)
		if r == 1:
			ctx.add_enemy_status(e, "poison", 8)
		elif r == 2:
			ctx.add_enemy_status(e, "burn", 3)
		else:
			ctx.add_enemy_status(e, "freeze", 3)


# ── Miracle Cascade ───────────────────────────────────────────────────────────

static func _miracle_cascade(ctx: BattleContext, source: BallBase) -> void:
	var r3: Array = [["power_slash", 3], ["toxic_burst", 3], ["fireball", 3],
			["ice_shield", 3], ["charm", 3]]
	var r4: Array = [["cleave", 4], ["chain_spark", 4], ["bomb_orb", 4],
			["greater_heal", 4], ["mirror_shield", 4]]
	var r5: Array = [["critical_edge", 5], ["poison_rain", 5], ["freeze_wave", 5],
			["giant_orb", 5], ["time_drift", 5], ["contagion", 5]]
	var p3: Array = r3[randi() % r3.size()]
	var p4: Array = r4[randi() % r4.size()]
	var p5: Array = r5[randi() % r5.size()]
	execute(ctx, source, String(p3[0]), int(p3[1]))
	execute(ctx, source, String(p4[0]), int(p4[1]))
	execute(ctx, source, String(p5[0]), int(p5[1]))


# ── Sacrifice Nova ────────────────────────────────────────────────────────────

static func _sacrifice_nova(ctx: BattleContext) -> void:
	var self_damage := int(round(PlayerState.player_health * 0.5))
	ctx._damage_player_raw(self_damage)
	_schedule_damage_all(ctx, 10.0, 500)


# ── 1 Shower ──────────────────────────────────────────────────────────────────

static func _one_shower(ctx: BattleContext, source: BallBase) -> void:
	if ctx.controller == null:
		return
	var tree: SceneTree = ctx.controller.get_tree() as SceneTree
	if tree == null:
		return
	var origin: Vector2 = _safe_origin(ctx, source)
	for i in range(10):
		var t: SceneTreeTimer = tree.create_timer(float(i), true, false, true)
		t.timeout.connect(func():
			if ctx.controller != null:
				var ball_rank := randi_range(1, 3)
				ctx.spawn_ball(
					"ball_normal",
					origin + Vector2(randf_range(-60.0, 60.0), -50.0),
					Vector2(randf_range(-20.0, 20.0), 0.0),
					ball_rank
				)
		)


# ── Alive enemies helper ──────────────────────────────────────────────────────

static func _alive_enemies(ctx: BattleContext) -> Array:
	var out: Array = []
	if ctx.controller == null or not ctx.controller.has_method("_alive_enemy_slots"):
		return out
	for slot in ctx.controller._alive_enemy_slots():
		if slot != null and slot.enemy != null and slot.enemy.is_alive():
			out.append(slot.enemy)
	return out
