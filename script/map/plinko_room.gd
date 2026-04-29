extends Node2D

const BALL_SCENE := preload("res://scenes/plinko/plinko_ball.tscn")

# ── Tweakable parameters (set in Inspector / stored in .tscn) ─────────────────
@export var max_drops            := 4
@export var ball_radius          := 9.0
@export var ball_drop_impulse    := 10.0
@export var indicator_speed      := 120.0   ## px/s, how fast the drop cursor moves
@export var indicator_half_range := 140.0   ## fallback if markers are missing

# ── Node references ───────────────────────────────────────────────────────────
@onready var _earnings_label := $PlinkoUI/EarningsLabel   as Label
@onready var _cost_label     := $PlinkoUI/CostLabel       as Label
@onready var _score_label    := $PlinkoUI/ScoreLabel      as Label
@onready var _win_label      := $PlinkoUI/WinLabel        as Label
@onready var _drop_hint      := $PlinkoUI/DropHint        as Label
@onready var _launch_button  := $PlinkoUI/LaunchButton    as TextureButton
@onready var _drop_indicator := $Background/Box/BallDropLine/DropIndicator as Polygon2D
@onready var _left_marker    := $Background/Box/BallDropLine/Left  as Marker2D
@onready var _right_marker   := $Background/Box/BallDropLine/Right as Marker2D
@onready var _ball_drop_line := $Background/Box/BallDropLine       as Node2D
@onready var _camera         := $Camera2D                          as Camera2D

# ── Runtime state ─────────────────────────────────────────────────────────────
var _drops_remaining      := 0
var _round_scores: Array[int] = []
var _active_ball: RigidBody2D = null
var _ball_resolved        := false
var _ball_alive_time      := 0.0
var _stuck_elapsed        := 0.0
var _finishing            := false

var _indicator_x          := 0.0
var _indicator_dir        := 1.0
var _ind_min_x            := 0.0
var _ind_max_x            := 0.0

var _hint_pulse_t         := 0.0

var _shake_time_left      := 0.0
var _shake_strength       := 0.0
var _shake_duration_total := 0.0
var _camera_base_offset   := Vector2.ZERO


func _ready() -> void:
	var gm := get_node_or_null("/root/GameManager")
	if gm != null and gm.has_method("get_room_rng_seed"):
		seed(gm.get_room_rng_seed())

	_drops_remaining    = max_drops
	_camera_base_offset = _camera.offset

	# Derive indicator oscillation bounds from the Left/Right markers in the scene.
	if is_instance_valid(_left_marker) and is_instance_valid(_right_marker):
		_ind_min_x = _left_marker.position.x + ball_radius
		_ind_max_x = _right_marker.position.x - ball_radius
	else:
		_ind_min_x = -indicator_half_range
		_ind_max_x =  indicator_half_range

	_indicator_x   = 0.0
	_indicator_dir = 1.0
	_drop_indicator.position.x = _indicator_x

	# Connect every reward-slot Area2D defined in the scene.
	var slots_root := get_node_or_null(
			"Background/Box/PlatformsRoot/RewardSlotsRoot") as Node
	if slots_root:
		for child in slots_root.get_children():
			if child is Area2D:
				child.body_entered.connect(_on_slot_body_entered.bind(child))

	_refresh_drop_ui()


# ── Indicator oscillation ─────────────────────────────────────────────────────

func _process(delta: float) -> void:
	_update_indicator(delta)
	_update_hint_shine(delta)
	_update_screen_shake(delta)


func _update_hint_shine(delta: float) -> void:
	if not is_instance_valid(_drop_hint):
		return
	_hint_pulse_t += delta * 2.2
	var glow := 0.5 + 0.5 * sin(_hint_pulse_t)
	var c := _drop_hint.get_theme_color("font_color")
	c.a = lerpf(0.35, 1.0, glow)
	_drop_hint.add_theme_color_override("font_color", c)


