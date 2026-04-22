extends Control
## Mana HUD: merge meter + mana pipes (filled = available mana).

const _PIP_FILLED := Color(0.33, 0.66, 1.0, 1.0)
const _PIP_EMPTY := Color(0.62, 0.62, 0.68, 0.55)
const _VISIBLE_PIP_COUNT := 5

@onready var _meter_fill: ColorRect = $Row/Meter/Fill
@onready var _meter_bg: ColorRect = $Row/Meter/Background
@onready var _pips_parent: HBoxContainer = $Row/ManaPipes


func _ready() -> void:
	_meter_bg.color = Color(0.05, 0.05, 0.08, 1.0)
	_meter_fill.color = _PIP_FILLED
	var i := 0
	for p in _pips_parent.get_children():
		if p is Panel:
			p.visible = i < _VISIBLE_PIP_COUNT
			_style_circle_panel(p as Panel, 11, _PIP_EMPTY)
			i += 1


func _style_circle_panel(p: Panel, corner_radius: int, col: Color) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	sb.set_corner_radius_all(corner_radius)
	p.add_theme_stylebox_override("panel", sb)


func sync_state(mana: int, merge_progress: int, merges_per_mana_pipe: int) -> void:
	var meter_inner_width := maxf(_meter_bg.size.x - 4.0, 0.0)
	_meter_fill.size.x = maxf(
		0.0,
		meter_inner_width * float(merge_progress) / float(max(merges_per_mana_pipe, 1))
	)
	var i := 0
	for p in _pips_parent.get_children():
		if not p is Panel:
			continue
		if not p.visible:
			continue
		var filled := i < mana
		_style_circle_panel(p as Panel, 11, _PIP_FILLED if filled else _PIP_EMPTY)
		i += 1
