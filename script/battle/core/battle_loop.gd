extends Node2D
class_name BattleLoop

const BallBase := preload("res://script/entities/balls/ball_base.gd")
const EnemyBase := preload("res://script/entities/enemies/enemy_base.gd")
const BattleContext := preload("res://script/battle/core/battle_context.gd")
const BattleResolver := preload("res://script/battle/core/battle_resolver.gd")
const BattleBallManager := preload("res://script/battle/controllers/battle_ball_manager.gd")
const EnemySlotController := preload("res://script/battle/controllers/enemy_slot_controller.gd")
const RewardSelectionController := preload("res://script/battle/controllers/reward_selection_controller.gd")
const BattleHudAdapter := preload("res://script/battle/ui/battle_hud_adapter.gd")
const REWARD_SELECTION_SCENE := preload("res://scenes/reward_selection.tscn")
const CURRENT_ABILITY_SCENE := preload("res://scenes/current_ability.tscn")
const Effects := preload("res://script/battle/core/general_effects.gd")
const sound := preload("res://script/game_manager/sound_manager.gd")
const PlaygroundOverlayScript := preload("res://script/map/playground_overlay.gd")

const BURST_AREA_RADIUS := 320.0
const BURST_STRENGTH := 35.0
const DESTROYING_META := "_battle_destroying"
const PLAYER_DAMAGE_COLOR := Color(1, 0.3, 0.3)
const ENEMY_DAMAGE_COLOR := Color(0.92, 0.58, 0.06)
const HEAL_COLOR := Color(0.35, 0.92, 0.55)
const MERGE_SETTLE_TIME := 0.5
const SHOOT_BURST_STRENGTH_MULT := 10.0
const SLOW_MO_SCALE := 0.2
const HOLD_ACTION := "hold_ball"

var _context := BattleContext.new(self)
var _resolver := BattleResolver.new()
var _box: BattleBallManager
var _hud: BattleHudAdapter
var _turn_running := false
var _selected_enemy_index := 0
var _enemy_slots: Array = []

var _reward_overlay: RewardSelectionController
var _elbaphs_update_acc := 0.0
var _current_ability_overlay: CanvasLayer
var _paused_for_ability_overlay := false
var _playground_overlay: CanvasLayer

@onready var _root := get_tree().current_scene as Node2D
@onready var _ball_placeholder := _root.get_node("BallHolder/BallPlaceholder") as BallBase
@onready var _line_indicator := _root.get_node("BallHolder/LineIndicator")
@onready var _target := _root.get_node("Aim") as Node2D
@onready var _target_area := _target.get_node("Area2D") as Area2D
@onready var _player := _root.get_node("PlayerHolder/Player")
@onready var _player_bar := _root.get_node("UI/StatsHUD/Row/PlayerHealthBar/Background") as ColorRect
@onready var _player_fill := _root.get_node("UI/StatsHUD/Row/PlayerHealthBar/Fill") as ColorRect
@onready var _player_hp_label := _root.get_node("UI/StatsHUD/Row/PlayerHealthBar/Label") as Label
@onready var _player_status_label := _root.get_node_or_null("UI/StatsHUD/Row/PlayerHealthBar/Status") as Label
var _player_shield_fill: ColorRect = null
@onready var _player_damage_anchor := _root.get_node("PlayerHolder/DamageAnchorPlayer") as Marker2D
@onready var _enemy_slot_root := _root.get_node("EnemySlot") as Node2D
@onready var _ui_root := _root.get_node("UI") as CanvasLayer
@onready var _ability_button := _root.get_node_or_null("UI/BallQueue/InspectAbilityButton") as Button


func _ready() -> void:
	_hud = BattleHudAdapter.new(_ui_root)
	_enemy_slots = _build_enemy_slots()
	if _ability_button != null:
		_ability_button.pressed.connect(_on_inspect_ability_requested)
	set_physics_process(false)
	if PlayerState.aim_size_level > 0:
		_target.scale = Vector2.ONE * (1.0 + PlayerState.aim_size_level * 0.25)
	call_deferred("_initialize")


func get_context() -> BattleContext:
	return _context


