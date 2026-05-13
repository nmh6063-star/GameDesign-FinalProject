extends CanvasLayer
## Playground overlay injected into the battle scene.
## LEFT  panel  – ball rank selector (pins which rank the next setup ball will be).
## RIGHT panel  – ability selector (equips ability into PlayerState instead of firing it live).
## Enemy auto-attacks every 5 s for 20 damage; player HP never drops below 100.

const RankAbilityCatalog := preload("res://script/entities/balls/elemental_balls/rank_ability_catalog.gd")
const FONT := preload("res://assets/dogica/TTF/dogicapixelbold.ttf")

const RIGHT_W    := 230
const LEFT_W     := 90
const ENEMY_DMG  := 20
const ENEMY_TICK := 5.0
const PLAYER_HP_FLOOR := 100

var _battle_loop: Node   ## set by battle_loop before adding
var _context             ## BattleContext

# panels
var _right_panel: PanelContainer
var _left_panel:  PanelContainer
var _right_collapsed := false
var _left_collapsed  := false

# log
var _log_label: RichTextLabel
var _log: Array[String] = []
const MAX_LOG := 8

# player HP label
var _player_hp_label: Label

# selected state
var _selected_rank_btn: Button = null   ## currently highlighted ball rank button
var _selected_ability_btns := {}        ## function_id → Button for highlight tracking

# enemy attack timer
var _dmg_timer: Timer
var _timer_label: Label
var _timer_remaining := ENEMY_TICK


func _ready() -> void:
	layer = 15
	if _battle_loop != null and _battle_loop.has_method("get_context"):
		_context = _battle_loop.get_context()
	_build_left_panel()
	_build_right_panel()
	_build_enemy_timer()


func _process(delta: float) -> void:
	# Update timer countdown label
	if _timer_label != null and is_instance_valid(_timer_label):
		_timer_remaining -= delta
		_timer_remaining = maxf(0.0, _timer_remaining)
		_timer_label.text = "Enemy hits in: %.1fs" % _timer_remaining

	# Keep player HP label synced
	if _player_hp_label != null and is_instance_valid(_player_hp_label):
		_player_hp_label.text = "Player HP: %d / %d" % [
			PlayerState.player_health, PlayerState.player_max_health]


# ── Enemy auto-attack timer ────────────────────────────────────────────────────

func _build_enemy_timer() -> void:
	_dmg_timer = Timer.new()
	_dmg_timer.wait_time = ENEMY_TICK
	_dmg_timer.one_shot = false
	_dmg_timer.autostart = true
	_dmg_timer.timeout.connect(_on_enemy_tick)
	add_child(_dmg_timer)
	_timer_remaining = ENEMY_TICK


func _on_enemy_tick() -> void:
	_timer_remaining = ENEMY_TICK
	if _context == null:
		return
	# Apply damage but honour the HP floor
	var current_hp := PlayerState.player_health
	if current_hp <= PLAYER_HP_FLOOR:
		_push_log("[color=gray]Enemy attacks – HP at floor (%d), no damage.[/color]" % PLAYER_HP_FLOOR)
		return
	var actual := mini(ENEMY_DMG, current_hp - PLAYER_HP_FLOOR)
	_context.damage_player(actual)
	_push_log("[color=red]Enemy deals %d dmg → HP %d[/color]" % [actual, PlayerState.player_health])


# ── LEFT panel – ball rank selector ───────────────────────────────────────────

