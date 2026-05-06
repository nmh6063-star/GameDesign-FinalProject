extends Node2D

const RankAbilityCatalog := preload("res://script/entities/balls/elemental_balls/rank_ability_catalog.gd")
const RankAbilityEffects := preload("res://script/entities/balls/elemental_balls/rank_ability_effects.gd")
const BattleContext := preload("res://script/battle/core/battle_context.gd")
const DummyEnemyScene := preload("res://scenes/dummy_enemy.tscn")
const PGController := preload("res://script/map/playground_controller.gd")

const DUMMY_HP := 99999
const MAX_LOG := 14
const FONT_PATH := "res://assets/dogica/TTF/dogicapixelbold.ttf"

# ── UI refs (built in _ready) ──────────────────────────────────────────────────
var _hp_bar: ProgressBar
var _hp_label: Label
var _log_label: RichTextLabel
var _ability_list: VBoxContainer
var _gold_label: Label

# ── State ─────────────────────────────────────────────────────────────────────
var _dummy: DummyEnemy
var _controller: PlaygroundController
var _context: BattleContext
var _log: Array[String] = []

const FONT := preload("res://assets/dogica/TTF/dogicapixelbold.ttf")


func _ready() -> void:
	_build_ui()
	_setup_dummy()
	_setup_context()
	_build_ability_buttons()
	_sync_hp()
	_sync_gold()


# ── Setup ─────────────────────────────────────────────────────────────────────

func _setup_dummy() -> void:
	_dummy = DummyEnemyScene.instantiate() as DummyEnemy
	_dummy.name = "DummyEnemy"
	add_child(_dummy)


func _setup_context() -> void:
	_controller = PGController.new()
	_controller.name = "PGController"
	_controller.dummy_enemy = _dummy
	_controller.on_hp_changed = _sync_hp
	_controller.log_message.connect(_push_log)
	add_child(_controller)
	_context = BattleContext.new(_controller)


# ── UI Build ──────────────────────────────────────────────────────────────────