func _initialize() -> void:
	_inject_playground_overlay_if_needed()
	_begin_battle()


func _inject_playground_overlay_if_needed() -> void:
	var gm := _game_manager()
	if gm == null or not bool(gm.get("is_playground_mode")):
		return
	if _playground_overlay != null and is_instance_valid(_playground_overlay):
		return
	_playground_overlay = PlaygroundOverlayScript.new()
	_playground_overlay.set("_battle_loop", self)
	_root.add_child(_playground_overlay)


func _begin_battle() -> void:
	var gm := _game_manager()
	if gm != null and gm.has_method("get_room_rng_seed"):
		seed(gm.get_room_rng_seed())
	else:
		randomize()
	_context.reset_for_battle()
	if _should_skip_reward_selection():
		_begin_stage()
		return
	_show_reward_selection()


func _physics_process(_delta: float) -> void:
	_handle_ability_overlay_input()
	_step_battle_resolution()
	_handle_selection_input()
	_handle_hold_input()
	_update_enemy_realtime_views()
	_update_target_visual()
	_handle_shoot_input()
	_context.tick_enemy_burn(_delta)
	_context.tick_combo(_delta)
	_sync_status_tags()
	_update_elbaphs_power(_delta)


func _handle_ability_overlay_input() -> void:
	if not Input.is_action_just_pressed("inspect_ability"):
		return
	_on_inspect_ability_requested()


func _step_battle_resolution() -> void:
	if _context.resolving_board:
		_resolver.resolve_frame(_context)


func _handle_selection_input() -> void:
	if Input.is_action_just_pressed("left"):
		if _step_enemy_selection(-1):
			sync_enemy_views()
	elif Input.is_action_just_pressed("right"):
		if _step_enemy_selection(1):
			sync_enemy_views()


func _update_enemy_realtime_views() -> void:
	for slot in _enemy_slots:
		slot.sync_realtime_view()


func _update_target_visual() -> void:
	_target.position = _root.get_local_mouse_position()
	_target.visible = _context.slow_mo_active


func _handle_hold_input() -> void:
	if _context.phase != BattleContext.Phase.PLAY or _context.slow_mo_active:
		return
	if not Input.is_action_just_pressed(HOLD_ACTION):
		return
	if _box == null or not is_instance_valid(_context.current_ball):
		return
	if _box.hold_swap(_context.current_ball):
		track_ball(_context.current_ball)


func _handle_shoot_input() -> void:
	if _context.slow_mo_active:
		if Input.is_action_just_pressed("drop"):
			if _context.can_shoot():
				try_shoot(_target_area, _target.global_position)
			_exit_slow_mo()
		elif Input.is_action_just_pressed("shoot"):
			_exit_slow_mo()
		return
	if _context.phase == BattleContext.Phase.PLAY \
		and Input.is_action_just_pressed("shoot") \
		and _can_enter_action_mode():
		_enter_slow_mo()


func _can_enter_action_mode() -> bool:
	if int(_context.player_statuses.get("freeze_stacks", 0)) > 0:
		return false
	return _context.can_shoot()


func ensure_ball_in_play() -> void:
	if _context.phase != BattleContext.Phase.PLAY or is_instance_valid(_context.current_ball):
		return
	_context.current_ball = spawn_setup_ball()
	
	track_ball(_context.current_ball)


func try_shoot(target_area: Area2D, burst_origin: Vector2) -> void:
	if _context.phase != BattleContext.Phase.PLAY or not _context.try_consume_shot():
		return
	var hit_balls := _targeted_balls(target_area)
	# Set up per-shoot tracking flags for Tide Turner and friends
	_context.battle_flags["shoot_ball_count"] = hit_balls.size()
	_context.battle_flags["shoot_damage_acc"]  = 0
	for ball in hit_balls:
		ball.on_shot(_context)
	# Tide Turner: deal X × total_shoot_damage right after all on_shot calls
	if bool(_context.battle_flags.get("tide_turner_pending", false)):
		_context.battle_flags.erase("tide_turner_pending")
		var ball_count := int(_context.battle_flags.get("shoot_ball_count", 1))
		var shoot_dmg  := int(_context.battle_flags.get("shoot_damage_acc",  0))
		if ball_count >= 2 and shoot_dmg > 0:
			damage_enemy(ball_count * shoot_dmg, active_enemy(), _context)
	sound.play_sound_from_string("shotgun")
	var effects = Effects.new()
	_root.add_child(effects)
	effects.shake(SHOOT_BURST_STRENGTH_MULT)
	burst_knock_on_balls(burst_origin, SHOOT_BURST_STRENGTH_MULT * 5.0)


