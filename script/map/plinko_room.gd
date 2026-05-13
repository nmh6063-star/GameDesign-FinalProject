extends Node2D

const BALL_SCENE := preload("res://scenes/plinko/plinko_ball.tscn")
const RankAbilityCatalog := preload("res://script/entities/balls/elemental_balls/rank_ability_catalog.gd")

@onready var _settings: PlinkoRoomSettings = get_node_or_null("Settings") as PlinkoRoomSettings

# ── Node references ───────────────────────────────────────────────────────────
@onready var _earnings_label := $PlinkoUI/EarningsLabel as Label
@onready var _cost_label := $PlinkoUI/CostLabel as Label
@onready var _score_label := $PlinkoUI/ScoreLabel as Label
@onready var _win_label := $PlinkoUI/WinLabel as Label
@onready var _drop_hint := $PlinkoUI/DropHint as Label
@onready var _launch_button := $PlinkoUI/LaunchButton as TextureButton
@onready var _leave_button := $PlinkoUI/LeaveButton as TextureButton
@onready var _drop_indicator := $Background/Box/BallDropLine/DropIndicator as Polygon2D
@onready var _left_marker := $Background/Box/BallDropLine/Left as Marker2D
@onready var _right_marker := $Background/Box/BallDropLine/Right as Marker2D
@onready var _ball_drop_line := $Background/Box/BallDropLine as Node2D
@onready var _camera := $Camera2D as Camera2D

# ── Runtime state ─────────────────────────────────────────────────────────────
var _drops_remaining := 0
var _plinko_points := 0
var _prize_counter_opened := false
var _prize_layer: CanvasLayer = null
var _active_ball: RigidBody2D = null
var _ball_resolved := false
var _ball_alive_time := 0.0
var _stuck_elapsed := 0.0
var _finishing := false

var _indicator_x := 0.0
var _indicator_dir := 1.0
var _ind_min_x := 0.0
var _ind_max_x := 0.0

var _hint_pulse_t := 0.0

var _shake_time_left := 0.0
var _shake_strength := 0.0
var _shake_duration_total := 0.0
var _camera_base_offset := Vector2.ZERO

# Slot name → { ability, rank, points }
var _slot_abilities: Dictionary = {}

const sound := preload("res://script/game_manager/sound_manager.gd")


func _ready() -> void:
	if _settings == null:
		push_error("PlinkoRoom: add a child node named 'Settings' with plinko_room_settings.gd")
		return

	var gm := get_node_or_null("/root/GameManager")
	if gm != null and gm.has_method("get_room_rng_seed"):
		seed(gm.get_room_rng_seed())

	_drops_remaining = _settings.max_drops
	_camera_base_offset = _camera.offset

	if is_instance_valid(_left_marker) and is_instance_valid(_right_marker):
		_ind_min_x = _left_marker.position.x + _settings.ball_radius
		_ind_max_x = _right_marker.position.x - _settings.ball_radius
	else:
		_ind_min_x = -_settings.indicator_half_range
		_ind_max_x = _settings.indicator_half_range

	_indicator_x = 0.0
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
	sound.play_sound_from_string("Jawbreaker", 0.5, true)


func _symmetric_tier_rank(visual_index: int, slot_count: int) -> int:
	if slot_count <= 0:
		return clampi(_settings.symmetric_center_rank, 1, 7)
	var lo := clampi(mini(_settings.symmetric_edge_rank, _settings.symmetric_center_rank), 1, 7)
	var hi := clampi(maxi(_settings.symmetric_edge_rank, _settings.symmetric_center_rank), 1, 7)
	var center := (slot_count - 1) * 0.5
	var dist := absf(float(visual_index) - center)
	var max_dist := maxf(center, float(slot_count - 1) - center)
	var t := dist / maxf(max_dist, 0.001)
	return clampi(int(round(lerpf(float(hi), float(lo), t))), 1, 7)


