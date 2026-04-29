extends Node2D

# ── Preloaded scenes (layout lives in .tscn, not in code) ───────────────────
const BALL_SCENE             := preload("res://scenes/plinko/plinko_ball.tscn")
const REWARD_PLATFORM_SCENE  := preload("res://scenes/plinko/plinko_reward_platform.tscn")
const CROSSHAIR_TEX          := preload("res://assets/Target.png")

const OBSTACLE_SCENES: Array = [
	"res://scenes/plinko/obstacle_classic.tscn",
	"res://scenes/plinko/obstacle_hybrid.tscn",
	"res://scenes/plinko/obstacle_moving_sweeper.tscn",
	"res://scenes/plinko/obstacle_tier_funnel.tscn",
]

# ── Tunable game parameters — set in Inspector / stored in .tscn ─────────────
@export var max_drops          := 4
@export var ball_radius        := 9.0
@export var ball_drop_impulse  := 40.0
@export var obstacle_origin_y  := -60.0   ## Y offset of obstacle root in PlatformsRoot space

# ── Reward-row configuration (value, count, y, spacing, color) ───────────────
@export var reward_row_values:   Array[int]   = [1, 2, 3, 5]
@export var reward_row_counts:   Array[int]   = [4, 2, 2, 1]
@export var reward_row_ys:       Array[float] = [-53.0, 5.0, 59.0, 112.0]
@export var reward_row_spacings: Array[float] = [48.0, 52.0, 52.0, 0.0]

# ── Interior bounds (must match Interior polygon + PlatformsRoot offset) ─────
const _INT_MARGIN   := 14.0
const _IX0          := -174.0 + _INT_MARGIN
const _IX1          :=  176.0 - _INT_MARGIN
const _IY0          := -218.0 + _INT_MARGIN
const _IY1          :=  168.0 - _INT_MARGIN
const _REWARD_HALF_W := 26.0

# ── Reward row colors (parallel to reward_row_* arrays) ──────────────────────
const _ROW_COLORS: Array = [
	Color(0.45, 0.75, 0.42),
	Color(0.42, 0.62, 0.88),
	Color(0.78, 0.52, 0.35),
	Color(0.82, 0.42, 0.72),
]
const _BONUS8_COLOR := Color(0.98, 0.84, 0.28)

# ── Node references ───────────────────────────────────────────────────────────
@onready var _earnings_label := $PlinkoUI/EarningsLabel  as Label
@onready var _cost_label     := $PlinkoUI/CostLabel      as Label
@onready var _win_label      := $PlinkoUI/WinLabel       as Label
@onready var _drop_hint      := $PlinkoUI/DropHint       as Label
@onready var _platforms_root := $Background/Box/PlatformsRoot as Node2D
@onready var _guide_line     := $Background/LimitSeparation/GuideLine as Line2D
@onready var _limit_sep      := $Background/LimitSeparation as Node2D
@onready var _camera         := $Camera2D as Camera2D
@onready var _gun_root       := $Background/GunRoot      as Node2D
@onready var _gun_sprite     := $Background/GunRoot/GunSprite as Sprite2D
@onready var _solo_target    := $Background/Box/SoloTarget as Node2D
@onready var _shoot_fx       := $ShootFX                 as Node2D
@onready var _laser          := $ShootFX/Laser           as Line2D
@onready var _crosshair      := $ShootFX/Crosshair       as Sprite2D

# ── Runtime state ─────────────────────────────────────────────────────────────
var _drops_remaining         := 0
var _round_scores: Array[int] = []
var _active_ball: RigidBody2D
var _active_ball_first_reward := -1
var _ball_alive_time          := 0.0
var _time_since_reward        := 0.0
var _finishing                := false
var _shot_busy                := false
var _drop_y_local             := 0.0
var _drop_x_local_min         := 0.0
var _drop_x_local_max         := 0.0
var _despawn_y_local          := INF
var _below_despawn_elapsed    := -1.0
var _stuck_elapsed            := 0.0
var _guide_pulse_t            := 0.0
var _guide_base_color         := Color(0.88, 0.84, 0.95, 0.55)
var _guide_base_width         := 3.0
var _shake_time_left          := 0.0
var _shake_strength           := 0.0
var _shake_duration_total     := 0.0
var _camera_base_offset       := Vector2.ZERO