func _complete_turn_after_drop() -> void:
	if _turn_running or _context.phase != BattleContext.Phase.PLAY:
		return
	_turn_running = true
	_clear_current_ball()
	_context.begin_resolution()
	await get_tree().create_timer(MERGE_SETTLE_TIME).timeout
	_end_turn()
	_turn_running = false


func resolve_enemy_turn(enemy: EnemyBase = null) -> void:
	var acting_enemy: EnemyBase = active_enemy() if enemy == null else enemy
	if acting_enemy == null or not acting_enemy.is_alive():
		return
	if not _context.on_enemy_attack_started(acting_enemy):
		return
	# Charm: redirect the attack to a random other enemy
	var charm_st := _context.status_for_enemy(acting_enemy)
	if int(charm_st.get("charm_stack", 0)) > 0:
		_context.set_charm_redirect(acting_enemy)
	acting_enemy.on_turn(_context)
	_context.clear_charm_redirect()
	_context.on_enemy_attack_resolved(acting_enemy)
	_sync_status_tags()


func active_balls() -> Array:
	return _box.active() if _box != null else []


func effect_balls() -> Array:
	var balls := active_balls()
	var current := _context.current_ball as BallBase
	if is_instance_valid(current) and current.is_active_for_effects():
		balls.append(current)
	return balls


func active_enemy() -> EnemyBase:
	var slot: EnemySlotController = _selected_enemy_slot()
	return slot.enemy if slot != null else null


func consume_ball(ball: BallBase, ctx: BattleContext = null) -> void:
	if not is_instance_valid(ball) or ball.is_queued_for_deletion():
		return
	if _context.current_ball == ball:
		_clear_current_ball()
	if ctx != null and not bool(ball.get_meta(DESTROYING_META, false)):
		ball.set_meta(DESTROYING_META, true)
		ball.on_destroy(ctx)
		ball.remove_meta(DESTROYING_META)
		if ball.is_queued_for_deletion():
			return
	if _box != null:
		_box.consume(ball)


func spawn_ball_copy(source: BallBase, offset: Vector2 = Vector2.ZERO) -> BallBase:
	return _box.spawn_copy(source, offset) if _box != null else null


func spawn_ball(ball_id: String, origin_global: Vector2, impulse: Vector2 = Vector2.ZERO, rank: int = 1) -> BallBase:
	return _box.spawn_ball(ball_id, rank, origin_global, impulse) if _box != null else null


func drop_zone_global() -> Vector2:
	return _box.drop_center_global() if _box != null else Vector2.ZERO


func drop_ball_in_box(ball_id: String, rank: int = 1) -> BallBase:
	return _box.drop_ball(ball_id, rank) if _box != null else null


func drop_element_ball_in_box(rank: int, x: float = INF) -> BallBase:
	return _box.drop_element_ball_at_x(rank, x) if _box != null else null


func spawn_setup_ball() -> BallBase:
	return _box.spawn_setup_ball() if _box != null else null


func heal_player(amount: int) -> void:
	if amount <= 0:
		return
	PlayerState.heal(amount)
	_sync_player_bar()
	_hud.show_damage(amount, _player_damage_anchor, HEAL_COLOR)
	# Second Wind cooldown resets when HP climbs back above 30% threshold
	if bool(_context.player_statuses.get("second_wind_cooldown", false)):
		var sw_thresh := int(round(float(PlayerState.player_max_health) * 0.30))
		if PlayerState.player_health >= sw_thresh:
			_context.player_statuses["second_wind_cooldown"] = false