func _assign_slot_abilities(slots_root: Node) -> void:
	var areas: Array[Area2D] = []
	for child in slots_root.get_children():
		if child is Area2D:
			areas.append(child as Area2D)
	areas.sort_custom(func(a: Area2D, b: Area2D) -> bool: return a.position.x < b.position.x)

	var used_fns: Array[String] = []
	var n := areas.size()
	var min_pts := 999999
	var max_pts := 0
	var slot_pts_list: Array[int] = []
	for i in range(n):
		var tier_rank := _symmetric_tier_rank(i, n)
		slot_pts_list.append(_slot_points_for_rank(tier_rank))
	for p in slot_pts_list:
		min_pts = mini(min_pts, p)
		max_pts = maxi(max_pts, p)

	for i in range(n):
		var child := areas[i]
		var tier_rank := _symmetric_tier_rank(i, n)
		var ability := _pick_random_ability_for_rank(tier_rank, used_fns)
		var rank := int(ability.get("rank", tier_rank))
		var slot_pts := _slot_points_for_rank(rank)
		_slot_abilities[child.name] = {
			"ability": ability,
			"rank": rank,
			"points": slot_pts,
		}

		var value_label := child.get_node_or_null("ValueLabel") as Label
		if value_label != null:
			value_label.text = str(slot_pts)
			value_label.add_theme_font_size_override("font_size", 9)
			value_label.tooltip_text = ""
		var vis := child.get_node_or_null("SlotVis") as Polygon2D
		if vis != null:
			vis.color = _points_slot_color(slot_pts, min_pts, max_pts)


func _slot_points_for_rank(rank: int) -> int:
	return _settings.points_slot_base + clampi(rank, 1, 7) * _settings.points_slot_per_rank


func _points_slot_color(pts: int, min_pts: int, max_pts: int) -> Color:
	if max_pts <= min_pts:
		return _rank_color(4)
	var t := clampf(float(pts - min_pts) / float(max_pts - min_pts), 0.0, 1.0)
	return Color(
		lerpf(0.35, 0.95, t),
		lerpf(0.65, 0.35, t),
		lerpf(0.35, 0.2, t),
		1.0
	)


func _random_ability_at_rank(rank: int) -> Dictionary:
	var r := clampi(rank, 1, 7)
	var options: Array = RankAbilityCatalog.reward_options_for_rank(r)
	options.append(RankAbilityCatalog.default_element_for_rank(r))
	options.shuffle()
	return options[0] as Dictionary


func _try_spend(cost: int) -> bool:
	if _plinko_points < cost:
		return false
	_plinko_points -= cost
	return true


func _pick_random_ability_for_rank(rank: int, exclude_fns: Array[String]) -> Dictionary:
	var r := clampi(rank, 1, 7)
	var options: Array = RankAbilityCatalog.reward_options_for_rank(r)
	options.append(RankAbilityCatalog.default_element_for_rank(r))
	options.shuffle()
	for opt in options:
		var fn := String(opt.get("function", ""))
		if not exclude_fns.has(fn):
			exclude_fns.append(fn)
			return opt
	return options[0] as Dictionary


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
	if _finishing or _prize_counter_opened or _settings == null:
		return
	_indicator_x += _indicator_dir * _settings.indicator_speed * delta
	if _indicator_x >= _ind_max_x:
		_indicator_x = _ind_max_x
		_indicator_dir = -1.0
	elif _indicator_x <= _ind_min_x:
		_indicator_x = _ind_min_x
		_indicator_dir = 1.0
	_drop_indicator.position.x = _indicator_x


func _physics_process(delta: float) -> void:
	if _settings == null:
		return
	if _active_ball == null or not is_instance_valid(_active_ball) or _ball_resolved:
		return
	var spd := _active_ball.linear_velocity.length()
	if spd < _settings.ball_stuck_speed_threshold:
		_stuck_elapsed += delta
		if _stuck_elapsed >= _settings.ball_stuck_timeout_sec:
			_finalize_active_ball(null)
			return
	else:
		_stuck_elapsed = 0.0
	_ball_alive_time += delta
	if _ball_alive_time > _settings.ball_max_air_time_sec:
		_finalize_active_ball(null)


