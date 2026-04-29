extends CanvasLayer
class_name CurrentAbilityView

const FONT := preload("res://assets/dogica/TTF/dogicabold.ttf")
const RankAbilityCatalog := preload("res://script/entities/balls/elemental_balls/rank_ability_catalog.gd")

var _rank_buttons: Array[Button] = []
var _hovered_rank := 0

# --- dev mode ---
var _dev_mode := false
var _dev_panel: Panel = null
var _dev_target_rank := 1
var _dev_rank_btns: Array[Button] = []
var _dev_status_label: Label = null


func _ready() -> void:
	_cache_rank_buttons()
	_connect_rank_buttons()
	_apply_rank_visual()
	_set_info_visible(false)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and (event as InputEventKey).pressed and not (event as InputEventKey).echo:
		if (event as InputEventKey).keycode == KEY_P:
			_toggle_dev_mode()


func _toggle_dev_mode() -> void:
	_dev_mode = not _dev_mode
	if _dev_mode:
		_build_dev_panel()
	else:
		_destroy_dev_panel()


# ── dev panel ────────────────────────────────────────────────────────────────

func _build_dev_panel() -> void:
	_destroy_dev_panel()

	var card := $Overlay/Card as Panel

	_dev_panel = Panel.new()
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.06, 0.04, 0.12, 0.97)
	bg.border_color = Color(0.8, 0.6, 0.1)
	bg.set_border_width_all(2)
	bg.set_corner_radius_all(10)
	_dev_panel.add_theme_stylebox_override("panel", bg)
	_dev_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	card.add_child(_dev_panel)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 14.0
	vbox.offset_top = 12.0
	vbox.offset_right = -14.0
	vbox.offset_bottom = -12.0
	vbox.add_theme_constant_override("separation", 8)
	_dev_panel.add_child(vbox)

	# Header
	var hdr := Label.new()
	hdr.text = "DEV MODE  —  select a rank slot, then pick an ability  |  P to exit"
	hdr.add_theme_font_override("font", FONT)
	hdr.add_theme_font_size_override("font_size", 11)
	hdr.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(hdr)

	# Target-rank selector
	var target_lbl := Label.new()
	target_lbl.text = "Equip ability to rank:"
	target_lbl.add_theme_font_override("font", FONT)
	target_lbl.add_theme_font_size_override("font_size", 10)
	target_lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	vbox.add_child(target_lbl)

	var rank_row := HBoxContainer.new()
	rank_row.add_theme_constant_override("separation", 6)
	vbox.add_child(rank_row)

	_dev_rank_btns.clear()
	for r in range(1, 8):
		var btn := Button.new()
		btn.text = "R%d" % r
		btn.custom_minimum_size = Vector2(46, 28)
		btn.add_theme_font_override("font", FONT)
		btn.add_theme_font_size_override("font_size", 10)
		btn.pressed.connect(_on_dev_target_rank.bind(r))
		rank_row.add_child(btn)
		_dev_rank_btns.append(btn)
	_refresh_rank_highlights()

	# Status feedback label
	_dev_status_label = Label.new()
	_dev_status_label.text = " "
	_dev_status_label.add_theme_font_override("font", FONT)
	_dev_status_label.add_theme_font_size_override("font_size", 10)
	_dev_status_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.55))
	_dev_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_dev_status_label)

	# Divider label
	var divider := Label.new()
	divider.text = "── All abilities ──────────────────────────────────────────"
	divider.add_theme_font_override("font", FONT)
	divider.add_theme_font_size_override("font_size", 9)
	divider.add_theme_color_override("font_color", Color(0.45, 0.45, 0.55))
	vbox.add_child(divider)

	# Ability grid inside scroll container
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)

	var grid := GridContainer.new()
	grid.columns = 3
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	scroll.add_child(grid)

	for rank in range(1, 8):
		for row in RankAbilityCatalog.all_display_rows_for_rank(rank):
			var ability_dict: Dictionary = row
			var a_name: String = ability_dict.get("name", "")
			var a_fn: String = ability_dict.get("function", "")
			var a_desc: String = ability_dict.get("description", "")
			var a_rank: int = int(ability_dict.get("rank", rank))

			var abtn := Button.new()
			abtn.text = "[R%d] %s" % [a_rank, a_name]
			abtn.tooltip_text = "%s\n%s\nid: %s" % [a_name, a_desc, a_fn]
			abtn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			abtn.custom_minimum_size = Vector2(0, 32)
			abtn.add_theme_font_override("font", FONT)
			abtn.add_theme_font_size_override("font_size", 9)
			abtn.pressed.connect(_on_dev_ability_picked.bind(a_fn, a_name, a_desc, a_rank))
			grid.add_child(abtn)