func damage_all_enemies(amount: int, ctx: BattleContext = null) -> void:
	if amount <= 0:
		return
	for slot in _alive_enemy_slots():
		var target: EnemyBase = slot.enemy
		if target != null and target.is_alive():
			damage_enemy(amount, target, ctx)


func damage_enemy(amount: int, enemy: EnemyBase = null, ctx: BattleContext = null) -> void:
	var target: EnemyBase = enemy if enemy != null else active_enemy()
	if amount <= 0 or target == null or not target.is_alive():
		return
	var pre_health := target.health()
	var slot: EnemySlotController = _enemy_slot(target)
	target.flash()
	var applied := target.take_damage_with_context(amount, ctx)
	if applied <= 0:
		return
	if slot != null:
		slot.sync_realtime_view()
		slot.show_damage(applied, ENEMY_DAMAGE_COLOR)
	# Overkill: overflow damage to next alive enemy when this kill is confirmed
	if ctx != null and not target.is_alive():
		if bool(ctx.battle_flags.get("overkill_active", false)):
			var overflow := maxi(0, amount - pre_health)
			if overflow > 0:
				var remain := _alive_enemy_slots()
				if not remain.is_empty():
					damage_enemy(overflow, (remain[0] as EnemySlotController).enemy, ctx)
	if _alive_enemy_slots().is_empty():
		_finish_battle("Stage Clear")


func damage_player(amount: int) -> void:
	if amount <= 0 or PlayerState.player_health <= 0:
		return
	# Corrupt Field: poisoned enemies deal 20% less damage for 1 shoot.
	if bool(_context.battle_flags.get("corrupt_field_active", false)):
		var attacker := active_enemy()
		if attacker != null:
			var atk_st := _context.status_for_enemy(attacker)
			if int(atk_st.get("poison_stack", 0)) > 0:
				amount = int(round(float(amount) * 0.8))
	if _context.should_reflect_damage():
		var attacker := active_enemy()
		if attacker != null:
			damage_enemy(amount, attacker, _context)
		return
	# Charm: redirect attack to a random enemy that isn't the charmed attacker
	var charm_src := _context.charm_redirect_source()
	if charm_src != null:
		var others := _alive_enemies_excluding(charm_src)
		if not others.is_empty():
			damage_enemy(amount, others[randi() % others.size()], _context)
			return
		# Only one enemy (the charmed one) — attack still hits player
	PlayerState.damage(amount)
	_player.flash()
	_sync_player_bar()
	_hud.show_damage(amount, _player_damage_anchor, PLAYER_DAMAGE_COLOR)
	# Second Wind: trigger when HP drops below 30%
	if bool(_context.player_statuses.get("second_wind_ready", false)):
		if PlayerState.player_health > 0 \
				and not bool(_context.player_statuses.get("second_wind_cooldown", false)):
			var sw_thresh := int(round(float(PlayerState.player_max_health) * 0.30))
			if PlayerState.player_health < sw_thresh:
				_context.player_statuses["second_wind_cooldown"] = true
				if not bool(_context.player_statuses.get("second_wind_main_used", false)):
					_context.player_statuses["second_wind_main_used"] = true
					heal_player(int(round(float(PlayerState.player_max_health) * 0.40)))
				else:
					var sw_missing := PlayerState.player_max_health - PlayerState.player_health
					heal_player(maxi(1, int(round(float(sw_missing) * 0.10))))
	if PlayerState.player_health == 0:
		if _context.can_resurrect():
			_context.mark_resurrect_used()
			PlayerState.player_health = max(1, int(PlayerState.player_max_health * 0.2))
			_sync_player_bar()
			return
		_finish_battle("Game Over")


func burst_knock_on_balls(origin_global: Vector2, strength_scale: float = 1.0) -> void:
	var strength := BURST_STRENGTH * strength_scale
	var radius_squared := BURST_AREA_RADIUS * BURST_AREA_RADIUS
	for node in get_tree().get_nodes_in_group("ball"):
		if not node is RigidBody2D:
			continue
		var body := node as RigidBody2D
		if body == _ball_placeholder or body.is_queued_for_deletion():
			continue
		var offset := body.global_position - origin_global
		var distance_squared := offset.length_squared()
		if distance_squared == 0.0 or distance_squared > radius_squared:
			continue
		body.apply_central_impulse(offset.normalized() * (strength))