func _ready() -> void:
	var gm := get_node_or_null("/root/GameManager")
	if gm != null and gm.has_method("get_room_rng_seed"):
		seed(gm.get_room_rng_seed())

	_drops_remaining = max_drops
	_crosshair.texture = CROSSHAIR_TEX
	_crosshair.visible = false
	_laser.clear_points()
	_guide_base_color = _guide_line.default_color
	_guide_base_width = _guide_line.width
	_camera_base_offset = _camera.offset

	# Bounds are computed once node transforms are resolved.
	_refresh_drop_bounds_from_guide()
	call_deferred("_refresh_drop_bounds_from_guide")
	call_deferred("_build_playfield")
	_refresh_drop_ui()


# ── Drop-line bounds from the visual GuideLine node ───────────────────────────

func _refresh_drop_bounds_from_guide() -> void:
	if _guide_line == null or not is_instance_valid(_guide_line) \
			or _guide_line.get_point_count() < 2:
		return
	var p0 := _guide_line.to_global(_guide_line.get_point_position(0))
	var p1 := _guide_line.to_global(_guide_line.get_point_position(1))
	# Match battle_ball_manager style: keep drop bounds in this node's local space.
	_drop_y_local = to_local((p0 + p1) * 0.5).y
	_drop_x_local_min = minf(p0.x, p1.x) - global_position.x + ball_radius
	_drop_x_local_max = maxf(p0.x, p1.x) - global_position.x - ball_radius


# ── Playfield builder ─────────────────────────────────────────────────────────

func _build_playfield() -> void:
	for c in _platforms_root.get_children():
		_platforms_root.remove_child(c)
		c.free()
	_despawn_y_local = INF

	# Pick and place a random obstacle layout from the scene files.
	var path   := OBSTACLE_SCENES[randi() % OBSTACLE_SCENES.size()] as String
	var packed := load(path) as PackedScene
	var obs    := packed.instantiate() as Node2D
	obs.position = Vector2(0.0, obstacle_origin_y)
	_apply_tiny_inward_tilts(obs)
	_ensure_lane_blocking(obs)
	_platforms_root.add_child(obs)

	# Spawn reward rows.
	var rows := _roll_reward_rows()
	for row in rows:
		var value := int(row.value)
		var y_c := float(row.y)
		_add_reward_row(
			value,
			int(row.count),
			y_c,
			float(row.spacing),
			row.color as Color
		)
		if value == 5:
			_despawn_y_local = to_local(_platforms_root.to_global(Vector2(0.0, y_c))).y
	if is_inf(_despawn_y_local):
		_despawn_y_local = to_local(_platforms_root.to_global(Vector2(0.0, _IY1 - 8.0))).y
	_add_side_guard_pegs(obs, rows)


func _roll_reward_rows() -> Array:
	var c1 := randi_range(1, 3)
	var c2 := randi_range(1, 3)
	var c3 := randi_range(1, 3)
	var c5 := 1
	var total := c1 + c2 + c3 + c5
	while total < 5:
		var pick := randi_range(1, 3)
		if pick == 1 and c1 < 4:
			c1 += 1
			total += 1
		elif pick == 2 and c2 < 3:
			c2 += 1
			total += 1
		elif pick == 3 and c3 < 3:
			c3 += 1
			total += 1
	var rows: Array = [
		{"value": 1, "count": c1, "y": clampf(reward_row_ys[0], _IY0 + 50.0, _IY1 - 50.0), "spacing": reward_row_spacings[0], "color": _ROW_COLORS[0]},
		{"value": 2, "count": c2, "y": clampf(reward_row_ys[1], _IY0 + 50.0, _IY1 - 50.0), "spacing": reward_row_spacings[1], "color": _ROW_COLORS[1]},
		{"value": 3, "count": c3, "y": clampf(reward_row_ys[2], _IY0 + 50.0, _IY1 - 50.0), "spacing": reward_row_spacings[2], "color": _ROW_COLORS[2]},
		{"value": 5, "count": c5, "y": clampf(reward_row_ys[3], _IY0 + 50.0, _IY1 - 50.0), "spacing": reward_row_spacings[3], "color": _ROW_COLORS[3]},
	]
	if randf() < 0.2:
		var y5 := float(rows[3].y)
		rows.append({
			"value": 8,
			"count": 1,
			"y": clampf(y5 + 28.0, _IY0 + 50.0, _IY1 - 36.0),
			"spacing": 0.0,
			"color": _BONUS8_COLOR
		})
	return rows