func _destroy_dev_panel() -> void:
	if _dev_panel != null:
		_dev_panel.queue_free()
		_dev_panel = null
	_dev_rank_btns.clear()
	_dev_status_label = null


func _on_dev_target_rank(rank: int) -> void:
	_dev_target_rank = rank
	_refresh_rank_highlights()


func _refresh_rank_highlights() -> void:
	for i in range(_dev_rank_btns.size()):
		var btn := _dev_rank_btns[i]
		var selected := (i + 1) == _dev_target_rank
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.72, 0.08, 0.08) if selected else Color(0.22, 0.19, 0.32)
		style.set_corner_radius_all(5)
		btn.add_theme_stylebox_override("normal", style)
		var hover := style.duplicate() as StyleBoxFlat
		hover.bg_color = style.bg_color.lightened(0.15)
		btn.add_theme_stylebox_override("hover", hover)
		btn.add_theme_stylebox_override("pressed", style.duplicate())
		btn.add_theme_stylebox_override("focus", style.duplicate())


func _on_dev_ability_picked(fn: String, a_name: String, a_desc: String, source_rank: int) -> void:
	var ability := {
		"name": a_name,
		"type": RankAbilityCatalog.ELEMENT_TYPE,
		"function": fn,
		"description": a_desc,
		"rank": source_rank,
	}
	PlayerState.equip_rank_ability(_dev_target_rank, ability)
	if _dev_status_label != null:
		_dev_status_label.text = "✓  R%d  ←  [R%d] %s" % [_dev_target_rank, source_rank, a_name]


# ── normal view ──────────────────────────────────────────────────────────────

func _cache_rank_buttons() -> void:
	_rank_buttons.clear()
	for rank in range(1, 8):
		_rank_buttons.append(get_node("Overlay/Card/TopBar/RankOrbs/RankBall%d" % rank) as Button)


func _connect_rank_buttons() -> void:
	for rank in range(1, 8):
		var btn := _rank_buttons[rank - 1]
		btn.mouse_entered.connect(_on_rank_hovered.bind(rank))
		btn.mouse_exited.connect(_on_rank_unhovered)


func _on_rank_hovered(rank: int) -> void:
	_hovered_rank = rank
	_apply_rank_visual()
	_set_info_visible(true)
	_show_rank_details(rank)


func _on_rank_unhovered() -> void:
	_hovered_rank = 0
	_apply_rank_visual()
	_set_info_visible(false)


func _apply_rank_visual() -> void:
	for rank in range(1, 8):
		var selected := rank == _hovered_rank
		var style := _make_orb_style(
			Color(0.816, 0.816, 0.816),
			Color(0.906, 0.0, 0.0) if selected else Color(0.55, 0.55, 0.55),
			4 if selected else 0
		)
		var btn := _rank_buttons[rank - 1]
		btn.add_theme_stylebox_override("normal", style)
		btn.add_theme_stylebox_override("hover", style.duplicate())
		btn.add_theme_stylebox_override("pressed", style.duplicate())
		btn.add_theme_stylebox_override("focus", style.duplicate())


func _show_rank_details(rank: int) -> void:
	var title := _title()
	var body := _body()
	var stat := _stat()
	if title == null or body == null or stat == null:
		return
	var ability = PlayerState.elements.get(rank)
	title.text = "Rank %d" % rank
	if ability == null or not (ability is Dictionary):
		body.text = "No ability equipped."
		stat.text = ""
		return
	body.text = "%s\n%s" % [str(ability.get("name", "")), str(ability.get("description", ""))]
	stat.text = "id: %s" % str(ability.get("function", ""))


func _set_info_visible(visible: bool) -> void:
	var panel := $Overlay/Card/InfoPanel as Panel
	if panel != null:
		panel.visible = visible


func _make_orb_style(fill: Color, border: Color, bw: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fill
	s.border_color = border
	s.set_border_width_all(bw)
	s.set_corner_radius_all(999)
	return s


func _title() -> Label:
	return $Overlay/Card/InfoPanel/VBox/Title as Label


func _body() -> Label:
	return $Overlay/Card/InfoPanel/VBox/Body as Label


func _stat() -> Label:
	return $Overlay/Card/InfoPanel/VBox/Stat as Label


func _on_close_pressed() -> void:
	queue_free()