func _on_launch() -> void:
	if _settings == null:
		return
	if _finishing or _prize_counter_opened or _drops_remaining <= 0 or _ball_resolved:
		return
	if _active_ball != null and is_instance_valid(_active_ball):
		return
	var drop_global := _ball_drop_line.to_global(Vector2(_indicator_x, 0.0))
	_drop_ball(to_local(drop_global))


func _drop_ball(local_pos: Vector2) -> void:
	_ball_alive_time = 0.0
	_stuck_elapsed = 0.0
	_drops_remaining -= 1

	var ball := BALL_SCENE.instantiate() as RigidBody2D
	ball.body_entered.connect(func(_body): sound.play_sound_from_string("peg_hit"))
	ball.add_to_group("plinko_ball")
	add_child(ball)
	ball.position = local_pos
	ball.apply_central_impulse(
		Vector2(randf_range(-_settings.ball_drop_impulse, _settings.ball_drop_impulse), 0.0))
	_active_ball = ball
	_refresh_drop_ui()


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
	_active_ball = null
	_ball_alive_time = 0.0
	_stuck_elapsed = 0.0

	if slot_data != null and slot_data is Dictionary and not slot_data.is_empty():
		var pts := int(slot_data.get("points", 0))
		_plinko_points += pts
		_show_win("+%d" % pts)
		_start_screen_shake(0.14, 4.0)
	else:
		_plinko_points += _settings.miss_points
		_show_win("+%d" % _settings.miss_points)

	_refresh_drop_ui()
	_after_ball_resolved()


func _after_ball_resolved() -> void:
	if _drops_remaining > 0:
		return
	if _prize_counter_opened:
		return
	_prize_counter_opened = true
	_show_prize_counter_ui()


func _show_prize_counter_ui() -> void:
	for child in get_tree().root.get_children():
		if child.name.contains("player"):
			child.queue_free()
	var panel := Panel.new()
	panel.name = "PrizeCounterUI"
	panel.custom_minimum_size = Vector2(420, 220)

	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5

	panel.offset_left = -210
	panel.offset_top = -110
	panel.offset_right = 210
	panel.offset_bottom = 110

	# Background style
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.08, 0.08, 0.12, 0.96)
	panel_style.border_color = Color(1.0, 0.85, 0.2)
	panel_style.border_width_left = 4
	panel_style.border_width_top = 4
	panel_style.border_width_right = 4
	panel_style.border_width_bottom = 4
	panel_style.corner_radius_top_left = 18
	panel_style.corner_radius_top_right = 18
	panel_style.corner_radius_bottom_left = 18
	panel_style.corner_radius_bottom_right = 18
	panel_style.shadow_color = Color(0, 0, 0, 0.5)
	panel_style.shadow_size = 12

	panel.add_theme_stylebox_override("panel", panel_style)

	add_child(panel)

	# Title text
	var label := Label.new()
	label.text = str(_plinko_points) + " \ngold got!"
	PlayerState.player_gold += _plinko_points

	label.anchor_left = 0.0
	label.anchor_top = 0.15
	label.anchor_right = 1.0
	label.anchor_bottom = 0.5
	const font = preload("res://assets/dogica/OTF/dogicabold.otf")
	label.add_theme_font_override("font", font)

	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	label.add_theme_font_size_override("font_size", 42)
	label.add_theme_color_override("font_color", Color(1, 0.95, 0.5))

	# Text outline
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 8)

	panel.add_child(label)

	# Next button
	var next_button := Button.new()
	next_button.text = "NEXT"
	next_button.add_theme_font_override("font", font)

	next_button.custom_minimum_size = Vector2(160, 52)

	next_button.anchor_left = 0.5
	next_button.anchor_top = 0.72
	next_button.anchor_right = 0.5
	next_button.anchor_bottom = 0.72

	next_button.offset_left = -80
	next_button.offset_top = 0
	next_button.offset_right = 80
	next_button.offset_bottom = 52

	# Button style
	var button_style := StyleBoxFlat.new()
	button_style.bg_color = Color(0.18, 0.18, 0.28)
	button_style.border_width_left = 3
	button_style.border_width_top = 3
	button_style.border_width_right = 3
	button_style.border_width_bottom = 3
	button_style.corner_radius_top_left = 12
	button_style.corner_radius_top_right = 12
	button_style.corner_radius_bottom_left = 12
	button_style.corner_radius_bottom_right = 12

	next_button.add_theme_stylebox_override("normal", button_style)

	next_button.add_theme_font_size_override("font_size", 24)
	next_button.add_theme_color_override("font_color", Color.WHITE)

	panel.add_child(next_button)
	next_button.pressed.connect(_on_counter_done)
	_refresh_drop_ui()


