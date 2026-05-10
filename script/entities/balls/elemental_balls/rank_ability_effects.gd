extends RefCounted
class_name RankAbilityEffects


static func execute(ctx: BattleContext, source: BallBase, kind: String, rank: int) -> void:
	match kind:
		# ── Rank 1 ────────────────────────────────────────────────────────────
		"strike":
			_deal_single(ctx, 8 * clampi(rank, 1, 7), source)
		"mend":
			var lost_mend := maxi(0, PlayerState.player_max_health - PlayerState.player_health)
			var heal_mend := maxi(1, int(round(float(lost_mend) * 0.05)))
			ctx.heal_player(heal_mend)
			var mend_dmg := maxi(1, int(round(float(heal_mend) * 0.10)))
			_deal_single(ctx, mend_dmg, source)
		"venom":
			ctx.add_enemy_status(ctx.active_enemy(), "poison", 6)
		"ember":
			for e in _alive_enemies(ctx):
				ctx.add_enemy_status(e, "burn", 3)
		"guard":
			ctx.add_player_shield(5)
		"critical":
			# 50%: deal 5 to all enemies; else: deal 5 to current target
			if randi_range(1, 2) == 1:
				_deal_all(ctx, 10, source)
			else:
				_deal_single(ctx, 15, source)
		"refresh":
			ctx.mana_pipes = min(ctx.MAX_MANA_PIPES, ctx.mana_pipes + 1)

		# ── Rank 2 ────────────────────────────────────────────────────────────
		"heavy_strike":
			_deal_single(ctx, 18, source)
		"recovery":
			var lost: int = maxi(0, PlayerState.player_max_health - PlayerState.player_health)
			ctx.heal_player(int(round(lost * 0.10)))
		"frost_touch":
			# Flat 5-second freeze on all enemies (5 stacks × 1 s each)
			for e in _alive_enemies(ctx):
				ctx.add_enemy_status(e, "freeze", 5)
				_deal_single(ctx, 10, source)
		"iron_guard":
			ctx.add_player_shield(25)
		"triple_shot":
			for _i in range(3):
				_deal_random_enemy(ctx, 10, source)
		"scatter_drop":
			for _i in range(2):
				_spawn_random_ball_rank_1_to_3(ctx, source)
		"critical_strike":
			if randi_range(1, 2) == 1:
				_deal_single(ctx, 25, source)
			else:
				_deal_single(ctx, 10, source)
		"fireburn":
			for e in _alive_enemies(ctx):
				ctx.add_enemy_status(e, "burn", 5)
		"toxic_burst":
			for _i in range(2):
				var enemies := _alive_enemies(ctx)
				if enemies.is_empty():
					break
				var target := enemies[randi() % enemies.size()] as EnemyBase
				ctx.add_enemy_status(target, "poison", 8)

		# ── Rank 3 ────────────────────────────────────────────────────────────
		"power_slash":
			_deal_single(ctx, 25, source)
		"pollution":
			# Doubles poison stacks on current target
			var st := ctx.status_for_enemy(ctx.active_enemy())
			if not st.is_empty():
				st["poison_stack"] = int(st.get("poison_stack", 0)) * 2
		"fireball":
			# Two hits on random enemies, each also applies 8 burn stacks
			for _i in range(2):
				var enemies := _alive_enemies(ctx)
				if enemies.is_empty():
					break
				var target := enemies[randi() % enemies.size()] as EnemyBase
				ctx.damage_enemy(12, target)
				ctx.add_enemy_status(target, "burn", 8)
			ctx.battle_flags["last_damage"] = 8
		"ice_shield":
			ctx.add_player_shield(20)
			ctx.add_enemy_status(ctx.active_enemy(), "freeze", 5)
		"reinforce":
			ctx.add_player_attack_bonus(3)
		"convert":
			_upgrade_random_ball_with_fx(ctx, 1)
		"echo_shot":
			_reapply_last(ctx, source)
		"charm":
			# All enemies redirect their next attack at each other (1 stack)
			for e in _alive_enemies(ctx):
				ctx.add_enemy_status(e, "charm", 1)
		"thunder_fang":
			_thunder_fang(ctx)
		"regeneration":
			_regeneration(ctx)

		# ── Rank 4 ────────────────────────────────────────────────────────────
		"cleave":
			_deal_all(ctx, 20, source)
		"greater_heal":
			var lost_g: int = maxi(0, PlayerState.player_max_health - PlayerState.player_health)
			ctx.heal_player(int(round(lost_g * 0.30)))
		"bomb_orb":
			_schedule_bomb_orb(ctx)
		"chain_spark":
			_chain_spark(ctx)
		"mirror_shield":
			ctx.set_player_reflect_hits(3)
		"corrupt_field":
			for e in _alive_enemies(ctx):
				ctx.add_enemy_status(e, "poison", 12)
			ctx.battle_flags["corrupt_field_active"] = true
		"tide_turner":
			# Mark pending; resolved in battle_loop.try_shoot after all on_shot calls.
			ctx.battle_flags["tide_turner_pending"] = true
		"weakness_brand":
			ctx.add_enemy_status(ctx.active_enemy(), "weakness_brand", 3)
		"lifesteal_field":
			ctx.player_statuses["direct_damage_heal_ratio"] = \
					maxf(float(ctx.player_statuses.get("direct_damage_heal_ratio", 0.0)), 0.1)
		"fortress":
			ctx.add_player_shield(50)
			ctx._damage_player_hp_only(15)

		# ── Rank 5 ────────────────────────────────────────────────────────────
		"critical_edge":
			var pool := [25, 30]
			_deal_single(ctx, int(pool[randi() % pool.size()]), source)
		"freeze_wave":
			for e in _alive_enemies(ctx):
				ctx.add_enemy_status(e, "freeze", 3)
		"giant_orb":
			# ×3 attack, ×2 size — no double-trigger
			_apply_giant_orb(ctx)
		"consume_core":
			_consume_random_ball_and_deal(ctx, 100, source)
		"upgrade_pulse":
			_upgrade_random_ball_with_fx(ctx, 1)
		"poison_rain":
			# Activate the Rain effect: stacks grow instead of shrink for 3 shoots,
			# and every direct hit adds 2 more stacks.
			ctx.battle_flags["poison_rain_shoots"] = 3
		"time_drift":
			_time_drift(ctx)
		"contagion":
			ctx.spread_debuffs_from_active_to_random_other()
		"chaos_slash":
			_chaos_slash(ctx)
		"guillotine":
			_guillotine(ctx, source)

		# ── Rank 6 ────────────────────────────────────────────────────────────
		"meteor_crash":
			_deal_all(ctx, 30, source)
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
			ctx.player_statuses["dot_damage_heal_ratio"] = maxf(cur_siphon, 0.1)
		"gatekeeper":
			ctx.battle_flags["gatekeeper_charges"] = \
					int(ctx.battle_flags.get("gatekeeper_charges", 0)) + 3
		"storm_surge":
			_storm_surge(ctx)
		"second_wind":
			ctx.player_statuses["second_wind_ready"]     = true
			ctx.player_statuses["second_wind_main_used"] = false
			ctx.player_statuses["second_wind_cooldown"]  = false
		"overkill":
			_deal_single(ctx, 40, source)
			ctx.battle_flags["overkill_active"] = true

		# ── Rank 7 ────────────────────────────────────────────────────────────
		"final_judgment":
			# 4 hits of 12 damage on current enemy.
			for _i in range(4):
				_deal_single(ctx, 12, source)
		"apocalypse":
			# 6 hits of 8 damage to all enemies.
			for _i in range(6):
				_deal_all(ctx, 8, source)
		"resurrection":
			ctx.set_resurrection_ready()
		"time_stop":
			_clear_all_balls(ctx)
			var stop_secs := 10
			var stop_until := ctx.now_ms() + stop_secs * 1000
			for e in _alive_enemies(ctx):
				var ts_st := ctx.status_for_enemy(e)
				ts_st["time_stop_until_ms"] = stop_until
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
		"baators_flame":
			_baators_flame(ctx)
		"thunder_strike":
			_thunder_strike(ctx)
		"elbaphs_power":
			_elbaphs_power(ctx)

	# Preserve last effect for Echo Shot (never record echo_shot itself)
	if kind != "echo_shot":
		ctx.battle_flags["last_effect_id"] = "%s_%d" % [kind, rank]