func _build_left_panel() -> void:
	# Tab toggle button
	var tab := Button.new()
	tab.text = "B\nA\nL\nL"
	tab.custom_minimum_size = Vector2(20, 70)
	tab.set_anchors_preset(Control.PRESET_CENTER_LEFT)
	tab.offset_left   = LEFT_W
	tab.offset_top    = -35
	tab.offset_right  = LEFT_W + 20
	tab.offset_bottom = 35
	tab.add_theme_font_override("font", FONT)
	tab.add_theme_font_size_override("font_size", 7)
	_style_flat(tab, Color(0.10, 0.18, 0.12), Color(0.4, 0.8, 0.5), 2)
	tab.pressed.connect(func():
		_left_collapsed = not _left_collapsed
		_left_panel.visible = not _left_collapsed)
	add_child(tab)

	# Panel
	_left_panel = PanelContainer.new()
	_left_panel.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	_left_panel.offset_right = LEFT_W
	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(0.06, 0.10, 0.08, 0.96)
	ps.border_color = Color(0.35, 0.75, 0.45, 1.0)
	ps.set_border_width_all(2)
	_left_panel.add_theme_stylebox_override("panel", ps)
	add_child(_left_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)
	_left_panel.add_child(vbox)

	var hdr := Label.new()
	hdr.text = "BALL\nRANK"
	hdr.add_theme_font_override("font", FONT)
	hdr.add_theme_font_size_override("font_size", 9)
	hdr.add_theme_color_override("font_color", Color(0.7, 1.0, 0.75))
	hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(hdr)

	vbox.add_child(HSeparator.new())

	for rank in range(1, 8):
		var btn := Button.new()
		btn.text = "R%d" % rank
		btn.add_theme_font_override("font", FONT)
		btn.add_theme_font_size_override("font_size", 10)
		btn.custom_minimum_size = Vector2(0, 28)
		_style_flat(btn, _rank_color(rank).darkened(0.55), _rank_color(rank).darkened(0.1), 1)
		btn.pressed.connect(_on_rank_selected.bind(rank, btn))
		vbox.add_child(btn)

	vbox.add_child(HSeparator.new())

	var random_btn := Button.new()
	random_btn.text = "⟳ Rnd"
	random_btn.add_theme_font_override("font", FONT)
	random_btn.add_theme_font_size_override("font_size", 9)
	random_btn.custom_minimum_size = Vector2(0, 26)
	_style_flat(random_btn, Color(0.22, 0.20, 0.28), Color(0.6, 0.55, 0.8), 1)
	random_btn.pressed.connect(func():
		if _battle_loop != null:
			_battle_loop.set("_playground_pinned_rank", 0)
		if _selected_rank_btn != null:
			_deselect_rank_btn(_selected_rank_btn)
			_selected_rank_btn = null
		_push_log("[color=aqua]Ball rank: random[/color]"))
	vbox.add_child(random_btn)


func _on_rank_selected(rank: int, btn: Button) -> void:
	if _battle_loop != null:
		_battle_loop.set("_playground_pinned_rank", rank)
	if _selected_rank_btn != null and _selected_rank_btn != btn:
		_deselect_rank_btn(_selected_rank_btn)
	_selected_rank_btn = btn
	# Highlight selected
	var sb := StyleBoxFlat.new()
	sb.bg_color = _rank_color(rank).darkened(0.15)
	sb.border_color = Color.WHITE
	sb.set_border_width_all(2)
	for i in 4:
		sb.set_corner_radius(i, 4)
	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_stylebox_override("hover", sb)
	_push_log("[color=lime]Ball rank pinned → R%d[/color]" % rank)


func _deselect_rank_btn(btn: Button) -> void:
	# Restore original style by re-applying the dimmed rank color
	# We need the rank from the button text
	var rank_str := btn.text.trim_prefix("R")
	var rank := rank_str.to_int()
	if rank >= 1 and rank <= 7:
		_style_flat(btn, _rank_color(rank).darkened(0.55), _rank_color(rank).darkened(0.1), 1)


# ── RIGHT panel – ability selector ────────────────────────────────────────────