func _add_reward_row(value: int, count: int, y_clamped: float,
		spacing: float, col: Color) -> void:
	var starts: Array[float] = []
	match count:
		4: starts = [-spacing * 1.5, -spacing * 0.5, spacing * 0.5, spacing * 1.5]
		2: starts = [-spacing * 0.5, spacing * 0.5]
		_: starts = [0.0]

	for j in range(starts.size()):
		var sx := clampf(starts[j], _IX0 + _REWARD_HALF_W + 4.0, _IX1 - _REWARD_HALF_W - 4.0)
		var plat := _create_reward_platform(value, y_clamped, sx, col, j)
		_platforms_root.add_child(plat)
		plat.reward_hit.connect(_on_reward_hit)


func _create_reward_platform(value: int, y: float, x: float,
		col: Color, idx: int) -> StaticBody2D:
	var plat := REWARD_PLATFORM_SCENE.instantiate() as StaticBody2D
	plat.name        = "Reward_%d_%d" % [value, idx]
	plat.position    = Vector2(x, y)
	plat.point_value = value
	plat.phase       = randf() * TAU
	plat.move_speed  = 0.58 + float(idx % 3) * 0.08
	var width_px := 52.0
	if value == 3:
		width_px = 66.0
	elif value == 5:
		width_px = 84.0
	var half_w := width_px * 0.5
	var want_amp := 28.0 + float(value) * 3.0
	plat.move_amplitude = _clamp_amplitude(x, half_w, want_amp)
	var body_shape := (plat.get_node("Collision") as CollisionShape2D).shape as RectangleShape2D
	body_shape.size.x = width_px
	var vis := plat.get_node("Vis") as Polygon2D
	vis.polygon = PackedVector2Array([
		Vector2(-half_w, -5.0), Vector2(half_w, -5.0),
		Vector2(half_w, 5.0), Vector2(-half_w, 5.0)
	])
	var zone_shape := (plat.get_node("HitZone/ZoneShape") as CollisionShape2D).shape as RectangleShape2D
	zone_shape.size.x = width_px + 6.0
	plat.get_node("Vis").color = col
	var value_label := plat.get_node_or_null("ValueLabel") as Label
	if value_label != null:
		value_label.text = str(value)
	return plat


func _clamp_amplitude(cx: float, hw: float, desired: float) -> float:
	var lim_r    := _IX1 - hw - cx
	var lim_l    := cx - hw - _IX0
	var max_travel := minf(maxf(0.0, lim_l), maxf(0.0, lim_r))
	return minf(desired, max_travel)


func _apply_tiny_inward_tilts(root: Node2D) -> void:
	# Stable platforms get subtle inward tilt; moving scripted platforms stay flat.
	for child in root.get_children():
		if child is StaticBody2D:
			var body := child as StaticBody2D
			if body.get_script() != null:
				body.rotation = 0.0
				if "period_seconds" in body:
					body.period_seconds *= 1.45
				continue
			if absf(body.rotation) < 0.001:
				if body.position.x < -1.0:
					body.rotation = 0.06
				elif body.position.x > 1.0:
					body.rotation = -0.06
				else:
					body.rotation = 0.03


func _ensure_lane_blocking(root: Node2D) -> void:
	# Keep most top-to-bottom lanes interrupted by symmetric obstacle additions.
	var lanes_abs := PackedFloat32Array([42.0, 84.0, 128.0])
	var pair_blocked := {}
	for lane_abs in lanes_abs:
		pair_blocked[lane_abs] = false
	for child in root.get_children():
		if child is StaticBody2D:
			var body := child as StaticBody2D
			for lane_abs in lanes_abs:
				if absf(absf(body.position.x) - lane_abs) <= 22.0:
					pair_blocked[lane_abs] = true
	var blocked_pairs := 0
	for lane_abs in lanes_abs:
		if bool(pair_blocked[lane_abs]):
			blocked_pairs += 1
	if blocked_pairs >= 3:
		return
	var y_slots := [-128.0, -96.0, -64.0, -30.0, 4.0]
	for lane_abs in lanes_abs:
		if bool(pair_blocked[lane_abs]):
			continue
		var y = y_slots[randi() % y_slots.size()]
		root.add_child(_make_blocker_peg(Vector2(-lane_abs, y)))
		root.add_child(_make_blocker_peg(Vector2(lane_abs, y)))
		blocked_pairs += 1
		if blocked_pairs >= 3:
			break


