extends Node2D

const BALL_SCENE := preload("res://scenes/plinko/plinko_ball.tscn")
const RankAbilityCatalog := preload("res://script/entities/balls/elemental_balls/rank_ability_catalog.gd")

# ── Tweakable parameters ──────────────────────────────────────────────────────
@export var max_drops            := 1       ## One drop per visit
@export var ball_radius          := 9.0
@export var ball_drop_impulse    := 10.0
@export var indicator_speed      := 120.0
@export var indicator_half_range := 140.0

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

# Ability slots: maps slot name → {ability: Dictionary, rank: int}
var _slot_abilities: Dictionary = {}


func _ready() -> void:
	var gm := get_node_or_null("/root/GameManager")
	if gm != null and gm.has_method("get_room_rng_seed"):
		seed(gm.get_room_rng_seed())

	_drops_remaining    = max_drops
	_camera_base_offset = _camera.offset

	if is_instance_valid(_left_marker) and is_instance_valid(_right_marker):
		_ind_min_x = _left_marker.position.x + ball_radius
		_ind_max_x = _right_marker.position.x - ball_radius
	else:
		_ind_min_x = -indicator_half_range
		_ind_max_x =  indicator_half_range

	_indicator_x   = 0.0
	_indicator_dir = 1.0
	_drop_indicator.position.x = _indicator_x

	var slots_root := get_node_or_null(
			"Background/Box/PlatformsRoot/RewardSlotsRoot") as Node
	if slots_root:
		_assign_slot_abilities(slots_root)
		for child in slots_root.get_children():
			if child is Area2D:
				child.body_entered.connect(_on_slot_body_entered.bind(child))

	_refresh_drop_ui()


# ── Assign a random rank ability to every slot ────────────────────────────────

func _assign_slot_abilities(slots_root: Node) -> void:
	var used_fns: Array[String] = []
	for child in slots_root.get_children():
		if not child is Area2D:
			continue
		var ability := _pick_random_ability(used_fns)
		var rank := int(ability.get("rank", 1))
		_slot_abilities[child.name] = {"ability": ability, "rank": rank}

		# Update the ValueLabel so the player can read the ability name
		var value_label := child.get_node_or_null("ValueLabel") as Label
		if value_label != null:
			var short_name := String(ability.get("name", "?"))
			# Abbreviate to fit small slot
			if short_name.length() > 9:
				short_name = short_name.substr(0, 8) + "…"
			value_label.text = short_name
			value_label.add_theme_font_size_override("font_size", 7)
			value_label.tooltip_text = (
				"%s (R%d)\n%s" % [ability.get("name","?"), rank, ability.get("description","")]
			)
			# Tint the polygon by rank
			var vis := child.get_node_or_null("SlotVis") as Polygon2D
			if vis != null:
				vis.color = _rank_color(rank)


func _pick_random_ability(exclude_fns: Array[String]) -> Dictionary:
	var rank := randi_range(1, 7)
	var options: Array = RankAbilityCatalog.reward_options_for_rank(rank)
	options.append(RankAbilityCatalog.default_element_for_rank(rank))
	options.shuffle()
	for opt in options:
		var fn := String(opt.get("function", ""))
		if not exclude_fns.has(fn):
			exclude_fns.append(fn)
			return opt
	return options[0]  # fallback


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
			_finalize_active_ball(null)
			return
	else:
		_stuck_elapsed = 0.0
	_ball_alive_time += delta
	if _ball_alive_time > 18.0:
		_finalize_active_ball(null)


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
	var slot_data: Dictionary = _slot_abilities.get(slot.name, {})
	_finalize_active_ball(slot_data if not slot_data.is_empty() else null)


func _finalize_active_ball(slot_data) -> void:
	_ball_resolved = false
	if _active_ball != null and is_instance_valid(_active_ball):
		_active_ball.queue_free()
	_active_ball     = null
	_ball_alive_time = 0.0
	_stuck_elapsed   = 0.0

	if slot_data != null and slot_data is Dictionary and not slot_data.is_empty():
		var ability: Dictionary = slot_data.get("ability", {})
		var name_str := String(ability.get("name", "?"))
		_show_win("Got: %s!" % name_str)
		_start_screen_shake(0.18, 5.5)
		_refresh_drop_ui()
		_show_swap_dialog(ability, int(slot_data.get("rank", 1)))
	else:
		_show_win("Miss…")
		_refresh_drop_ui()
		_check_end()


# ── Swap dialog ───────────────────────────────────────────────────────────────