func _build_right_panel() -> void:
	# Tab toggle
	var tab := Button.new()
	tab.text = "≡\nA\nB\nI\nL"
	tab.custom_minimum_size = Vector2(20, 80)
	tab.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	tab.offset_left   = -RIGHT_W - 20
	tab.offset_top    = -40
	tab.offset_right  = -RIGHT_W
	tab.offset_bottom = 40
	tab.add_theme_font_override("font", FONT)
	tab.add_theme_font_size_override("font_size", 7)
	_style_flat(tab, Color(0.18, 0.12, 0.30), Color(0.7, 0.6, 1.0), 2)
	tab.pressed.connect(func():
		_right_collapsed = not _right_collapsed
		_right_panel.visible = not _right_collapsed)
	add_child(tab)

	# Panel
	_right_panel = PanelContainer.new()
	_right_panel.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	_right_panel.offset_left  = -RIGHT_W
	_right_panel.offset_right = 0
	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(0.07, 0.05, 0.14, 0.96)
	ps.border_color = Color(0.55, 0.45, 0.9, 1.0)
	ps.set_border_width_all(2)
	_right_panel.add_theme_stylebox_override("panel", ps)
	add_child(_right_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 3)
	_right_panel.add_child(vbox)

	# Header
	var hdr := Label.new()
	hdr.text = "ABILITIES"
	hdr.add_theme_font_override("font", FONT)
	hdr.add_theme_font_size_override("font_size", 10)
	hdr.add_theme_color_override("font_color", Color(0.9, 0.8, 1.0))
	hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(hdr)

	var hint := Label.new()
	hint.text = "(click = equip on next ball)"
	hint.add_theme_font_override("font", FONT)
	hint.add_theme_font_size_override("font_size", 7)
	hint.add_theme_color_override("font_color", Color(0.6, 0.55, 0.75))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(hint)

	# Reset enemy button
	var reset_btn := _make_btn("↺ Reset Enemy", Color(0.55, 0.15, 0.15))
	reset_btn.pressed.connect(_reset_enemy)
	vbox.add_child(reset_btn)

	vbox.add_child(HSeparator.new())

	# Scrollable ability list
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)

	var ability_list := VBoxContainer.new()
	ability_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ability_list.add_theme_constant_override("separation", 2)
	scroll.add_child(ability_list)

	for rank in range(1, 8):
		var rank_lbl := Label.new()
		rank_lbl.text = "─ Rank %d" % rank
		rank_lbl.add_theme_font_override("font", FONT)
		rank_lbl.add_theme_font_size_override("font_size", 8)
		rank_lbl.add_theme_color_override("font_color", _rank_color(rank))
		ability_list.add_child(rank_lbl)

		var default_ab := RankAbilityCatalog.default_element_for_rank(rank)
		_add_ability_btn(ability_list, default_ab, true)

		for opt in RankAbilityCatalog.reward_options_for_rank(rank):
			_add_ability_btn(ability_list, opt, false)

	vbox.add_child(HSeparator.new())

	# Enemy timer display
	_timer_label = Label.new()
	_timer_label.text = "Enemy hits in: %.1fs" % ENEMY_TICK
	_timer_label.add_theme_font_override("font", FONT)
	_timer_label.add_theme_font_size_override("font_size", 8)
	_timer_label.add_theme_color_override("font_color", Color(1.0, 0.55, 0.35))
	_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_timer_label)

	# Player HP display
	_player_hp_label = Label.new()
	_player_hp_label.text = "Player HP: --"
	_player_hp_label.add_theme_font_override("font", FONT)
	_player_hp_label.add_theme_font_size_override("font_size", 8)
	_player_hp_label.add_theme_color_override("font_color", Color(0.4, 0.9, 0.55))
	_player_hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_player_hp_label)

	vbox.add_child(HSeparator.new())

	# Log
	var log_hdr := Label.new()
	log_hdr.text = "Log"
	log_hdr.add_theme_font_override("font", FONT)
	log_hdr.add_theme_font_size_override("font_size", 8)
	log_hdr.add_theme_color_override("font_color", Color(0.6, 0.55, 0.8))
	vbox.add_child(log_hdr)

	_log_label = RichTextLabel.new()
	_log_label.bbcode_enabled = true
	_log_label.custom_minimum_size = Vector2(0, 80)
	_log_label.add_theme_font_override("normal_font", FONT)
	_log_label.add_theme_font_size_override("normal_font_size", 7)
	_log_label.scroll_following = true
	vbox.add_child(_log_label)

	vbox.add_child(HSeparator.new())
	var menu_btn := _make_btn("← Menu", Color(0.2, 0.15, 0.38))
	menu_btn.pressed.connect(func():
		var gm := get_node_or_null("/root/GameManager")
		if gm != null:
			gm.is_playground_mode = false
		get_tree().change_scene_to_file("res://scenes/menu_screen.tscn"))
	vbox.add_child(menu_btn)