func _make_blocker_peg(pos: Vector2) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.position = pos
	var pm := PhysicsMaterial.new()
	pm.bounce = 0.45
	pm.friction = 0.35
	body.physics_material_override = pm
	var sh := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 6.5
	sh.shape = circle
	body.add_child(sh)
	var vis := Polygon2D.new()
	vis.color = Color(0.84, 0.8, 0.93)
	vis.polygon = PackedVector2Array([
		Vector2(0, -7), Vector2(6, 0), Vector2(0, 7), Vector2(-6, 0)
	])
	body.add_child(vis)
	return body


func _add_side_guard_pegs(root: Node2D, rows: Array) -> void:
	# Add two mirrored fixed peg sets that lean inward: "\" on left and "/" on right.
	var edge_clearance := 28.0
	var safe_side_x := minf(absf(_IX0), absf(_IX1)) - edge_clearance
	var y_candidates: Array[float] = []
	for row in rows:
		y_candidates.append(float(row.y))
	y_candidates.sort()
	if y_candidates.size() < 2:
		return
	var y_top := y_candidates[0]
	var y_bottom := y_candidates[min(2, y_candidates.size() - 1)]
	var x_outer := safe_side_x
	var x_inner := safe_side_x - 18.0
	root.add_child(_make_blocker_peg(Vector2(-x_outer, y_top)))
	root.add_child(_make_blocker_peg(Vector2(-x_inner, y_bottom)))
	root.add_child(_make_blocker_peg(Vector2(x_outer, y_top)))
	root.add_child(_make_blocker_peg(Vector2(x_inner, y_bottom)))


# ── Gun tip helper ────────────────────────────────────────────────────────────

func _gun_barrel_tip_global() -> Vector2:
	if _gun_sprite != null and is_instance_valid(_gun_sprite) \
			and _gun_sprite.texture != null:
		var w         := float(_gun_sprite.texture.get_width())
		var local_tip := Vector2(-w * 0.42 * _gun_sprite.scale.x, 0.0)
		return _gun_sprite.to_global(local_tip)
	return _gun_root.to_global(Vector2(-52.0, 2.0))


# ── Reward-hit → gun feedback ─────────────────────────────────────────────────

func _on_reward_hit(value: int, body: Node2D, platform: Node2D) -> void:
	if _shot_busy or _finishing:
		return
	if body != _active_ball or not is_instance_valid(_active_ball):
		return
	if _active_ball_first_reward >= 0:
		return
	_shot_busy = true
	_active_ball_first_reward = value
	_time_since_reward = 0.0
	# Let physics resolve the bounce on the value platform before cleanup.
	await get_tree().create_timer(0.1).timeout
	if platform != null and is_instance_valid(platform):
		platform.queue_free()
	_finalize_active_ball()
	await _play_gun_hit_feedback(value)
	_shot_busy = false


func _play_gun_hit_feedback(_value: int) -> void:
	_start_screen_shake(0.22, 7.5)
	var aim := _solo_target.global_position
	var tip := _gun_barrel_tip_global()
	_crosshair.global_position = aim
	_crosshair.visible = true
	_crosshair.scale   = Vector2(0.05, 0.05)
	_laser.width = 0.0
	_laser.default_color = Color(1.0, 0.88, 0.28, 0.0)
	_laser.clear_points()
	var old_ts := Engine.time_scale
	Engine.time_scale = 0.34
	var tw := create_tween()
	tw.tween_property(_crosshair, "scale", Vector2(0.2, 0.2), 0.14) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tw.finished
	await get_tree().create_timer(0.18).timeout
	if _solo_target.has_method("flash_twice"):
		await _solo_target.flash_twice()
	_crosshair.visible = false
	_laser.clear_points()
	Engine.time_scale = old_ts
	_show_win("Hit %d!" % _value)


func _tween_laser_alpha(a: float) -> void:
	var c   := _laser.default_color
	c.a     = a
	_laser.default_color = c


# ── Ball lifecycle ────────────────────────────────────────────────────────────

func _process(delta: float) -> void:
	_update_guide_shine(delta)
	_update_screen_shake(delta)


func _update_guide_shine(delta: float) -> void:
	_guide_pulse_t += delta * 2.8
	var glow := 0.5 + 0.5 * sin(_guide_pulse_t)
	var c := _guide_base_color
	c.a = lerpf(0.45, 0.92, glow)
	_guide_line.default_color = c
	_guide_line.width = lerpf(_guide_base_width, _guide_base_width + 1.6, glow)
	for child in _limit_sep.get_children():
		if child is Sprite2D and child.name.begins_with("Indicator"):
			var spr := child as Sprite2D
			var m := spr.modulate
			m.a = lerpf(0.35, 0.95, glow)
			spr.modulate = m