func _shop_cost_for_rank(rank: int) -> int:
	if _settings == null:
		return 9999
	var r := clampi(rank, 1, 7)
	if r >= 7:
		return _settings.shop_roll_rank_7_cost
	if r == 6:
		return _settings.shop_roll_rank_6_cost
	return _settings.shop_roll_rank_1_to_5_cost


func _clamp_tooltip_text(s: String, max_len: int = 950) -> String:
	if s.length() <= max_len:
		return s
	return s.substr(0, maxi(0, max_len - 2)) + "…"


func _dictionary_for_rank_tooltip(rank: int) -> Dictionary:
	var r := clampi(rank, 1, 7)
	var ab: Variant = PlayerState.elements.get(r)
	if ab != null and typeof(ab) == TYPE_DICTIONARY:
		return (ab as Dictionary).duplicate(true)
	return RankAbilityCatalog.default_element_for_rank(r)


func _ability_hover_tooltip(rank: int) -> String:
	var r := clampi(rank, 1, 7)
	var d := _dictionary_for_rank_tooltip(r)
	var name_str := String(d.get("name", "?"))
	var desc_str := String(d.get("description", ""))
	var lines := "Rank %d ball — current ability\n%s" % [r, name_str]
	if desc_str.length() > 0:
		lines += "\n\n" + desc_str
	return _clamp_tooltip_text(lines)


func _lucky_draw_hover_tooltip(rank_min: int, rank_max: int) -> String:
	if _settings == null:
		return ""
	var lo := clampi(rank_min, 1, 7)
	var hi := clampi(rank_max, 1, 7)
	if lo > hi:
		var sw := lo
		lo = hi
		hi = sw
	var parts: Array[String] = []
	parts.append(
		"Spend %d score: one random new ability, rank rolled between %d and %d (same pools as fixed rank rolls)." % [
			_settings.draw_cost, lo, hi
		])
	parts.append("\n\nAbilities on your team in that range:")
	for rr in range(lo, hi + 1):
		var d := _dictionary_for_rank_tooltip(rr)
		parts.append("\n• Rank %d: %s" % [rr, String(d.get("name", "?"))])
	var acc: String = ""
	for p in parts:
		acc += p
	return _clamp_tooltip_text(acc)


func _make_rank_roll_button(rank: int) -> Button:
	var cost := _shop_cost_for_rank(rank)
	var tint := _rank_color(rank).lerp(Color(0.06, 0.05, 0.12), 0.45)
	var btn := _make_dialog_button("R%d (%d)" % [rank, cost], tint)
	btn.custom_minimum_size = Vector2(72, 34)
	btn.add_theme_font_size_override("font_size", 10)
	btn.tooltip_text = _ability_hover_tooltip(rank)
	btn.disabled = _plinko_points < cost
	btn.pressed.connect(_on_counter_shop_rank.bind(rank, cost))
	btn.pressed.connect(sound.play_sound_from_string.bind("click"))
	return btn


