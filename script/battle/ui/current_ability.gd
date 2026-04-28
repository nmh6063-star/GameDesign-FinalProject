extends CanvasLayer
class_name CurrentAbilityView

const FONT := preload("res://assets/dogica/TTF/dogicabold.ttf")

var _rank_buttons: Array[Button] = []
var _default_rank := 1
var _hovered_rank := 0


func _ready() -> void:
	_cache_rank_buttons()
	_connect_rank_buttons()
	_apply_rank_visual()
	_set_info_visible(false)


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