func _build_ui() -> void:
	# Background
	var bg := ColorRect.new()
	bg.color = Color(0.06, 0.04, 0.10)
	bg.anchors_preset = Control.PRESET_FULL_RECT
	add_child(bg)

	var ui := CanvasLayer.new()
	ui.name = "UI"
	add_child(ui)

	# ── Top bar ────────────────────────────────────────────────────────────
	var top := PanelContainer.new()
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.offset_bottom = 64
	var top_style := StyleBoxFlat.new()
	top_style.bg_color = Color(0.10, 0.07, 0.18)
	top_style.set_border_width_all(0)
	top.add_theme_stylebox_override("panel", top_style)
	ui.add_child(top)

	var top_hbox := HBoxContainer.new()
	top_hbox.add_theme_constant_override("separation", 20)
	top.add_child(top_hbox)

	var title := Label.new()
	title.text = "  PLAYGROUND"
	title.add_theme_font_override("font", FONT)
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.9, 0.85, 1.0))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_hbox.add_child(title)

	# Enemy HP
	var enemy_panel := VBoxContainer.new()
	enemy_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_hbox.add_child(enemy_panel)

	_hp_label = Label.new()
	_hp_label.add_theme_font_override("font", FONT)
	_hp_label.add_theme_font_size_override("font_size", 10)
	_hp_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
	_hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	enemy_panel.add_child(_hp_label)

	_hp_bar = ProgressBar.new()
	_hp_bar.max_value = DUMMY_HP
	_hp_bar.custom_minimum_size = Vector2(260, 14)
	_hp_bar.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
	enemy_panel.add_child(_hp_bar)

	# Gold
	_gold_label = Label.new()
	_gold_label.add_theme_font_override("font", FONT)
	_gold_label.add_theme_font_size_override("font_size", 12)
	_gold_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.2))
	_gold_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	top_hbox.add_child(_gold_label)

	# Reset button
	var reset_btn := _make_button("Reset Enemy", Color(0.6, 0.2, 0.2))
	reset_btn.pressed.connect(_reset_dummy)
	top_hbox.add_child(reset_btn)

	# Back button
	var back_btn := _make_button("← Menu", Color(0.2, 0.2, 0.4))
	back_btn.pressed.connect(func():
		get_tree().change_scene_to_file("res://scenes/menu_screen.tscn"))
	top_hbox.add_child(back_btn)
	var spacer_r := Control.new()
	spacer_r.custom_minimum_size = Vector2(8, 0)
	top_hbox.add_child(spacer_r)

	# ── Body (ability list + log) ──────────────────────────────────────────
	var body := HSplitContainer.new()
	body.set_anchors_preset(Control.PRESET_FULL_RECT)
	body.offset_top = 68
	body.offset_bottom = -8
	body.offset_left = 8
	body.offset_right = -8
	body.split_offset = 500
	ui.add_child(body)

	# Left: scrollable ability list
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(scroll)

	_ability_list = VBoxContainer.new()
	_ability_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_ability_list.add_theme_constant_override("separation", 4)
	scroll.add_child(_ability_list)

	# Right: log
	var right_panel := PanelContainer.new()
	right_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var rp_style := StyleBoxFlat.new()
	rp_style.bg_color = Color(0.08, 0.06, 0.12)
	rp_style.border_color = Color(0.3, 0.2, 0.5)
	rp_style.set_border_width_all(2)
	rp_style.corner_radius_top_left = 8
	rp_style.corner_radius_top_right = 8
	rp_style.corner_radius_bottom_left = 8
	rp_style.corner_radius_bottom_right = 8
	right_panel.add_theme_stylebox_override("panel", rp_style)
	body.add_child(right_panel)

	var right_vbox := VBoxContainer.new()
	right_vbox.add_theme_constant_override("separation", 6)
	right_panel.add_child(right_vbox)

	var log_title := Label.new()
	log_title.text = "Effect Log"
	log_title.add_theme_font_override("font", FONT)
	log_title.add_theme_font_size_override("font_size", 12)
	log_title.add_theme_color_override("font_color", Color(0.7, 0.6, 0.9))
	right_vbox.add_child(log_title)

	_log_label = RichTextLabel.new()
	_log_label.bbcode_enabled = true
	_log_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_log_label.add_theme_font_override("normal_font", FONT)
	_log_label.add_theme_font_size_override("normal_font_size", 10)
	_log_label.scroll_following = true
	right_vbox.add_child(_log_label)

	var clear_btn := _make_button("Clear Log", Color(0.2, 0.15, 0.3))
	clear_btn.pressed.connect(func():
		_log.clear()
		_log_label.clear())
	right_vbox.add_child(clear_btn)


func _build_ability_buttons() -> void:
	for rank in range(1, 8):
		# Rank header
		var header := Label.new()
		header.text = "── RANK %d ──" % rank
		header.add_theme_font_override("font", FONT)
		header.add_theme_font_size_override("font_size", 11)
		header.add_theme_color_override("font_color", _rank_color(rank))
		header.add_theme_constant_override("outline_size", 1)
		_ability_list.add_child(header)

		# Default ability
		var default_ability := RankAbilityCatalog.default_element_for_rank(rank)
		_add_ability_button(default_ability, true)

		# Options
		for opt in RankAbilityCatalog.reward_options_for_rank(rank):
			_add_ability_button(opt, false)