func _gold_for_all_score() -> int:
	if _settings == null:
		return 0
	return maxi(0, int(floor(_plinko_points * _settings.gold_per_plinko_point)))


func _on_counter_cash_out_all() -> void:
	if _settings == null:
		return
	var g := _gold_for_all_score()
	if g <= 0:
		return
	PlayerState.add_gold(g)
	_plinko_points = 0
	sound.play_sound_from_string("coin")
	sound.play_sound_from_string("payout", 0.5, false, false)
	if _prize_layer != null and is_instance_valid(_prize_layer):
		_prize_layer.queue_free()
		_prize_layer = null
	_show_prize_counter_ui()


func _on_counter_lucky_draw() -> void:
	if _settings == null:
		return
	if not _try_spend(_settings.draw_cost):
		return
	var rmin := clampi(_settings.lucky_draw_rank_min, 1, 7)
	var rmax := clampi(_settings.lucky_draw_rank_max, 1, 7)
	if rmin > rmax:
		var tmp := rmin
		rmin = rmax
		rmax = tmp
	var r := randi_range(rmin, rmax)
	var ab := _random_ability_at_rank(r)
	if _prize_layer != null and is_instance_valid(_prize_layer):
		_prize_layer.queue_free()
		_prize_layer = null
	_show_swap_dialog(ab, r, Callable(self, "_show_prize_counter_ui"))


func _on_counter_shop_rank(rank: int, cost: int) -> void:
	if not _try_spend(cost):
		return
	var ab := _random_ability_at_rank(rank)
	if _prize_layer != null and is_instance_valid(_prize_layer):
		_prize_layer.queue_free()
		_prize_layer = null
	_show_swap_dialog(ab, rank, Callable(self, "_show_prize_counter_ui"))


func _on_counter_done() -> void:
	if _prize_layer != null and is_instance_valid(_prize_layer):
		_prize_layer.queue_free()
		_prize_layer = null
	sound.play_sound_from_string("Beneath The Mask", 0.25, true)
	_complete_room()


func _show_swap_dialog(new_ability: Dictionary, rank: int, after: Callable = Callable()) -> void:
	for child in get_tree().root.get_children():
		if child.name.contains("player"):
			child.queue_free()
	sound.play_sound_from_string("coin")
	sound.play_sound_from_string("payout", 0.5, false, false)
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
	card.offset_left = -280.0
	card.offset_top = -200.0
	card.offset_right = 280.0
	card.offset_bottom = 200.0
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

	var current_ability: Dictionary = PlayerState.elements.get(rank, {})
	var current_name := String(current_ability.get("name", "(none)")) if current_ability != null else "(none)"
	var current_desc := String(current_ability.get("description", "")) if current_ability != null else ""

	var current_lbl := Label.new()
	current_lbl.text = "Current (Rank %d):\n  %s" % [rank, current_name]
	if current_desc.length() > 0:
		current_lbl.text += "\n  " + current_desc
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
		new_lbl.text += "\n  " + new_desc
	new_lbl.add_theme_font_override("font", font)
	new_lbl.add_theme_font_size_override("font_size", 9)
	new_lbl.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5))
	new_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(new_lbl)

	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 20)
	vbox.add_child(btn_row)

	var swap_btn := _make_dialog_button("Swap", Color(0.2, 0.55, 0.2))
	var skip_btn := _make_dialog_button("Skip", Color(0.35, 0.2, 0.5))
	btn_row.add_child(swap_btn)
	btn_row.add_child(skip_btn)

	swap_btn.pressed.connect(func():
		PlayerState.equip_rank_ability(rank, new_ability)
		overlay.queue_free()
		if after.is_valid():
			after.call()
	)
	swap_btn.pressed.connect(sound.play_sound_from_string.bind("click"))
	swap_btn.pressed.connect(sound.play_sound_from_string.bind("Beneath the Mask"))

	skip_btn.pressed.connect(func():
		overlay.queue_free()
		if after.is_valid():
			after.call()
	)
	skip_btn.pressed.connect(sound.play_sound_from_string.bind("click"))
	skip_btn.pressed.connect(sound.play_sound_from_string.bind("Beneath the Mask"))