# ── Single / All / Random helpers ─────────────────────────────────────────────

static func _deal_single(ctx: BattleContext, amount: int, source: BallBase = null) -> void:
	var ae := ctx.active_enemy()
	if ae != null:
		var final := _apply_attack_mult(ctx, source, amount)
		ctx.damage_enemy(final, ae)
		ctx.battle_flags["last_damage"] = final


static func _deal_all(ctx: BattleContext, amount: int, source: BallBase = null) -> void:
	if ctx.controller != null and ctx.controller.has_method("damage_all_enemies"):
		var final := _apply_attack_mult(ctx, source, amount)
		ctx.controller.damage_all_enemies(final, ctx)
		ctx.battle_flags["last_damage"] = final


static func _deal_random_enemy(ctx: BattleContext, amount: int, source: BallBase = null) -> void:
	var enemies := _alive_enemies(ctx)
	if enemies.is_empty():
		return
	var final := _apply_attack_mult(ctx, source, amount)
	ctx.damage_enemy(final, enemies[randi() % enemies.size()])
	ctx.battle_flags["last_damage"] = final


static func _apply_attack_mult(ctx: BattleContext, source: BallBase, amount: int) -> int:
	if source == null or not is_instance_valid(source):
		return amount
	var mult := float(ctx.ball_status_for(source).get("attack_mult", 1.0))
	if mult == 1.0:
		return amount
	return int(round(float(amount) * mult))


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
	var ball_rank := randi_range(1, 3)
	# Always spread from the drop-zone centre so balls don't cluster on one side.
	var centre: Vector2
	if ctx.controller != null and ctx.controller.has_method("drop_zone_global"):
		centre = ctx.controller.drop_zone_global()
		if centre == Vector2.ZERO:
			centre = _safe_origin(ctx, source)
	else:
		centre = _safe_origin(ctx, source)
	var spawn_pos := centre + Vector2(randf_range(-80.0, 80.0), -30.0)
	ctx.spawn_ball("ball_normal", spawn_pos,
			Vector2(randf_range(-40.0, 40.0), 0.0), ball_rank)


