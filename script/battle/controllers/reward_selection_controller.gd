extends CanvasLayer
class_name RewardSelectionController

const RankAbilityCatalog := preload("res://script/entities/balls/elemental_balls/rank_ability_catalog.gd")
const COLLECTION_SCENE := preload("res://scenes/ability_collection.tscn")
const FONT := preload("res://assets/dogica/TTF/dogicabold.ttf")

signal selection_completed

const REWARD_SLOT_COUNT := 3

var _chosen_rank: int = 0
var _picked_index: int = -1
var _hovered_reward_index: int = -1
var _ability_entries: Array = []
var _top_rank_buttons: Array[Button] = []
var _rank_locked := false

## Cached tooltip label references (set in _ready).
var _tip_body: Label
var _tip_stat: Label

## Cached label / node references (set in _ready).
var _rank_pick_label_node: Label
var _phase_label_node: Label
var _reward_name_nodes: Array[Label] = []

## Duplicated styles so each orb can own its StyleBoxFlat instance.
var _orb_style_idle: StyleBoxFlat
var _orb_style_selected: StyleBoxFlat
var _reward_style_idle: StyleBoxFlat
var _reward_style_selected: StyleBoxFlat


func _ready() -> void:
	_build_style_templates()
	_cache_top_rank_buttons()
	_cache_tip_labels()
	_set_tooltip_passthrough()
	_connect_rank_picker_buttons()
	_connect_top_rank_hover()
	_collection_button().pressed.connect(_on_collection_pressed)
	_next_button().pressed.connect(_on_next_pressed)
	for i in range(REWARD_SLOT_COUNT):
		var card := _reward_card(i)
		var orb := _reward_orb(i)
		if orb != null:
			orb.mouse_entered.connect(_on_reward_hover.bind(i))
			orb.mouse_exited.connect(_on_hover_exit)
			orb.pressed.connect(_on_reward_card_pressed.bind(i))
		card.disabled = true
	set_process(false)
	_begin_rank_pick_phase()
	_apply_top_rank_selection_visual()
	_refresh_next_state()


func _process(_delta: float) -> void:
	if not _hover_tip().visible:
		return
	var tip := _hover_tip()
	var mp := get_viewport().get_mouse_position() + Vector2(14, 14)
	tip.global_position = mp
	var vr := get_viewport().get_visible_rect()
	tip.global_position.x = clampf(tip.global_position.x, vr.position.x + 4, vr.end.x - tip.size.x - 4)
	tip.global_position.y = clampf(tip.global_position.y, vr.position.y + 4, vr.end.y - tip.size.y - 4)


func _build_style_templates() -> void:
	_orb_style_idle = _make_orb_style(Color(0.816, 0.816, 0.816), Color(0.55, 0.55, 0.55), 0)
	_orb_style_selected = _make_orb_style(Color(0.816, 0.816, 0.816), Color(0.906, 0.0, 0.0), 4)
	_reward_style_idle = _make_reward_card_style(false)
	_reward_style_selected = _make_reward_card_style(true)


