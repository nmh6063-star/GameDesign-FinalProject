extends CanvasLayer
## Ability-testing panel injected into the battle scene when playground mode is active.
## Sits on the right edge of the screen as a collapsible drawer.

const RankAbilityCatalog := preload("res://script/entities/balls/elemental_balls/rank_ability_catalog.gd")
const RankAbilityEffects  := preload("res://script/entities/balls/elemental_balls/rank_ability_effects.gd")
const FONT := preload("res://assets/dogica/TTF/dogicapixelbold.ttf")

const PANEL_W   := 240
const MAX_LOG   := 10

var _battle_loop: Node   ## BattleLoop instance – set by battle_loop before adding
var _context            ## BattleContext – obtained via battle_loop.get_context()

var _panel: PanelContainer
var _log_label: RichTextLabel
var _collapsed := false
var _log: Array[String] = []


func _ready() -> void:
	layer = 15
	if _battle_loop != null and _battle_loop.has_method("get_context"):
		_context = _battle_loop.get_context()
	_build_ui()


# ── UI construction ───────────────────────────────────────────────────────────

func _build_ui() -> void:
	# Toggle tab on the right edge
	var tab := Button.new()
	tab.text = "≡\nA\nB\nI\nL"
	tab.custom_minimum_size = Vector2(22, 80)
	tab.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	tab.offset_left   = -22
	tab.offset_top    = -40
	tab.offset_right  = 0
	tab.offset_bottom = 40
	tab.add_theme_font_override("font", FONT)
	tab.add_theme_font_size_override("font_size", 8)
	_style_flat(tab, Color(0.18, 0.12, 0.30), Color(0.7, 0.6, 1.0), 2)
	tab.pressed.connect(_toggle_panel)
	add_child(tab)

	# Main panel anchored right
	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	_panel.offset_left = -PANEL_W - 24
	_panel.offset_right = -24
	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(0.07, 0.05, 0.14, 0.96)
	ps.border_color = Color(0.55, 0.45, 0.9, 1.0)
	ps.set_border_width_all(2)
	for i in 4:
		ps.set_corner_radius(i, 0)
	_panel.add_theme_stylebox_override("panel", ps)
	add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	_panel.add_child(vbox)

	# Header
	var hdr := Label.new()
	hdr.text = "PLAYGROUND"
	hdr.add_theme_font_override("font", FONT)
	hdr.add_theme_font_size_override("font_size", 11)
	hdr.add_theme_color_override("font_color", Color(0.9, 0.8, 1.0))
	hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(hdr)

	# Reset button
	var reset_btn := _make_btn("↺ Reset Enemy", Color(0.55, 0.15, 0.15))
	reset_btn.pressed.connect(_reset_enemy)
	vbox.add_child(reset_btn)

	# Separator
	vbox.add_child(HSeparator.new())

	# Scrollable ability list
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)

	var ability_list := VBoxContainer.new()
	ability_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ability_list.add_theme_constant_override("separation", 3)
	scroll.add_child(ability_list)

	for rank in range(1, 8):
		var rank_lbl := Label.new()
		rank_lbl.text = "─ Rank %d" % rank
		rank_lbl.add_theme_font_override("font", FONT)
		rank_lbl.add_theme_font_size_override("font_size", 9)
		rank_lbl.add_theme_color_override("font_color", _rank_color(rank))
		ability_list.add_child(rank_lbl)

		var default_ab := RankAbilityCatalog.default_element_for_rank(rank)
		_add_ability_btn(ability_list, default_ab, true)

		for opt in RankAbilityCatalog.reward_options_for_rank(rank):
			_add_ability_btn(ability_list, opt, false)

	# Separator + log
	vbox.add_child(HSeparator.new())

	var log_hdr := Label.new()
	log_hdr.text = "Log"
	log_hdr.add_theme_font_override("font", FONT)
	log_hdr.add_theme_font_size_override("font_size", 9)
	log_hdr.add_theme_color_override("font_color", Color(0.6, 0.55, 0.8))
	vbox.add_child(log_hdr)

	_log_label = RichTextLabel.new()
	_log_label.bbcode_enabled = true
	_log_label.custom_minimum_size = Vector2(0, 90)
	_log_label.add_theme_font_override("normal_font", FONT)
	_log_label.add_theme_font_size_override("normal_font_size", 8)
	_log_label.scroll_following = true
	vbox.add_child(_log_label)

	# Back-to-menu button
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
	var label := String(ability.get("name", "?"))
	btn.text = ("• " if is_default else "  ") + label
	btn.tooltip_text = String(ability.get("description", ""))
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.add_theme_font_override("font", FONT)
	btn.add_theme_font_size_override("font_size", 8)
	btn.pressed.connect(_fire_ability.bind(ability))

	var rank := int(ability.get("rank", 1))
	var col := _rank_color(rank).darkened(0.5)
	_style_flat(btn, col, _rank_color(rank).darkened(0.1), 1)
	parent.add_child(btn)


# ── Ability firing ────────────────────────────────────────────────────────────

func _fire_ability(ability: Dictionary) -> void:
	if _context == null:
		# Try to grab it again in case it wasn't ready at _ready time
		if _battle_loop != null and _battle_loop.has_method("get_context"):
			_context = _battle_loop.get_context()
		if _context == null:
			_push_log("[color=red]No battle context[/color]")
			return

	var fn_str := String(ability.get("function", ""))
	var sep := fn_str.rfind("_")
	if sep < 0:
		_push_log("[color=red]Bad id: %s[/color]" % fn_str)
		return
	var kind := fn_str.substr(0, sep)
	var rank := fn_str.substr(sep + 1).to_int()

	_push_log("[b]%s[/b] (R%d)" % [ability.get("name","?"), rank])
	RankAbilityEffects.execute(_context, null, kind, rank)


func _reset_enemy() -> void:
	if _battle_loop != null and _battle_loop.has_method("respawn_playground_enemies"):
		_battle_loop.call("respawn_playground_enemies")
	_push_log("[color=cyan]Enemy reset.[/color]")
	_log.clear()
	if _log_label != null:
		_log_label.clear()


# ── Panel toggle ──────────────────────────────────────────────────────────────

func _toggle_panel() -> void:
	_collapsed = not _collapsed
	_panel.visible = not _collapsed


# ── Log ───────────────────────────────────────────────────────────────────────

func _push_log(text: String) -> void:
	_log.push_front(text)
	if _log.size() > MAX_LOG:
		_log.resize(MAX_LOG)
	if _log_label != null:
		_log_label.clear()
		_log_label.append_text("\n".join(_log))


# ── Helpers ───────────────────────────────────────────────────────────────────

func _make_btn(label_text: String, color: Color) -> Button:
	var btn := Button.new()
	btn.text = label_text
	btn.add_theme_font_override("font", FONT)
	btn.add_theme_font_size_override("font_size", 9)
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