func _start_screen_shake(duration: float, strength: float) -> void:
	_shake_duration_total = maxf(_shake_duration_total, duration)
	_shake_time_left = maxf(_shake_time_left, duration)
	_shake_strength = maxf(_shake_strength, strength)


func _update_screen_shake(delta: float) -> void:
	if _shake_time_left <= 0.0:
		if _camera.offset != _camera_base_offset:
			_camera.offset = _camera_base_offset
		_shake_duration_total = 0.0
		return
	_shake_time_left = maxf(0.0, _shake_time_left - delta)
	var t := _shake_time_left / maxf(0.001, _shake_duration_total)
	var amp := _shake_strength * t
	_camera.offset = _camera_base_offset + Vector2(randf_range(-amp, amp), randf_range(-amp, amp))

func _physics_process(delta: float) -> void:
	if _active_ball == null or not is_instance_valid(_active_ball):
		return
	var spd := _active_ball.linear_velocity.length()
	if spd < 7.0:
		_stuck_elapsed += delta
		if _stuck_elapsed >= 2.0:
			_finalize_active_ball()
			return
	else:
		_stuck_elapsed = 0.0
	if not is_inf(_despawn_y_local):
		if _active_ball.position.y > _despawn_y_local:
			if _below_despawn_elapsed < 0.0:
				_below_despawn_elapsed = 0.0
			else:
				_below_despawn_elapsed += delta
				if _below_despawn_elapsed >= 1.0:
					_finalize_active_ball()
					return
		else:
			_below_despawn_elapsed = -1.0
	_ball_alive_time += delta
	if _ball_alive_time > 14.0:
		_finalize_active_ball()


func _unhandled_input(event: InputEvent) -> void:
	if _finishing or _drops_remaining <= 0 or _shot_busy:
		return
	if not (event is InputEventMouseButton
			and event.pressed
			and event.button_index == MOUSE_BUTTON_LEFT):
		return
	if _active_ball != null and is_instance_valid(_active_ball):
		return
	var mouse_x_local := get_local_mouse_position().x
	var drop_x_local := clampf(mouse_x_local, _drop_x_local_min, _drop_x_local_max)
	_drop_ball(Vector2(drop_x_local, _drop_y_local))


func _drop_ball(local_pos: Vector2) -> void:
	_drops_remaining -= 1
	_refresh_drop_ui()
	_active_ball_first_reward = -1
	_ball_alive_time    = 0.0
	_time_since_reward  = 0.0
	_below_despawn_elapsed = -1.0
	_stuck_elapsed = 0.0

	var ball := BALL_SCENE.instantiate() as RigidBody2D
	ball.add_to_group("plinko_ball")
	add_child(ball)
	# Same pattern as combat manager: local spawn position in root space.
	ball.position = local_pos
	ball.apply_central_impulse(
		Vector2(randf_range(-ball_drop_impulse, ball_drop_impulse), 0.0))
	_active_ball = ball


func _finalize_active_ball() -> void:
	if _active_ball == null or not is_instance_valid(_active_ball):
		_active_ball = null
		_check_end()
		return
	var b := _active_ball
	_active_ball = null
	var v := _active_ball_first_reward if _active_ball_first_reward >= 0 else 0
	_active_ball_first_reward = -1
	_ball_alive_time   = 0.0
	_time_since_reward = 0.0
	_below_despawn_elapsed = -1.0
	_stuck_elapsed = 0.0
	_round_scores.append(v)
	b.queue_free()
	_show_win("Round: +%d pts" % v if v > 0 else "Round: 0 pts")
	_check_end()


func _check_end() -> void:
	if _drops_remaining > 0 or _finishing:
		return
	_finishing = true
	var total := 0
	for s in _round_scores:
		total += s
	if is_instance_valid(_earnings_label):
		_earnings_label.text = "Done — score %d pts" % total
	await get_tree().create_timer(1.4).timeout
	if is_inside_tree():
		GameManager.complete_current_room()


func _on_leave() -> void:
	if _finishing:
		return
	GameManager.complete_current_room()


# ── UI helpers ────────────────────────────────────────────────────────────────

func _refresh_drop_ui() -> void:
	_cost_label.text = "Drops left: %d / %d" % [_drops_remaining, max_drops]
	_drop_hint.text  = "Click to drop"


func _show_win(text: String) -> void:
	_win_label.text     = text
	_win_label.modulate = Color(1, 0.9, 0.2, 1)
	var tw := create_tween()
	tw.tween_property(_win_label, "modulate:a", 0.0, 1.2)