func _add_ability_button(ability: Dictionary, is_default: bool) -> void:
	var btn := Button.new()
	var name_str = ability.get("name", "?")
	var desc_str = ability.get("description", "")
	var prefix := "[D] " if is_default else "  "
	btn.text = prefix + name_str
	btn.tooltip_text = desc_str
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.add_theme_font_override("font", FONT)
	btn.add_theme_font_size_override("font_size", 10)
	btn.pressed.connect(_fire_ability.bind(ability))

	var rank := int(ability.get("rank", 1))
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.15, 0.10, 0.22, 0.92) if not is_default else Color(0.10, 0.15, 0.28, 0.95)
	sb.border_color = _rank_color(rank).darkened(0.3)
	sb.set_border_width_all(1)
	sb.corner_radius_top_left = 5
	sb.corner_radius_top_right = 5
	sb.corner_radius_bottom_left = 5
	sb.corner_radius_bottom_right = 5
	btn.add_theme_stylebox_override("normal", sb)
	var sb_hover := sb.duplicate() as StyleBoxFlat
	sb_hover.bg_color = sb.bg_color.lightened(0.15)
	btn.add_theme_stylebox_override("hover", sb_hover)
	btn.add_theme_stylebox_override("pressed", sb_hover)

	_ability_list.add_child(btn)


# ── Firing abilities ──────────────────────────────────────────────────────────

func _fire_ability(ability: Dictionary) -> void:
	if not _dummy.is_alive():
		_dummy.current_health = DUMMY_HP
		_context.reset_for_battle()

	var fn_str := String(ability.get("function", ""))
	var sep_idx := fn_str.rfind("_")
	if sep_idx < 0:
		_push_log("[color=red]Bad function id: %s[/color]" % fn_str)
		return
	var kind := fn_str.substr(0, sep_idx)
	var rank := fn_str.substr(sep_idx + 1).to_int()

	_push_log("[b]→ %s[/b] (rank %d)" % [ability.get("name", "?"), rank])
	RankAbilityEffects.execute(_context, null, kind, rank)
	_sync_hp()
	_sync_gold()


# ── UI helpers ────────────────────────────────────────────────────────────────

func _sync_hp() -> void:
	if _hp_bar == null or _dummy == null:
		return
	var hp := _dummy.current_health
	_hp_bar.max_value = DUMMY_HP
	_hp_bar.value = hp
	if _hp_label != null:
		_hp_label.text = "Dummy HP: %d / %d" % [hp, DUMMY_HP]


func _sync_gold() -> void:
	if _gold_label == null:
		return
	_gold_label.text = "Gold: %d  " % PlayerState.player_gold


func _reset_dummy() -> void:
	_dummy.current_health = DUMMY_HP
	_context.reset_for_battle()
	_log.clear()
	if _log_label != null:
		_log_label.clear()
	_sync_hp()
	_push_log("[color=cyan]Enemy reset.[/color]")


func _push_log(text: String) -> void:
	_log.push_front(text)
	if _log.size() > MAX_LOG:
		_log.resize(MAX_LOG)
	if _log_label != null:
		_log_label.clear()
		_log_label.append_text("\n".join(_log))


func _make_button(label_text: String, color: Color) -> Button:
	var btn := Button.new()
	btn.text = label_text
	btn.add_theme_font_override("font", FONT)
	btn.add_theme_font_size_override("font_size", 11)
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.corner_radius_top_left = 8
	sb.corner_radius_top_right = 8
	sb.corner_radius_bottom_left = 8
	sb.corner_radius_bottom_right = 8
	sb.set_border_width_all(0)
	btn.add_theme_stylebox_override("normal", sb)
	var sb_h := sb.duplicate() as StyleBoxFlat
	sb_h.bg_color = color.lightened(0.2)
	btn.add_theme_stylebox_override("hover", sb_h)
	btn.add_theme_stylebox_override("pressed", sb_h)
	return btn


func _rank_color(rank: int) -> Color:
	match rank:
		1: return Color(0.75, 0.75, 0.75)
		2: return Color(0.4, 0.85, 0.4)
		3: return Color(0.4, 0.6, 1.0)
		4: return Color(0.85, 0.4, 0.9)
		5: return Color(1.0, 0.85, 0.2)
		6: return Color(1.0, 0.55, 0.2)
		7: return Color(1.0, 0.3, 0.3)
	return Color.WHITE