func sync_mana_hud() -> void:
	_hud.sync_mana(_context.mana_pipes, _context.merge_progress)


func sync_combo_hud() -> void:
	_hud.sync_combo(_context.combo, _context.combo_multiplier(), _context.combo_timer_ratio())


func track_ball(ball) -> void:
	_line_indicator.call("track_ball", ball)
	_sync_ball_hud()


func has_battle_result() -> bool:
	return _context.has_battle_result()


func sync_enemy_views() -> void:
	if _alive_enemy_slots().is_empty():
		_selected_enemy_index = 0
	var selected: EnemySlotController = _selected_enemy_slot()
	for slot in _enemy_slots:
		slot.set_selected(slot == selected)
		slot.sync_view()


func _enter_slow_mo() -> void:
	_context.slow_mo_active = true
	Engine.time_scale = SLOW_MO_SCALE
	sound.play_sound_from_string("slow")


func _exit_slow_mo() -> void:
	_context.slow_mo_active = false
	Engine.time_scale = 1.0
	sound.play_sound_from_string("speed")


func _show_reward_selection() -> void:
	_reward_overlay = REWARD_SELECTION_SCENE.instantiate() as RewardSelectionController
	_reward_overlay.selection_completed.connect(_on_reward_selection_completed)
	_root.add_child(_reward_overlay)


func _on_reward_selection_completed() -> void:
	_reward_overlay = null
	_begin_stage()


func _begin_stage() -> void:
	_context.clear_battle_result()
	_box = BattleBallManager.new(
		_root,
		_ball_placeholder,
		_context,
		_target,
		_on_ball_dropped,
		BattleLoadout.queue_ball_pool_ids()
	)
	_override_enemy_ids_from_stage()
	_spawn_enemies()
	_target.z_index = 999
	_hud.clear_result()
	track_ball(null)
	_sync_player_bar()
	sync_mana_hud()
	set_physics_process(true)
	_begin_turn()


func _on_ball_dropped() -> void:
	_context.consume_freeze_on_ball_drop()
	var burn := int(_context.player_statuses.get("burn_stacks", 0))
	if burn > 0:
		damage_player(burn * 3)
		_context.player_statuses["burn_stacks"] = burn - 1
	var freeze := int(_context.player_statuses.get("freeze_stacks", 0))
	if freeze > 0:
		_context.player_statuses["freeze_stacks"] = freeze - 1
	# Poison Rain: count down the shoot-duration timer.
	var pr := int(_context.battle_flags.get("poison_rain_shoots", 0))
	if pr > 0:
		_context.battle_flags["poison_rain_shoots"] = pr - 1
	# Corrupt Field: the attack-damage debuff lasts exactly 1 shoot.
	if bool(_context.battle_flags.get("corrupt_field_active", false)):
		_context.battle_flags["corrupt_field_active"] = false
	# Fragile: debuff clears after each shoot
	if int(_context.battle_flags.get("fragile_stacks", 0)) > 0:
		_context.battle_flags["fragile_stacks"] = 0
	# Weakness Brand: count down per shoot
	for slot in _alive_enemy_slots():
		var se := (slot as EnemySlotController).enemy
		if se != null:
			var st := _context.status_for_enemy(se)
			var wb := int(st.get("weakness_brand_shoots", 0))
			if wb > 0:
				st["weakness_brand_shoots"] = wb - 1
	_sync_status_tags()
	_complete_turn_after_drop()


func _begin_turn() -> void:
	_context.start_turn()
	sync_enemy_views()
	sync_mana_hud()
	ensure_ball_in_play()


func _end_turn() -> void:
	_context.lock_resolution()
	sync_enemy_views()
	if has_battle_result():
		return
	_begin_turn()


func _clear_current_ball() -> void:
	_context.current_ball = null
	track_ball(null)


func _enemy_slot(enemy: EnemyBase) -> EnemySlotController:
	for slot in _enemy_slots:
		if slot.enemy == enemy:
			return slot
	return null


