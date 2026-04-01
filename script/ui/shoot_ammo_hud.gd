extends Control
## Shoot merge meter + bullet pips (filled = stocked shot).

const _METER_INNER_WIDTH := 118.0
const _PIP_FILLED := Color(0.9, 0.82, 0.2, 1.0)
const _PIP_EMPTY := Color(0.22, 0.22, 0.28, 1.0)

@onready var _meter_fill: ColorRect = $Row/Meter/Fill
@onready var _pips_parent: HBoxContainer = $Row/BulletPips


func _ready() -> void:
	for p in _pips_parent.get_children():
		if p is Panel:
			_style_circle_panel(p as Panel, 7, _PIP_EMPTY)
	var gm := get_node_or_null("/root/Node2D/GameManager")
	if gm == null:
		return
	if gm.has_signal("shoot_ammo_changed"):
		gm.shoot_ammo_changed.connect(_on_shoot_ammo_changed)
	if gm.has_method("emit_shoot_ammo_sync"):
		gm.emit_shoot_ammo_sync()


func _style_circle_panel(p: Panel, corner_radius: int, col: Color) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	sb.set_corner_radius_all(corner_radius)
	p.add_theme_stylebox_override("panel", sb)


func _on_shoot_ammo_changed(
	bullets: int, max_bullets: int, merge_progress: int, merges_per_bullet: int
) -> void:
	_meter_fill.size.x = maxf(
		0.0, _METER_INNER_WIDTH * float(merge_progress) / float(max(merges_per_bullet, 1))
	)
	var i := 0
	for p in _pips_parent.get_children():
		if not p is Panel:
			continue
		var filled := i < bullets
		_style_circle_panel(p as Panel, 7, _PIP_FILLED if filled else _PIP_EMPTY)
		i += 1