func _make_orb_style(fill: Color, border: Color, bw: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fill
	s.border_color = border
	s.set_border_width_all(bw)
	s.set_corner_radius_all(999)
	return s


func _make_reward_card_style(selected: bool) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(1, 0.96, 0.88) if selected else Color(0.98, 0.94, 0.82)
	s.border_color = Color(0.9, 0.15, 0.12) if selected else Color(0.6, 0.5, 0.35)
	s.set_border_width_all(4 if selected else 2)
	s.set_corner_radius_all(12)
	return s


func _make_rank_decor_style(_rank: int) -> StyleBoxFlat:
	return _make_orb_style(Color(0.816, 0.816, 0.816), Color(0.55, 0.55, 0.55), 0)


func _cache_top_rank_buttons() -> void:
	_top_rank_buttons.clear()
	for rank in range(1, 8):
		var button := get_node("Overlay/Card/TopBar/RankOrbs/RankBall%d" % rank) as Button
		_top_rank_buttons.append(button)


func _connect_top_rank_hover() -> void:
	for rank in range(1, 8):
		var btn := _top_rank_button(rank)
		btn.mouse_entered.connect(_on_top_rank_hover.bind(rank))
		btn.mouse_exited.connect(_on_hover_exit)


func _connect_rank_picker_buttons() -> void:
	for rank in range(1, 8):
		var btn := _rank_pick_button(rank)
		btn.pressed.connect(_on_rank_picked.bind(rank))


func _begin_rank_pick_phase() -> void:
	_rank_locked = false
	_chosen_rank = 0
	_picked_index = -1
	_ability_entries.clear()
	_rewards_row().visible = false
	_rank_pick_row().visible = true
	if _rank_pick_label_node != null:
		_rank_pick_label_node.text = "Pick a rank (1-7). This choice is final for this reward."
	if _phase_label_node != null:
		_phase_label_node.text = "Pick rank first. Hover top balls to inspect current abilities."
	for rank in range(1, 8):
		_rank_pick_button(rank).disabled = false
	_apply_top_rank_selection_visual()
	_clear_reward_row()
	_refresh_next_state()


func _on_rank_picked(rank: int) -> void:
	if _rank_locked:
		return
	_rank_locked = true
	_chosen_rank = rank
	_picked_index = 0
	_apply_top_rank_selection_visual()
	for r in range(1, 8):
		_rank_pick_button(r).disabled = true
	_rank_pick_row().visible = false
	_rewards_row().visible = true
	if _rank_pick_label_node != null:
		_rank_pick_label_node.text = "Chosen rank: %d" % rank
	if _phase_label_node != null:
		_phase_label_node.text = "Pick a reward from rank %d pool." % rank
	var pool := RankAbilityCatalog.reward_options_for_rank(rank)
	pool.shuffle()
	_ability_entries = pool.slice(0, min(REWARD_SLOT_COUNT, pool.size()))
	_picked_index = -1
	_refresh_reward_cards()
	_refresh_next_state()


func _cache_tip_labels() -> void:
	var vbox := $Overlay/HoverTip/VBox
	if vbox != null:
		_tip_body  = vbox.get_node_or_null("TipBody")  as Label
		_tip_stat  = vbox.get_node_or_null("TipStat")  as Label
	_rank_pick_label_node = get_node_or_null("Overlay/Card/SelectionPanel/RankPickLabel") as Label
	_phase_label_node     = get_node_or_null("Overlay/Card/PhaseLabel") as Label
	_reward_name_nodes.resize(REWARD_SLOT_COUNT)
	for i in range(REWARD_SLOT_COUNT):
		_reward_name_nodes[i] = get_node_or_null(
			"Overlay/Card/SelectionPanel/RewardsRow/RewardCard%d/Margin/VBox/Name" % i) as Label


func _show_tip(title: String, body: String, stat: String) -> void:
	if _tip_body == null or _tip_stat == null:
		return
	_tip_body.text  = body
	_tip_stat.text  = stat
	var tip := _hover_tip()
	tip.visible = true
	tip.reset_size()
	set_process(true)


func _on_top_rank_hover(rank: int) -> void:
	var el = PlayerState.elements.get(rank)
	var body_text := "No ability equipped for this rank."
	var stat_text := ""
	if el != null and el is Dictionary:
		body_text = "%s\n%s" % [str(el.get("name", "")), str(el.get("description", ""))]
		stat_text = "id: %s" % str(el.get("function", ""))
	_show_tip("Rank %d — current ability" % rank, body_text, stat_text)


func _on_reward_hover(index: int) -> void:
	if index < 0 or index >= _ability_entries.size():
		return
	_hovered_reward_index = index
	_apply_reward_selection_visual()
	var e: Dictionary = _ability_entries[index]
	var stat_text := "Pick a rank first." if _chosen_rank < 1 else "On shot · rank slot %d" % _chosen_rank
	_show_tip(str(e.get("name", "")), str(e.get("description", "")), stat_text)


func _on_reward_card_pressed(index: int) -> void:
	if index < 0 or index >= _ability_entries.size():
		return
	_picked_index = index
	_apply_reward_selection_visual()
	_refresh_next_state()


func _on_hover_exit() -> void:
	_hovered_reward_index = -1
	_apply_reward_selection_visual()
	_hover_tip().visible = false
	set_process(false)


func _on_next_pressed() -> void:
	if _chosen_rank < 1 or _picked_index < 0 or _picked_index >= _ability_entries.size():
		return
	var picked: Dictionary = _ability_entries[_picked_index]
	PlayerState.equip_rank_ability(_chosen_rank, picked)
	selection_completed.emit()
	queue_free()


func _on_collection_pressed() -> void:
	get_tree().current_scene.add_child(COLLECTION_SCENE.instantiate())


func _apply_top_rank_selection_visual() -> void:
	for rank in range(1, 8):
		var b := _top_rank_button(rank)
		if rank == _chosen_rank:
			var sel := _orb_style_selected.duplicate()
			b.add_theme_stylebox_override("normal", sel)
			b.add_theme_stylebox_override("hover", sel.duplicate())
			b.add_theme_stylebox_override("pressed", sel.duplicate())
			b.add_theme_stylebox_override("focus", sel.duplicate())
		else:
			var deco := _make_rank_decor_style(rank)
			b.add_theme_stylebox_override("normal", deco)
			b.add_theme_stylebox_override("hover", deco.duplicate())
			b.add_theme_stylebox_override("pressed", deco.duplicate())
			b.add_theme_stylebox_override("focus", deco.duplicate())


func _apply_reward_selection_visual() -> void:
	for i in range(REWARD_SLOT_COUNT):
		var card := _reward_card(i)
		var orb := _reward_orb(i)
		if i == _picked_index and _picked_index >= 0:
			card.add_theme_stylebox_override("normal", _reward_style_selected.duplicate())
			card.add_theme_stylebox_override("hover", _reward_style_selected.duplicate())
			card.add_theme_stylebox_override("pressed", _reward_style_selected.duplicate())
			if orb != null:
				var orb_sel := _make_orb_style(Color(0.816, 0.816, 0.816), Color(0.906, 0.0, 0.0), 4)
				orb.add_theme_stylebox_override("normal", orb_sel)
				orb.add_theme_stylebox_override("hover", orb_sel.duplicate())
				orb.add_theme_stylebox_override("pressed", orb_sel.duplicate())
				orb.add_theme_stylebox_override("focus", orb_sel.duplicate())
		else:
			card.add_theme_stylebox_override("normal", _reward_style_idle.duplicate())
			card.add_theme_stylebox_override("hover", _reward_style_idle.duplicate())
			card.add_theme_stylebox_override("pressed", _reward_style_idle.duplicate())
			if orb != null:
				var hovering := i == _hovered_reward_index
				var orb_idle := _make_orb_style(
					Color(0.816, 0.816, 0.816),
					Color(0.95, 0.35, 0.25) if hovering else Color(0.55, 0.55, 0.55),
					2 if hovering else 0
				)
				orb.add_theme_stylebox_override("normal", orb_idle)
				orb.add_theme_stylebox_override("hover", orb_idle.duplicate())
				orb.add_theme_stylebox_override("pressed", orb_idle.duplicate())
				orb.add_theme_stylebox_override("focus", orb_idle.duplicate())


func _clear_reward_row() -> void:
	_ability_entries.clear()
	for i in range(REWARD_SLOT_COUNT):
		var card := _reward_card(i)
		var orb := _reward_orb(i)
		card.disabled = true
		if orb != null:
			orb.disabled = true
		var lbl := _reward_name(i)
		if lbl != null:
			lbl.text = "—"
		card.modulate = Color(1, 1, 1, 0.45)


func _refresh_reward_cards() -> void:
	for i in range(REWARD_SLOT_COUNT):
		var card := _reward_card(i)
		var orb := _reward_orb(i)
		var lbl := _reward_name(i)
		if i < _ability_entries.size():
			var e: Dictionary = _ability_entries[i]
			if lbl != null:
				lbl.text = str(e.get("name", ""))
			card.disabled = false
			if orb != null:
				orb.disabled = false
			card.modulate = Color.WHITE
		else:
			if lbl != null:
				lbl.text = "—"
			card.disabled = true
			if orb != null:
				orb.disabled = true
			card.modulate = Color(1, 1, 1, 0.45)
	_apply_reward_selection_visual()


func _refresh_next_state() -> void:
	_next_button().disabled = _chosen_rank < 1 or _picked_index < 0


func _set_tooltip_passthrough() -> void:
	_make_controls_mouse_ignore(_hover_tip())


func _make_controls_mouse_ignore(node: Node) -> void:
	if node is Control:
		(node as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		_make_controls_mouse_ignore(child)


func _top_rank_button(rank: int) -> Button:
	return _top_rank_buttons[rank - 1]


func _rank_pick_row() -> HBoxContainer:
	return $Overlay/Card/SelectionPanel/RankPickRow as HBoxContainer


func _rank_pick_label() -> Label:
	return _rank_pick_label_node


func _rank_pick_button(rank: int) -> Button:
	return get_node("Overlay/Card/SelectionPanel/RankPickRow/PickRank%d" % rank) as Button


func _rewards_row() -> HBoxContainer:
	return $Overlay/Card/SelectionPanel/RewardsRow as HBoxContainer


func _reward_card(i: int) -> Button:
	return get_node("Overlay/Card/SelectionPanel/RewardsRow/RewardCard%d" % i) as Button


func _reward_name(i: int) -> Label:
	if i >= 0 and i < _reward_name_nodes.size():
		return _reward_name_nodes[i]
	return null


func _reward_orb(i: int) -> Button:
	return get_node_or_null("Overlay/Card/SelectionPanel/RewardsRow/RewardCard%d/Margin/VBox/Orb" % i) as Button


func _hover_tip() -> Panel:
	return $Overlay/HoverTip as Panel


func _phase_label() -> Label:
	return _phase_label_node


func _next_button() -> Button:
	return $Overlay/Card/Next as Button


func _collection_button() -> Button:
	return $Overlay/Card/CollectionButton as Button