func _show_swap_dialog(new_ability: Dictionary, rank: int) -> void:
	var font: Font = load("res://assets/dogica/TTF/dogicapixelbold.ttf") as Font

	var overlay := CanvasLayer.new()
	overlay.layer = 20
	add_child(overlay)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.65)
	dim.anchors_preset = Control.PRESET_FULL_RECT
	overlay.add_child(dim)

	var card := PanelContainer.new()
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.offset_left   = -260.0
	card.offset_top    = -140.0
	card.offset_right  =  260.0
	card.offset_bottom =  140.0
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color(0.10, 0.07, 0.18)
	card_style.border_color = Color(0.85, 0.8, 1.0)
	card_style.set_border_width_all(3)
	for i in 4:
		card_style.set_corner_radius(i, 14)
	card.add_theme_stylebox_override("panel", card_style)
	overlay.add_child(card)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	card.add_child(vbox)

	var title := Label.new()
	title.text = "Ability Found!"
	title.add_theme_font_override("font", font)
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	# Current ability at this rank
	var current_ability: Dictionary = PlayerState.elements.get(rank, {})
	var current_name := String(current_ability.get("name", "(none)")) if current_ability != null else "(none)"
	var current_desc := String(current_ability.get("description", "")) if current_ability != null else ""

	var current_lbl := Label.new()
	current_lbl.text = "Current (Rank %d):\n  %s" % [rank, current_name]
	if current_desc.length() > 0:
		current_lbl.text += "\n  " + current_desc.substr(0, 60) + ("…" if current_desc.length() > 60 else "")
	current_lbl.add_theme_font_override("font", font)
	current_lbl.add_theme_font_size_override("font_size", 9)
	current_lbl.add_theme_color_override("font_color", Color(0.75, 0.75, 0.85))
	current_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(current_lbl)

	var arrow := Label.new()
	arrow.text = "   ↕"
	arrow.add_theme_font_override("font", font)
	arrow.add_theme_font_size_override("font_size", 14)
	arrow.add_theme_color_override("font_color", Color(0.6, 0.6, 0.8))
	arrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(arrow)

	var new_name := String(new_ability.get("name", "?"))
	var new_desc := String(new_ability.get("description", ""))
	var new_lbl := Label.new()
	new_lbl.text = "New (Rank %d):\n  %s" % [rank, new_name]
	if new_desc.length() > 0:
		new_lbl.text += "\n  " + new_desc.substr(0, 60) + ("…" if new_desc.length() > 60 else "")
	new_lbl.add_theme_font_override("font", font)
	new_lbl.add_theme_font_size_override("font_size", 9)
	new_lbl.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5))
	new_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(new_lbl)

	# Buttons
	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 20)
	vbox.add_child(btn_row)

	var swap_btn  := _make_dialog_button("Swap", Color(0.2, 0.55, 0.2))
	var skip_btn  := _make_dialog_button("Skip", Color(0.35, 0.2, 0.5))
	btn_row.add_child(swap_btn)
	btn_row.add_child(skip_btn)

	swap_btn.pressed.connect(func():
		PlayerState.equip_rank_ability(rank, new_ability)
		overlay.queue_free()
		_check_end())

	skip_btn.pressed.connect(func():
		overlay.queue_free()
		_check_end())


func _make_dialog_button(label_text: String, color: Color) -> Button:
	var font: Font = load("res://assets/dogica/TTF/dogicapixelbold.ttf") as Font
	var btn := Button.new()
	btn.text = label_text
	btn.custom_minimum_size = Vector2(100, 36)
	btn.add_theme_font_override("font", font)
	btn.add_theme_font_size_override("font_size", 12)
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_border_width_all(0)
	for i in 4:
		sb.set_corner_radius(i, 10)
	btn.add_theme_stylebox_override("normal", sb)
	var sb_h := sb.duplicate() as StyleBoxFlat
	sb_h.bg_color = color.lightened(0.2)
	btn.add_theme_stylebox_override("hover", sb_h)
	btn.add_theme_stylebox_override("pressed", sb_h)
	return btn


func _check_end() -> void:
	if _finishing:
		return
	_finishing = true
	if is_instance_valid(_earnings_label):
		_earnings_label.text = "Plinko done!"
	await get_tree().create_timer(0.8).timeout
	if is_inside_tree():
		GameManager.complete_current_room()


func _on_leave() -> void:
	if _finishing:
		return
	GameManager.complete_current_room()


# ── UI helpers ────────────────────────────────────────────────────────────────

func _refresh_drop_ui() -> void:
	_cost_label.text = "Drops left: %d / %d" % [_drops_remaining, max_drops]
	_score_label.text = ""
	if is_instance_valid(_launch_button):
		var ball_active := _active_ball != null and is_instance_valid(_active_ball)
		_launch_button.disabled = _drops_remaining <= 0 or _finishing \
				or ball_active or _ball_resolved


func _show_win(text: String) -> void:
	_win_label.text     = text
	_win_label.modulate = Color(1, 0.9, 0.2, 1)
	var tw := create_tween()
	tw.tween_property(_win_label, "modulate:a", 0.0, 2.4)


func _rank_color(rank: int) -> Color:
	match rank:
		1: return Color(0.65, 0.65, 0.65)
		2: return Color(0.3, 0.75, 0.3)
		3: return Color(0.3, 0.5, 0.9)
		4: return Color(0.75, 0.3, 0.85)
		5: return Color(0.9, 0.78, 0.15)
		6: return Color(0.9, 0.45, 0.15)
		7: return Color(0.9, 0.2, 0.2)
	return Color.WHITE


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