# ── Ball manipulation ─────────────────────────────────────────────────────────

static func _upgrade_random_ball(ctx: BattleContext, by: int) -> void:
	var balls := ctx.active_balls()
	if balls.is_empty():
		return
	var ball := balls[randi() % balls.size()] as BallBase
	ball.rank = clampi(ball.rank + by, 1, 7)
	ball.refresh()


## Same as _upgrade_random_ball but also plays the green expanding ring at the upgraded ball.
static func _upgrade_random_ball_with_fx(ctx: BattleContext, by: int) -> void:
	var balls := ctx.active_balls()
	if balls.is_empty():
		return
	var ball := balls[randi() % balls.size()] as BallBase
	ball.rank = clampi(ball.rank + by, 1, 7)
	ball.refresh()
	_spawn_merge_ring(ctx, ball.global_position)


static func _spawn_merge_ring(ctx: BattleContext, world_pos: Vector2) -> void:
	if ctx.controller == null:
		return
	const RingScript := preload("res://scenes/visual_effects/merge_ring_effect.gd")
	var ring: Node2D = Node2D.new()
	ring.set_script(RingScript)
	ring.global_position = world_pos
	ctx.controller.add_child(ring)
	ring.play()


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


## Bomb Orb: 10-second countdown displayed on all enemies, then deals 50 to all.
static func _schedule_bomb_orb(ctx: BattleContext) -> void:
	if ctx.controller == null:
		return
	var tree: SceneTree = ctx.controller.get_tree() as SceneTree
	if tree == null:
		return
	const TICKS   := 10
	const DAMAGE  := 50
	ctx.battle_flags["bomb_orb_ticks"] = TICKS
	# Tick down every second
	for i in range(1, TICKS + 1):
		var t: SceneTreeTimer = tree.create_timer(float(i), true, false, true)
		var remaining := TICKS - i
		t.timeout.connect(func():
			ctx.battle_flags["bomb_orb_ticks"] = remaining
			if ctx.controller != null and ctx.controller.has_method("_sync_status_tags_public"):
				ctx.controller._sync_status_tags_public()
		)
	# Detonate at the end
	var det: SceneTreeTimer = tree.create_timer(float(TICKS), true, false, true)
	det.timeout.connect(func():
		ctx.battle_flags["bomb_orb_ticks"] = 0
		if ctx.controller != null and ctx.controller.has_method("damage_all_enemies"):
			ctx.controller.damage_all_enemies(DAMAGE, ctx)
	)


