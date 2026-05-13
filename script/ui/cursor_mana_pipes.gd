extends Control
## Mana pips + merge meter follow the cursor (top-level controls).

const _PIP_FILLED := Color(0.33, 0.66, 1.0, 1.0)
const _PIP_EMPTY := Color(0.62, 0.62, 0.68, 0.55)
const _VISIBLE_PIP_COUNT := 3
const _PIP_CURSOR_OFFSET_Y := 20.0
const _PIP_SCREEN_MARGIN := 20.0
const PIP_SIZE_PX := 8
const PIP_CORNER_PX := 8
const PIP_SEPARATION := 2
const _METER_GAP_Y := 6.0

@onready var _pips_parent: HBoxContainer = $ManaPipes
@onready var _merge_meter: Control = $Meter


func _ready() -> void:
	_pips_parent.top_level = true
	_pips_parent.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pips_parent.z_index = 80
	_pips_parent.add_theme_constant_override("separation", PIP_SEPARATION)
	var pip_size := Vector2(float(PIP_SIZE_PX), float(PIP_SIZE_PX))
	var i := 0
	for p in _pips_parent.get_children():
		if p is Panel:
			p.visible = i < _VISIBLE_PIP_COUNT
			p.mouse_filter = Control.MOUSE_FILTER_IGNORE
			p.custom_minimum_size = pip_size
			_style_circle_panel(p as Panel, PIP_CORNER_PX, _PIP_EMPTY)
			i += 1

	if is_instance_valid(_merge_meter):
		_merge_meter.top_level = true
		_merge_meter.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_merge_meter.z_index = 79
		var msz := _merge_meter.custom_minimum_size
		if msz.x > 0.0 and msz.y > 0.0:
			_merge_meter.size = msz
		var bg := _merge_meter.get_node_or_null("Background") as ColorRect
		var fill := _merge_meter.get_node_or_null("Fill") as ColorRect
		if bg != null:
			bg.color = Color(0.05, 0.05, 0.08, 1.0)
		if fill != null:
			fill.color = Color(0.33, 0.66, 1.0, 1.0)


func _process(_delta: float) -> void:
	if not is_instance_valid(_pips_parent):
		return
	var sz := _pips_parent.size
	if sz.x < 1.0 or sz.y < 1.0:
		sz = _pips_parent.get_combined_minimum_size()
	var m := get_global_mouse_position()
	var pos := m + Vector2(0.0, _PIP_CURSOR_OFFSET_Y)
	var vr := get_viewport().get_visible_rect()
	var min_x := vr.position.x + _PIP_SCREEN_MARGIN
	var min_y := vr.position.y + _PIP_SCREEN_MARGIN
	var max_x := vr.position.x + vr.size.x - sz.x - _PIP_SCREEN_MARGIN
	var max_y := vr.position.y + vr.size.y - sz.y - _PIP_SCREEN_MARGIN
	pos.x = clampf(pos.x, min_x, maxf(min_x, max_x))
	pos.y = clampf(pos.y, min_y, maxf(min_y, max_y))
	_pips_parent.global_position = pos
	_layout_merge_meter(sz, vr)


func _layout_merge_meter(pip_bounds: Vector2, vr: Rect2) -> void:
	if not is_instance_valid(_merge_meter):
		return
	var msz := _merge_meter.size
	if msz.x < 1.0 or msz.y < 1.0:
		msz = _merge_meter.get_combined_minimum_size()
	var cx := _pips_parent.global_position.x + (pip_bounds.x - msz.x) * 0.5
	var cy := _pips_parent.global_position.y + pip_bounds.y + _METER_GAP_Y
	var mpos := Vector2(cx, cy)
	var min_x := vr.position.x + _PIP_SCREEN_MARGIN
	var min_y := vr.position.y + _PIP_SCREEN_MARGIN
	var max_x := vr.position.x + vr.size.x - msz.x - _PIP_SCREEN_MARGIN
	var max_y := vr.position.y + vr.size.y - msz.y - _PIP_SCREEN_MARGIN
	mpos.x = clampf(mpos.x, min_x, maxf(min_x, max_x))
	mpos.y = clampf(mpos.y, min_y, maxf(min_y, max_y))
	_merge_meter.global_position = mpos


func sync_merge_meter(merge_progress: int, merges_per_mana_pipe: int) -> void:
	if not is_instance_valid(_merge_meter):
		return
	var bg := _merge_meter.get_node_or_null("Background") as ColorRect
	var fill := _merge_meter.get_node_or_null("Fill") as ColorRect
	if bg == null or fill == null:
		return
	var meter_inner_width := maxf(bg.size.x - 4.0, 0.0)
	fill.size.x = maxf(
		0.0,
		meter_inner_width * float(merge_progress) / float(max(merges_per_mana_pipe, 1))
	)


func sync_pipes(mana: int) -> void:
	var i := 0
	for p in _pips_parent.get_children():
		if not p is Panel:
			continue
		if not p.visible:
			continue
		var filled := i < mana
		_style_circle_panel(p as Panel, PIP_CORNER_PX, _PIP_FILLED if filled else _PIP_EMPTY)
		i += 1


func _style_circle_panel(p: Panel, corner_radius: int, col: Color) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	sb.set_corner_radius_all(corner_radius)
	p.add_theme_stylebox_override("panel", sb)