func _make_dialog_button(label_text: String, color: Color) -> Button:
	var font: Font = load("res://assets/dogica/TTF/dogicapixelbold.ttf") as Font
	var btn := Button.new()
	btn.text = label_text
	btn.custom_minimum_size = Vector2(100, 36)
	btn.add_theme_font_override("font", font)
	btn.add_theme_font_size_override("font_size", 12)
	btn.add_theme_color_override("font_color", Color(0.96, 0.96, 1.0))
	btn.add_theme_color_override("font_pressed_color", Color(1, 1, 1))
	btn.add_theme_color_override("font_hover_color", Color(1, 1, 1))
	btn.add_theme_color_override("font_disabled_color", Color(0.95, 0.95, 1.0))
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_border_width_all(0)
	for i in 4:
		sb.set_corner_radius(i, 10)
	btn.add_theme_stylebox_override("normal", sb)
	var sb_h := sb.duplicate() as StyleBoxFlat
	sb_h.bg_color = color.lightened(0.12)
	btn.add_theme_stylebox_override("hover", sb_h)
	btn.add_theme_stylebox_override("pressed", sb_h)
	var sb_dis := sb.duplicate() as StyleBoxFlat
	# Readable disabled state (esp. on dark modal bg)
	sb_dis.bg_color = Color(0.46, 0.43, 0.52).lerp(color, 0.22)
	sb_dis.border_color = Color(0.88, 0.86, 0.96)
	sb_dis.set_border_width_all(2)
	btn.add_theme_stylebox_override("disabled", sb_dis)
	return btn


func _complete_room() -> void:
	if _finishing:
		return
	_finishing = true
	if _prize_layer != null and is_instance_valid(_prize_layer):
		_prize_layer.queue_free()
		_prize_layer = null
	if is_instance_valid(_leave_button):
		_leave_button.disabled = true
	if is_instance_valid(_earnings_label) and _settings != null and _settings.exit_room_message.length() > 0:
		_earnings_label.text = _settings.exit_room_message
	await get_tree().create_timer(0.55).timeout
	if is_inside_tree():
		GameManager.complete_current_room()


func _on_leave() -> void:
	if _finishing:
		return
	if not _prize_counter_opened:
		return
	_complete_room()


func _refresh_drop_ui() -> void:
	if _settings == null:
		return
	_cost_label.text = _settings.drops_label_format % [_drops_remaining, _settings.max_drops]
	_score_label.text = _settings.score_label_format % _plinko_points
	var ball_active := _active_ball != null and is_instance_valid(_active_ball)
	if is_instance_valid(_launch_button):
		_launch_button.disabled = _prize_counter_opened or _drops_remaining <= 0 \
				or _finishing or ball_active or _ball_resolved
	if is_instance_valid(_leave_button):
		_leave_button.disabled = not _prize_counter_opened or _finishing


func _show_win(text: String) -> void:
	_win_label.text = text
	_win_label.modulate = Color(1, 0.9, 0.2, 1)
	var tw := create_tween()
	tw.tween_property(_win_label, "modulate:a", 0.0, 2.4)


func _rank_color(rank: int) -> Color:
	match rank:
		1:
			return Color(0.65, 0.65, 0.65)
		2:
			return Color(0.3, 0.75, 0.3)
		3:
			return Color(0.3, 0.5, 0.9)
		4:
			return Color(0.75, 0.3, 0.85)
		5:
			return Color(0.9, 0.78, 0.15)
		6:
			return Color(0.9, 0.45, 0.15)
		7:
			return Color(0.9, 0.2, 0.2)
	return Color.WHITE


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
	_camera.offset = _camera_base_offset + Vector2(
		randf_range(-amp, amp), randf_range(-amp, amp))
