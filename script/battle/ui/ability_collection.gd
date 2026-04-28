extends CanvasLayer

const RankAbilityCatalog := preload("res://script/entities/balls/elemental_balls/rank_ability_catalog.gd")
const FONT := preload("res://assets/dogica/TTF/dogicabold.ttf")


func _ready() -> void:
	var tabs := $Overlay/Card/TabContainer as TabContainer
	for c in tabs.get_children():
		c.queue_free()
	for rank in range(1, 8):
		tabs.add_child(_build_rank_page(rank))
	for i in range(tabs.get_tab_count()):
		tabs.set_tab_title(i, "Rank %d" % (i + 1))
	tabs.current_tab = 0
	$Overlay/Card/Close.pressed.connect(queue_free)


func _build_rank_page(rank: int) -> Control:
	var scroll := ScrollContainer.new()
	scroll.name = "RankPage%d" % rank
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	scroll.add_child(margin)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(grid)
	for row in RankAbilityCatalog.all_display_rows_for_rank(rank):
		grid.add_child(_ability_card(row))
	return scroll


func _ability_card(row: Dictionary) -> Control:
	var outer := PanelContainer.new()
	outer.custom_minimum_size = Vector2(260, 148)
	outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.16, 0.12, 0.24, 1)
	style.border_color = Color(0.55, 0.48, 0.72, 1)
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	outer.add_theme_stylebox_override("panel", style)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	outer.add_child(vb)
	var badge := Label.new()
	badge.text = "Base ability" if row.get("is_base", false) else "Reward pool"
	badge.add_theme_font_override("font", FONT)
	badge.add_theme_font_size_override("font_size", 10)
	badge.add_theme_color_override("font_color", Color(0.75, 0.82, 1.0))
	vb.add_child(badge)
	var title := Label.new()
	title.text = str(row.get("name", ""))
	title.add_theme_font_override("font", FONT)
	title.add_theme_font_size_override("font_size", 15)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(title)
	var body := Label.new()
	body.text = str(row.get("description", ""))
	body.add_theme_font_override("font", FONT)
	body.add_theme_font_size_override("font_size", 11)
	body.add_theme_color_override("font_color", Color(0.88, 0.88, 0.94))
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(body)
	var fn := Label.new()
	fn.text = "id: %s" % str(row.get("function", ""))
	fn.add_theme_font_override("font", FONT)
	fn.add_theme_font_size_override("font_size", 9)
	fn.add_theme_color_override("font_color", Color(0.55, 0.52, 0.62))
	vb.add_child(fn)
	return outer