func _alive_enemy_slots() -> Array:
	var slots: Array = []
	for slot in _enemy_slots:
		if slot.is_alive():
			slots.append(slot)
	return slots


func _alive_enemies_excluding(excluded: EnemyBase) -> Array:
	var out: Array = []
	for slot in _alive_enemy_slots():
		if slot.enemy != null and slot.enemy.is_alive() and slot.enemy != excluded:
			out.append(slot.enemy)
	return out


func _selected_enemy_slot() -> EnemySlotController:
	var slots := _alive_enemy_slots()
	if slots.is_empty():
		return null
	_selected_enemy_index = wrapi(_selected_enemy_index, 0, slots.size())
	return slots[_selected_enemy_index] as EnemySlotController


func _step_enemy_selection(step: int) -> bool:
	var count := _alive_enemy_slots().size()
	if count <= 1:
		return false
	var next_index := wrapi(_selected_enemy_index + step, 0, count)
	if next_index == _selected_enemy_index:
		return false
	_selected_enemy_index = next_index
	return true


func _spawn_enemies() -> void:
	for slot in _enemy_slots:
		var enemy: EnemyBase = slot.spawn_enemy()
		if enemy != null:
			enemy.action_requested.connect(_on_enemy_action_requested.bind(enemy))


func _sync_player_bar() -> void:
	var bar_visual_w := PlayerHealthBarSync.bar_visual_width(_player_bar)
	var bar_h := _player_bar.size.y
	var hp_frac := float(PlayerState.player_health) / float(maxf(1.0, PlayerState.player_max_health))
	var hp_visual_w := PlayerHealthBarSync.apply_hp_fill(_player_bar, _player_fill, hp_frac)
	_player_hp_label.text = "%d/%d" % [PlayerState.player_health, PlayerState.player_max_health]

	# Shield: golden bar segment defined in .tscn, resolved once here.
	if _player_shield_fill == null:
		_player_shield_fill = _root.get_node_or_null(
				"UI/StatsHUD/Row/PlayerHealthBar/ShieldFill") as ColorRect
	var shield := int(_context.player_statuses.get("shield", 0))
	if shield > 0:
		var shield_frac := minf(float(shield) / float(maxf(1.0, PlayerState.player_max_health)),
				1.0 - hp_frac)
		_player_shield_fill.position = Vector2(_player_fill.position.x + hp_visual_w,
				_player_fill.position.y)
		var shield_visual_w := bar_visual_w * shield_frac
		_player_shield_fill.size = Vector2(
				maxf(0.0, shield_visual_w / maxf(absf(_player_shield_fill.scale.x), 0.0001)),
				bar_h)
		_player_shield_fill.visible = true
	else:
		_player_shield_fill.visible = false

	if _player_status_label != null:
		var tags: Array[String] = []
		if shield > 0:
			tags.append("🛡 %d" % shield)
		var atk := int(_context.player_statuses.get("attack_bonus", 0))
		if atk > 0:
			tags.append("⚔ ATK+%d" % atk)
		if _context.can_resurrect():
			tags.append("✚ Revive")
		if _context.has_reflect_active():
			tags.append("↩ Reflect")
		var pa := int(_context.player_statuses.get("poison_apple_charges", 0))
		if pa > 0:
			tags.append("☠ PA×%d" % pa)
		var cl := int(_context.player_statuses.get("clone_stacks", 0))
		if cl > 0:
			tags.append("✦ Clone×%d" % cl)
		var gk := int(_context.battle_flags.get("gatekeeper_charges", 0))
		if gk > 0:
			tags.append("🔰 GK×%d" % gk)
		if bool(_context.player_statuses.get("second_wind_ready", false)):
			if not bool(_context.player_statuses.get("second_wind_main_used", false)):
				tags.append("💨 2nd Wind")
			else:
				tags.append("💨 2nd Wind+")
		var ls := float(_context.player_statuses.get("direct_damage_heal_ratio", 0.0))
		if ls > 0.0:
			tags.append("🩸 Lifesteal")
		var fr := int(_context.battle_flags.get("fragile_stacks", 0))
		if fr > 0:
			tags.append("💔 Fragile")
		if int(_context.battle_flags.get("elbaphs_power_start_ms", 0)) > 0:
			tags.append("⚡ Elbaph")
		_player_status_label.text = "  ".join(tags)