# ── Chain Spark ───────────────────────────────────────────────────────────────

static func _chain_spark(ctx: BattleContext) -> void:
	var enemies := _alive_enemies(ctx)
	if enemies.is_empty():
		return
	var dmg := 20
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
	st["attack_mult"]   = 3.0
	st["trigger_twice"] = false
	st["is_giant"]      = true
	st["size_mult"]     = 2.0
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
	st["attack_mult"]   = 3.0
	st["trigger_twice"] = true
	st["is_giant"]      = true
	st["size_mult"]     = 2.0
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
	var enemies := _alive_enemies(ctx)
	if enemies.is_empty():
		return
	# 10 random hits: each picks a random enemy and a random enchantment.
	for _i in range(10):
		var target: EnemyBase = enemies[randi() % enemies.size()]
		match randi_range(1, 3):
			1: ctx.add_enemy_status(target, "poison", 8)
			2: ctx.add_enemy_status(target, "burn",   3)
			3: ctx.add_enemy_status(target, "freeze", 3)


# ── Miracle Cascade ───────────────────────────────────────────────────────────

static func _miracle_cascade(ctx: BattleContext, source: BallBase) -> void:
	var r3: Array = [["power_slash", 3], ["pollution", 3], ["fireball", 3],
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


# ── Shower ────────────────────────────────────────────────────────────────────

static func _one_shower(ctx: BattleContext, source: BallBase) -> void:
	if ctx.controller == null:
		return
	var tree: SceneTree = ctx.controller.get_tree() as SceneTree
	if tree == null:
		return
	for i in range(12):
		var t: SceneTreeTimer = tree.create_timer(float(i), true, false, true)
		t.timeout.connect(func():
			if ctx.controller == null:
				return
			# INF lets BattleBallManager pick a fully random local X inside the box.
			ctx.drop_element_ball_in_box(randi_range(1, 3), INF)
		)


# ── Regeneration ──────────────────────────────────────────────────────────────

static func _regeneration(ctx: BattleContext) -> void:
	if ctx.controller == null:
		return
	var tree: SceneTree = ctx.controller.get_tree() as SceneTree
	if tree == null:
		return
	for i in range(1, 11):
		var t: SceneTreeTimer = tree.create_timer(float(i), true, false, true)
		t.timeout.connect(func():
			if ctx.controller != null:
				ctx.heal_player(3)
		)


# ── Guillotine ────────────────────────────────────────────────────────────────

static func _guillotine(ctx: BattleContext, source: BallBase) -> void:
	var target := ctx.active_enemy()
	if target == null:
		return
	var missing := target.max_health() - target.health()
	var dmg := maxi(1, int(round(float(missing) * 0.25)))
	ctx.damage_enemy(dmg, target)


# ── Thunder Fang ──────────────────────────────────────────────────────────────

static func _thunder_fang(ctx: BattleContext) -> void:
	var target := ctx.active_enemy()
	if target == null:
		return
	for e in _alive_enemies(ctx):
		var dmg := maxi(1, int(round(float(e.health()) * 0.05)))
		ctx.damage_enemy(dmg, e)
		if e == target:
			ctx.add_enemy_status(e, "thunder", 5)
		else:
			ctx.add_enemy_status(e, "thunder", 3)


# ── Chaos Slash ───────────────────────────────────────────────────────────────

static func _chaos_slash(ctx: BattleContext) -> void:
	var enemies := _alive_enemies(ctx)
	var hit_player := false
	for _i in range(5):
		var pool_size := enemies.size() + 1
		if pool_size == 1:
			# No enemies — all hits land on player
			ctx._damage_player_raw(15)
			hit_player = true
			continue
		var idx := randi() % pool_size
		if idx < enemies.size():
			ctx.damage_enemy(15, enemies[idx])
		else:
			ctx._damage_player_raw(15)
			hit_player = true
	if hit_player:
		ctx.battle_flags["fragile_stacks"] = \
				int(ctx.battle_flags.get("fragile_stacks", 0)) + 1


# ── Storm Surge ───────────────────────────────────────────────────────────────

static func _storm_surge(ctx: BattleContext) -> void:
	for e in _alive_enemies(ctx):
		var dmg := maxi(1, int(round(float(e.max_health()) * 0.10)))
		ctx.damage_enemy(dmg, e)
		ctx.add_enemy_status(e, "thunder", 20)


# ── Baator's Flame ────────────────────────────────────────────────────────────

static func _baators_flame(ctx: BattleContext) -> void:
	var now := ctx.now_ms()
	for e in _alive_enemies(ctx):
		var st := ctx.status_for_enemy(e)
		var poison  := int(st.get("poison_stack",  0))
		var thunder := int(st.get("thunder_stack", 0))
		var freeze_ms := int(st.get("freeze_until_ms", 0))
		var freeze_secs := maxi(0, (freeze_ms - now) / 1000)
		var burn_gain := int(round(float(poison)      * 1.5)) \
					   + int(round(float(thunder)     * 2.0)) \
					   + int(round(float(freeze_secs) * 10.0))
		st["poison_stack"]    = 0
		st["thunder_stack"]   = 0
		st["freeze_until_ms"] = 0
		if burn_gain > 0:
			ctx.add_enemy_status(e, "burn", burn_gain)


# ── Thunder Strike ────────────────────────────────────────────────────────────

static func _thunder_strike(ctx: BattleContext) -> void:
	for e in _alive_enemies(ctx):
		var stacks := int(ctx.status_for_enemy(e).get("thunder_stack", 0))
		if stacks <= 0:
			continue
		var dmg := maxi(1, int(round(float(e.health()) * float(stacks) * 0.02)))
		ctx.damage_enemy(dmg, e)


# ── Elbaph's Power ────────────────────────────────────────────────────────────

static func _elbaphs_power(ctx: BattleContext) -> void:
	ctx.battle_flags["elbaphs_power_start_ms"] = ctx.now_ms()
	for ball in ctx.active_balls():
		var st := ctx.ball_status_for(ball)
		st["elbaphs_power"] = true
		st["attack_mult"]   = 1.0
		st["size_mult"]     = 1.0


# ── Alive enemies helper ──────────────────────────────────────────────────────

static func _alive_enemies(ctx: BattleContext) -> Array:
	var out: Array = []
	if ctx.controller == null or not ctx.controller.has_method("_alive_enemy_slots"):
		return out
	for slot in ctx.controller._alive_enemy_slots():
		if slot != null and slot.enemy != null and slot.enemy.is_alive():
			out.append(slot.enemy)
	return out