func _add_ability_btn(parent: VBoxContainer, ability: Dictionary, is_default: bool) -> void:
	var btn := Button.new()
	var fn_id := String(ability.get("function", ""))
	btn.text = ("• " if is_default else "  ") + String(ability.get("name", "?"))
	btn.tooltip_text = String(ability.get("description", ""))
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.add_theme_font_override("font", FONT)
	btn.add_theme_font_size_override("font_size", 7)
	btn.pressed.connect(_equip_ability.bind(ability, btn))
	var rank := int(ability.get("rank", 1))
	var col := _rank_color(rank).darkened(0.5)
	_style_flat(btn, col, _rank_color(rank).darkened(0.1), 1)
	_selected_ability_btns[fn_id] = btn
	parent.add_child(btn)


# ── Ability equipping ──────────────────────────────────────────────────────────

func _equip_ability(ability: Dictionary, btn: Button) -> void:
	var rank := int(ability.get("rank", 1))
	var name_str := String(ability.get("name", "?"))

	# De-highlight the previous selection for this rank (if any)
	var cur_equipped = PlayerState.elements.get(rank, {})
	if cur_equipped is Dictionary and not cur_equipped.is_empty():
		var old_fn := String(cur_equipped.get("function", ""))
		if _selected_ability_btns.has(old_fn):
			var old_btn := _selected_ability_btns[old_fn] as Button
			if is_instance_valid(old_btn) and old_btn != btn:
				_style_flat(old_btn, _rank_color(rank).darkened(0.5),
						_rank_color(rank).darkened(0.1), 1)

	# Equip into PlayerState so the next ball spawned inherits this ability
	PlayerState.equip_rank_ability(rank, ability)

	# Highlight selected button
	var sb := StyleBoxFlat.new()
	sb.bg_color = _rank_color(rank).darkened(0.15)
	sb.border_color = Color.WHITE
	sb.set_border_width_all(2)
	for i in 4:
		sb.set_corner_radius(i, 4)
	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_stylebox_override("hover", sb)

	_push_log("[b]Equipped[/b] %s → R%d" % [name_str, rank])


func _reset_enemy() -> void:
	if _battle_loop != null and _battle_loop.has_method("respawn_playground_enemies"):
		_battle_loop.call("respawn_playground_enemies")
	_log.clear()
	if _log_label != null:
		_log_label.clear()
	_push_log("[color=cyan]Enemy reset.[/color]")
	_timer_remaining = ENEMY_TICK
	_dmg_timer.start()


# ── Log ───────────────────────────────────────────────────────────────────────

func _push_log(text: String) -> void:
	_log.push_front(text)
	if _log.size() > MAX_LOG:
		_log.resize(MAX_LOG)
	if _log_label != null:
		_log_label.clear()
		_log_label.append_text("\n".join(_log))


# ── Style helpers ─────────────────────────────────────────────────────────────

func _make_btn(label_text: String, color: Color) -> Button:
	var btn := Button.new()
	btn.text = label_text
	btn.add_theme_font_override("font", FONT)
	btn.add_theme_font_size_override("font_size", 8)
	_style_flat(btn, color, color.lightened(0.25), 0)
	return btn


func _style_flat(ctrl: Control, bg: Color, border: Color, border_w: int) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(border_w)
	for i in 4:
		sb.set_corner_radius(i, 4)
	ctrl.add_theme_stylebox_override("normal", sb)
	var sbh := sb.duplicate() as StyleBoxFlat
	sbh.bg_color = bg.lightened(0.15)
	ctrl.add_theme_stylebox_override("hover", sbh)
	ctrl.add_theme_stylebox_override("pressed", sbh)


func _rank_color(rank: int) -> Color:
	match rank:
		1: return Color(0.72, 0.72, 0.72)
		2: return Color(0.3, 0.85, 0.3)
		3: return Color(0.35, 0.55, 1.0)
		4: return Color(0.8, 0.35, 0.9)
		5: return Color(1.0, 0.85, 0.2)
		6: return Color(1.0, 0.5, 0.15)
		7: return Color(1.0, 0.25, 0.25)
	return Color.WHITE