func _sync_ball_hud() -> void:
	if _box == null:
		_hud.sync_ball_queue({}, [], {})
		return
	_hud.sync_ball_queue(_box.next_entry(), _box.queue_preview(), _box.held_entry())


func _finish_battle(text: String) -> void:
	if _context.has_battle_result():
		return
	if _context.slow_mo_active:
		_exit_slow_mo()
	_context.finish_battle(text)
	_context.phase = BattleContext.Phase.RESOLVE
	_context.lock_resolution()
	_clear_current_ball()
	_target.visible = false
	set_physics_process(false)
	_hud.show_result(text)
	var game_manager := _game_manager()
	if game_manager == null:
		return
	await get_tree().create_timer(1.1).timeout
	if not is_inside_tree():
		return
	if text == "Game Over":
		game_manager.call("restart_run")
		return
	# Playground mode: respawn the enemy and keep testing
	if text == "Stage Clear" and bool(game_manager.get("is_playground_mode")):
		respawn_playground_enemies()
		return
	# Award currency on victory
	if text == "Stage Clear":
		PlayerState.add_gold(_compute_battle_gold_reward())
	if _should_show_post_battle_reward():
		_show_post_battle_reward_selection()
		return
	game_manager.call("complete_current_room")


func _should_show_post_battle_reward() -> bool:
	return true


## Base 50 gold + 15 per 3 combo tier reached this battle.
func _compute_battle_gold_reward() -> int:
	var max_combo := int(_context.battle_flags.get("max_combo_reached", 0))
	var combo_bonus := (max_combo / 3) * 15
	return 50 + combo_bonus


## Called in playground mode when the dummy enemy is defeated — respawn it.
func respawn_playground_enemies() -> void:
	_context.reset_for_battle()
	_hud.clear_result()
	# spawn_enemy() frees the old enemy internally before spawning a new one
	_override_enemy_ids_from_stage()
	_spawn_enemies()
	sync_enemy_views()
	_sync_player_bar()
	sync_mana_hud()
	set_physics_process(true)
	_begin_turn()


## Dev / hotkey: jump to the same flow as Stage Clear (result → timer → rank reward → map).
func skip_to_post_battle_reward() -> void:
	if not is_inside_tree() or _context == null:
		return
	if _context.has_battle_result():
		return
	_finish_battle("Stage Clear")


func _show_post_battle_reward_selection() -> void:
	if not is_inside_tree():
		return
	if _reward_overlay != null and is_instance_valid(_reward_overlay):
		_reward_overlay.queue_free()
	_reward_overlay = REWARD_SELECTION_SCENE.instantiate() as RewardSelectionController
	_reward_overlay.selection_completed.connect(_on_post_battle_reward_selection_completed)
	_root.add_child(_reward_overlay)


func _on_inspect_ability_requested() -> void:
	if _current_ability_overlay != null and is_instance_valid(_current_ability_overlay):
		return
	if _reward_overlay != null and is_instance_valid(_reward_overlay):
		return
	if _context.has_battle_result():
		return
	if _context.slow_mo_active:
		_exit_slow_mo()
	set_physics_process(false)
	_current_ability_overlay = CURRENT_ABILITY_SCENE.instantiate() as CanvasLayer
	_current_ability_overlay.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	_current_ability_overlay.tree_exited.connect(_on_current_ability_closed)
	_root.add_child(_current_ability_overlay)
	if not get_tree().paused:
		get_tree().paused = true
		_paused_for_ability_overlay = true
	else:
		_paused_for_ability_overlay = false


func _on_current_ability_closed() -> void:
	_current_ability_overlay = null
	if _paused_for_ability_overlay:
		get_tree().paused = false
	_paused_for_ability_overlay = false
	if _context.has_battle_result():
		return
	if _reward_overlay != null and is_instance_valid(_reward_overlay):
		return
	set_physics_process(true)