func _update_indicator(delta: float) -> void:
	if _finishing:
		return
	_indicator_x += _indicator_dir * indicator_speed * delta
	if _indicator_x >= _ind_max_x:
		_indicator_x  = _ind_max_x
		_indicator_dir = -1.0
	elif _indicator_x <= _ind_min_x:
		_indicator_x  = _ind_min_x
		_indicator_dir = 1.0
	_drop_indicator.position.x = _indicator_x


# ── Ball stuck / timeout watchdog ─────────────────────────────────────────────

func _physics_process(delta: float) -> void:
	if _active_ball == null or not is_instance_valid(_active_ball) or _ball_resolved:
		return
	var spd := _active_ball.linear_velocity.length()
	if spd < 7.0:
		_stuck_elapsed += delta
		if _stuck_elapsed >= 2.5:
			_finalize_active_ball(0)
			return
	else:
		_stuck_elapsed = 0.0
	_ball_alive_time += delta
	if _ball_alive_time > 18.0:
		_finalize_active_ball(0)


# ── Launch button ─────────────────────────────────────────────────────────────

func _on_launch() -> void:
	if _finishing or _drops_remaining <= 0 or _ball_resolved:
		return
	if _active_ball != null and is_instance_valid(_active_ball):
		return
	var drop_global := _ball_drop_line.to_global(Vector2(_indicator_x, 0.0))
	_drop_ball(to_local(drop_global))


func _drop_ball(local_pos: Vector2) -> void:
	_ball_alive_time = 0.0
	_stuck_elapsed   = 0.0
	_drops_remaining -= 1

	var ball := BALL_SCENE.instantiate() as RigidBody2D
	ball.add_to_group("plinko_ball")
	add_child(ball)
	ball.position = local_pos
	ball.apply_central_impulse(
		Vector2(randf_range(-ball_drop_impulse, ball_drop_impulse), 0.0))
	_active_ball = ball
	_refresh_drop_ui()


# ── Reward slot detection ─────────────────────────────────────────────────────

func _on_slot_body_entered(body: Node, slot: Area2D) -> void:
	if _finishing or _ball_resolved:
		return
	if not is_instance_valid(body) or body != _active_ball:
		return
	_ball_resolved = true
	var value := int(slot.get_meta("reward_value", 0))
	_finalize_active_ball(value)


func _finalize_active_ball(value: int) -> void:
	_ball_resolved = false
	if _active_ball != null and is_instance_valid(_active_ball):
		_active_ball.queue_free()
	_active_ball     = null
	_ball_alive_time = 0.0
	_stuck_elapsed   = 0.0
	_round_scores.append(value)
	if value > 0:
		_show_win("+%d pts!" % value)
		_start_screen_shake(0.18, 5.5)
	else:
		_show_win("Miss!")
	_refresh_drop_ui()
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
	var running_total := 0
	for s in _round_scores:
		running_total += s
	_score_label.text = "Score: %d pts" % running_total
	if is_instance_valid(_launch_button):
		var ball_active := _active_ball != null and is_instance_valid(_active_ball)
		_launch_button.disabled = _drops_remaining <= 0 or _finishing \
				or ball_active or _ball_resolved


func _show_win(text: String) -> void:
	_win_label.text     = text
	_win_label.modulate = Color(1, 0.9, 0.2, 1)
	var tw := create_tween()
	tw.tween_property(_win_label, "modulate:a", 0.0, 1.8)


# ── Screen shake ──────────────────────────────────────────────────────────────

func _start_screen_shake(duration: float, strength: float) -> void:
	_shake_duration_total = maxf(_shake_duration_total, duration)
	_shake_time_left      = maxf(_shake_time_left, duration)
	_shake_strength       = maxf(_shake_strength, strength)


func _update_screen_shake(delta: float) -> void:
	if _shake_time_left <= 0.0:
		if _camera.offset != _camera_base_offset:
			_camera.offset = _camera_base_offset
		_shake_duration_total = 0.0
		return
	_shake_time_left = maxf(0.0, _shake_time_left - delta)
	var t   := _shake_time_left / maxf(0.001, _shake_duration_total)
	var amp := _shake_strength * t
	_camera.offset = _camera_base_offset + Vector2(
		randf_range(-amp, amp), randf_range(-amp, amp))