func _on_post_battle_reward_selection_completed() -> void:
	_reward_overlay = null
	var gm := _game_manager()
	if gm != null:
		gm.complete_current_room()


func _on_enemy_action_requested(enemy: EnemyBase) -> void:
	if has_battle_result():
		return
	resolve_enemy_turn(enemy)


func _targeted_balls(target_area: Area2D) -> Array:
	var hit_balls: Array = []
	for body in target_area.get_overlapping_bodies():
		if not body is BallBase:
			continue
		var ball := body as BallBase
		if ball.can_be_hit_by_shot():
			hit_balls.append(ball)
	return hit_balls


func _build_enemy_slots() -> Array:
	var slots: Array = []
	for child in _enemy_slot_root.get_children():
		if not child is Node2D:
			continue
		var slot := child as Node2D
		var spawn := _spawn_marker_for_slot(slot)
		slots.append(EnemySlotController.new(slot, spawn, _enemy_id_for_slot(spawn)))
	return slots


func _spawn_marker_for_slot(slot: Node2D) -> Marker2D:
	for child in slot.get_children():
		if child is Marker2D and child.name.begins_with("EnemySpawn"):
			return child as Marker2D
	return null


func _enemy_id_for_slot(spawn: Marker2D) -> String:
	if spawn == null or not spawn.name.begins_with("EnemySpawn_"):
		return ""
	return spawn.name.trim_prefix("EnemySpawn_")


func _override_enemy_ids_from_stage() -> void:
	var gm := _game_manager()
	if gm == null or not gm.has_method("get_stage_enemy_ids"):
		return
	var room = gm.active_room() if gm.has_method("active_room") else null
	var row := 0
	if room != null:
		var r = room.get("row")
		if r != null:
			row = int(r)
	var ids: Array = gm.get_stage_enemy_ids(row)
	for i in range(mini(ids.size(), _enemy_slots.size())):
		_enemy_slots[i]._enemy_id = ids[i]


func _game_manager() -> Node:
	return get_node_or_null("/root/GameManager")


func _should_skip_reward_selection() -> bool:
	var game_manager := _game_manager()
	if game_manager == null:
		return false
	if not game_manager.has_method("should_skip_battle_rewards"):
		return false
	return bool(game_manager.call("should_skip_battle_rewards"))


func _sync_status_tags() -> void:
	_sync_player_bar()
	var burn := int(_context.player_statuses.get("burn_stacks", 0))
	var freeze := int(_context.player_statuses.get("freeze_stacks", 0))
	_hud.sync_player_statuses(burn, freeze)
	for slot in _enemy_slots:
		if slot != null and slot.has_method("sync_status_tag"):
			slot.sync_status_tag(_context)


## Public wrapper so external scripts (e.g. bomb timer callbacks) can trigger a status refresh.
func _sync_status_tags_public() -> void:
	_sync_status_tags()


## Public player bar sync used by BattleContext._damage_player_hp_only (Fortress).
func _sync_player_bar_public() -> void:
	_sync_player_bar()


# ── Elbaph's Power: progressively grow all tagged balls over 15 seconds ───────

func _update_elbaphs_power(delta: float) -> void:
	var start_ms := int(_context.battle_flags.get("elbaphs_power_start_ms", 0))
	if start_ms <= 0:
		return
	_elbaphs_update_acc += delta
	if _elbaphs_update_acc < 0.1:
		return
	_elbaphs_update_acc = 0.0
	var elapsed_ms := _context.now_ms() - start_ms
	if elapsed_ms >= 15000:
		_context.battle_flags.erase("elbaphs_power_start_ms")
	var t := clampf(float(elapsed_ms) / 15000.0, 0.0, 1.0)
	var size_mult   := lerpf(1.0, 2.0, t)
	var attack_mult := lerpf(0.5, 1.5, t)
	for ball in active_balls():
		var b := ball as BallBase
		var st := _context.ball_status_for(b)
		if not bool(st.get("elbaphs_power", false)):
			continue
		st["size_mult"]   = size_mult
		st["attack_mult"] = attack_mult
		b._update_collision()
		b.queue_redraw()
