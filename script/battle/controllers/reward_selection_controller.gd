extends CanvasLayer
class_name RewardSelectionController

const RankAbilityCatalog := preload("res://script/entities/balls/elemental_balls/rank_ability_catalog.gd")
const COLLECTION_SCENE := preload("res://scenes/ability_collection.tscn")
const Abilities := preload("res://script/entities/balls/elemental_balls/elemental_rank_abilities.gd")

signal selection_completed

const REWARD_SLOT_COUNT := 3

## Matches top-bar RankBall1–7 in reward_selection.tscn (size + label scale).
const _RANK_BAR_ORB_SIZES: Array[Vector2] = [
	Vector2(50, 50),
	Vector2(65, 65),
	Vector2(82, 82),
	Vector2(98, 98),
	Vector2(114, 114),
	Vector2(130, 130),
	Vector2(148, 148),
]
const _RANK_BAR_ORB_FONT_SIZES: Array[int] = [11, 12, 13, 14, 15, 16, 17]
const DEFAULT_REWARD_ORB_SIZE := Vector2(72, 72)
## Matches Current Ability overlay InfoPanel body width for wrapped text.
const _HOVER_TIP_BODY_WIDTH := 420.0
const _ABILITY_HOVER_MOUSE_OFFSET := Vector2(18, 18)

## Reward tier: 0 = ranks 1–3, 1 = ranks 4–6, 2 = rank 7. -1 = none chosen yet.
var _selected_reward_range: int = -1
var _range_choice_locked := false
var _hovered_range_panel: int = -1
var _picked_index: int = -1
var _ability_entries: Array = []
var _top_rank_buttons: Array[Button] = []
var _range_panels: Array[Panel] = []

## Cached label / node references (set in _ready).
var _rank_pick_label_node: Label
var _phase_label_node: Label
var _reward_name_nodes: Array[Label] = []

## Duplicated styles so each orb can own its StyleBoxFlat instance.
var _reward_style_idle: StyleBoxFlat
var _reward_style_selected: StyleBoxFlat
var _range_frame_idle: StyleBoxFlat
var _range_frame_hover: StyleBoxFlat
var _range_frame_selected: StyleBoxFlat
var _range_frame_not_chosen_dim: StyleBoxFlat

var _ability_hover_tip: Panel
var _ability_hover_margin: MarginContainer
var _ability_hover_vbox: VBoxContainer
var _ability_hover_title: Label
var _ability_hover_body: Label
var _ability_hover_stat: Label
## Tracks hover content so we only reflow the tip when the target changes ("rank:3", "reward:1", …).
var _hover_tip_key: String = ""

const sound := preload("res://script/game_manager/sound_manager.gd")


func _ready() -> void:
	_build_style_templates()
	_cache_top_rank_buttons()
	_cache_range_panels()
	_cache_tip_labels()
	_connect_range_panels()
	_disable_rank_ball_pointer_events()
	_cache_ability_hover_tip()
	set_process(true)
	_collection_button().pressed.connect(_on_collection_pressed)
	_next_button().pressed.connect(_on_next_pressed)
	_next_button().pressed.connect(sound.play_sound_from_string.bind("click"))
	for i in range(REWARD_SLOT_COUNT):
		var card := _reward_card(i)
		card.pressed.connect(_on_reward_card_pressed.bind(i))
		card.pressed.connect(sound.play_sound_from_string.bind("click"))
		var orb := _reward_orb(i)
		if orb != null:
			orb.pressed.connect(_on_reward_card_pressed.bind(i))
			orb.pressed.connect(sound.play_sound_from_string.bind("click"))
		card.disabled = true
	_begin_rank_pick_phase()
	sound.play_sound_from_string("Beneath the Mask", 0.25, true)


func _process(_delta: float) -> void:
	_update_hover_tip()


func _cache_ability_hover_tip() -> void:
	_ability_hover_tip = get_node("HoverTip") as Panel
	_ability_hover_margin = get_node("HoverTip/MarginContainer") as MarginContainer
	_ability_hover_vbox = get_node("HoverTip/MarginContainer/VBox") as VBoxContainer
	_ability_hover_title = get_node("HoverTip/MarginContainer/VBox/TipTitle") as Label
	_ability_hover_body = get_node("HoverTip/MarginContainer/VBox/TipBody") as Label
	_ability_hover_stat = get_node("HoverTip/MarginContainer/VBox/TipStat") as Label
	if _ability_hover_tip != null:
		_ability_hover_tip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_ability_hover_tip.visible = false
		_ability_hover_tip.top_level = true
	for lbl in [_ability_hover_title, _ability_hover_body, _ability_hover_stat]:
		if lbl != null:
			lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _rank_under_mouse() -> int:
	var mp := get_viewport().get_mouse_position()
	for rank in range(1, 8):
		var b := _top_rank_button(rank)
		if b == null or not b.visible or not is_instance_valid(b):
			continue
		if b.get_global_rect().has_point(mp):
			return rank
	return -1


func _reward_card_under_mouse() -> int:
	if _rewards_row() == null or not _rewards_row().visible:
		return -1
	var mp := get_viewport().get_mouse_position()
	for i in range(REWARD_SLOT_COUNT):
		if i >= _ability_entries.size():
			continue
		var card := _reward_card(i)
		if card == null or not card.visible or not is_instance_valid(card):
			continue
		if card.disabled:
			continue
		if card.get_global_rect().has_point(mp):
			return i
	return -1


func _fill_reward_pick_hover_tip(entry_index: int) -> void:
	if _ability_hover_title == null or _ability_hover_body == null or _ability_hover_stat == null:
		return
	if entry_index < 0 or entry_index >= _ability_entries.size():
		return
	var ability: Dictionary = _ability_entries[entry_index]
	var slot_rank := clampi(int(ability.get("rank", 1)), 1, 7)
	_ability_hover_title.text = str(ability.get("name", "?"))
	var desc_r := str(ability.get("description", ""))
	_ability_hover_body.text = desc_r if not desc_r.is_empty() else "—"
	_ability_hover_stat.text = "Rank %d  ·  id: %s" % [slot_rank, str(ability.get("function", ""))]


func _fill_ability_hover_tip(rank: int) -> void:
	if _ability_hover_title == null or _ability_hover_body == null or _ability_hover_stat == null:
		return
	var ability = PlayerState.elements.get(rank)
	if ability == null or not (ability is Dictionary):
		_ability_hover_title.text = "Rank %d" % rank
		_ability_hover_body.text = "No ability equipped."
		_ability_hover_stat.text = ""
		return
	_ability_hover_title.text = "Rank %d — %s" % [rank, str(ability.get("name", "?"))]
	var desc_a := str(ability.get("description", ""))
	_ability_hover_body.text = desc_a if not desc_a.is_empty() else "—"
	_ability_hover_stat.text = "id: %s" % str(ability.get("function", ""))


func _apply_hover_tip_size() -> void:
	if (
			_ability_hover_tip == null
			or _ability_hover_margin == null
			or _ability_hover_vbox == null
			or _ability_hover_body == null
	):
		return
	const ML := 18.0
	const MT := 16.0
	const MR := 18.0
	const MB := 16.0
	var tw := _HOVER_TIP_BODY_WIDTH
	var wrap := Vector2(tw, 0)
	_ability_hover_body.custom_minimum_size = wrap
	if _ability_hover_title != null:
		_ability_hover_title.custom_minimum_size = wrap
	if _ability_hover_stat != null:
		_ability_hover_stat.custom_minimum_size = wrap

	var sep := float(_ability_hover_vbox.get_theme_constant("separation", "VBoxContainer"))
	var sum_y := 0.0
	var parts := 0
	for lbl in [_ability_hover_title, _ability_hover_body, _ability_hover_stat]:
		if lbl == null:
			continue
		if lbl == _ability_hover_stat and lbl.text.is_empty():
			continue
		sum_y += lbl.get_minimum_size().y
		parts += 1
	if parts > 1:
		sum_y += sep * float(parts - 1)

	var outer := Vector2(tw + ML + MR, sum_y + MT + MB)
	outer.x = maxf(outer.x, tw + ML + MR)
	outer.y = maxf(outer.y, 56.0)
	_ability_hover_tip.custom_minimum_size = outer
	_ability_hover_tip.size = outer


func _update_hover_tip() -> void:
	if _ability_hover_tip == null:
		return
	var reward_i := _reward_card_under_mouse()
	var rank := _rank_under_mouse()
	var next_key := ""
	if reward_i >= 0:
		next_key = "reward:%d" % reward_i
	elif rank >= 0:
		next_key = "rank:%d" % rank
	if next_key.is_empty():
		if _ability_hover_tip.visible:
			_ability_hover_tip.visible = false
		_hover_tip_key = ""
		return

	var content_changed := next_key != _hover_tip_key
	if content_changed:
		_hover_tip_key = next_key
		if reward_i >= 0:
			_fill_reward_pick_hover_tip(reward_i)
		else:
			_fill_ability_hover_tip(rank)

	_ability_hover_tip.visible = true
	if content_changed:
		_apply_hover_tip_size()
		call_deferred("_deferred_finalize_reward_hover_tip")
	_reward_hover_tip_position()


func _deferred_finalize_reward_hover_tip() -> void:
	if _ability_hover_tip == null or not _ability_hover_tip.visible:
		return
	_apply_hover_tip_size()
	_reward_hover_tip_position()


func _reward_hover_tip_position() -> void:
	if _ability_hover_tip == null or not _ability_hover_tip.visible:
		return
	var mp := get_viewport().get_mouse_position()
	_ability_hover_tip.global_position = mp + _ABILITY_HOVER_MOUSE_OFFSET
	_clamp_control_to_viewport(_ability_hover_tip)


func _clamp_control_to_viewport(ctrl: Control) -> void:
	var vr := get_viewport().get_visible_rect()
	var gr := ctrl.get_global_rect()
	var p := ctrl.global_position
	if gr.position.x < vr.position.x:
		p.x = vr.position.x
	if gr.position.y < vr.position.y:
		p.y = vr.position.y
	if gr.end.x > vr.end.x:
		p.x = vr.end.x - gr.size.x
	if gr.end.y > vr.end.y:
		p.y = vr.end.y - gr.size.y
	ctrl.global_position = p


func _build_style_templates() -> void:
	_reward_style_idle = _make_reward_card_style(false)
	_reward_style_selected = _make_reward_card_style(true)
	_range_frame_idle = _make_range_frame_style(2, Color(0.55, 0.52, 0.58), 0.04)
	_range_frame_hover = _make_range_frame_fill(
		2,
		Color(0.75, 0.28, 0.32, 0.55),
		Color(0.92, 0.22, 0.28, 0.2)
	)
	_range_frame_selected = _make_range_frame_fill(
		2,
		Color(0.82, 0.22, 0.26, 0.65),
		Color(0.94, 0.15, 0.2, 0.35)
	)
	_range_frame_not_chosen_dim = _make_range_frame_style(1, Color(0.4, 0.38, 0.42), 0.02)


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


func _rank_bar_ball_size(rank: int) -> Vector2:
	var i := clampi(rank, 1, 7) - 1
	return _RANK_BAR_ORB_SIZES[i]


func _rank_bar_ball_font_size(rank: int) -> int:
	var i := clampi(rank, 1, 7) - 1
	return _RANK_BAR_ORB_FONT_SIZES[i]


func _make_range_frame_style(border_w: int, border_col: Color, fill_alpha: float) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(1, 1, 1, fill_alpha)
	s.border_color = border_col
	s.set_border_width_all(border_w)
	s.set_corner_radius_all(14)
	return s


func _make_range_frame_fill(border_w: int, border_col: Color, fill: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fill
	s.border_color = border_col
	s.set_border_width_all(border_w)
	s.set_corner_radius_all(14)
	return s


func _cache_top_rank_buttons() -> void:
	_top_rank_buttons.clear()
	for rank in range(1, 8):
		var button := get_node("Overlay/Card/TopBar/RankOrbs/RankBall%d" % rank) as Button
		_top_rank_buttons.append(button)


func _cache_range_panels() -> void:
	_range_panels.clear()
	for i in range(3):
		var p := get_node_or_null("Overlay/Card/TopBar/RangeTier%d" % i) as Panel
		if p != null:
			_range_panels.append(p)


func _connect_range_panels() -> void:
	var tb := _top_bar()
	if not tb.resized.is_connected(_update_range_panel_layout):
		tb.resized.connect(_update_range_panel_layout)
	var orbs := _rank_orbs_container()
	if orbs != null and not orbs.resized.is_connected(_update_range_panel_layout):
		orbs.resized.connect(_update_range_panel_layout)
	for i in range(_range_panels.size()):
		var p := _range_panels[i]
		p.mouse_entered.connect(_on_range_panel_hover_enter.bind(i))
		p.mouse_exited.connect(_on_range_panel_hover_exit)
		p.gui_input.connect(_on_range_panel_gui_input.bind(i))


func _disable_rank_ball_pointer_events() -> void:
	var orbs_row := _rank_orbs_container()
	if orbs_row != null:
		orbs_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for rank in range(1, 8):
		_top_rank_button(rank).mouse_filter = Control.MOUSE_FILTER_IGNORE


func _rank_orbs_container() -> Control:
	return get_node_or_null("Overlay/Card/TopBar/RankOrbs") as Control


func _top_bar() -> Control:
	return $Overlay/Card/TopBar as Control


func _range_panel(index: int) -> Panel:
	if index >= 0 and index < _range_panels.size():
		return _range_panels[index]
	return null


func _set_range_panels_interactive(interactive: bool) -> void:
	var filt := Control.MOUSE_FILTER_STOP if interactive else Control.MOUSE_FILTER_IGNORE
	for i in range(_range_panels.size()):
		var p := _range_panel(i)
		if p != null:
			p.mouse_filter = filt


func _union_global_rect(controls: Array) -> Rect2:
	var r := Rect2()
	var first := true
	for c in controls:
		if c is Control:
			var cr := (c as Control).get_global_rect()
			r = cr if first else r.merge(cr)
			first = false
	return r


func _controls_in_reward_range(range_id: int) -> Array:
	match range_id:
		0:
			return [_top_rank_button(1), _top_rank_button(2), _top_rank_button(3)]
		1:
			return [_top_rank_button(4), _top_rank_button(5), _top_rank_button(6)]
		_:
			return [_top_rank_button(7)]


func _update_range_panel_layout() -> void:
	var tb := _top_bar()
	if tb == null:
		return
	const PAD := 10.0
	var inv := tb.get_global_transform().affine_inverse()
	for i in range(mini(3, _range_panels.size())):
		var gr := _union_global_rect(_controls_in_reward_range(i))
		if gr.size.x <= 0.0 or gr.size.y <= 0.0:
			continue
		gr = gr.grow_individual(PAD, PAD, PAD, PAD)
		var top_left: Vector2 = inv * gr.position
		var bot_right: Vector2 = inv * (gr.position + gr.size)
		var p := _range_panel(i)
		if p == null:
			continue
		p.position = top_left
		p.size = bot_right - top_left


func _refresh_range_panel_styles() -> void:
	for i in range(_range_panels.size()):
		var p := _range_panels[i]
		var selected := i == _selected_reward_range
		var hovered := i == _hovered_range_panel and not _range_choice_locked
		var st: StyleBoxFlat
		if _range_choice_locked:
			st = _range_frame_selected.duplicate() if selected else _range_frame_not_chosen_dim.duplicate()
		elif hovered:
			st = _range_frame_hover.duplicate()
		else:
			st = _range_frame_idle.duplicate()
		p.add_theme_stylebox_override("panel", st)


func _on_range_panel_hover_enter(range_id: int) -> void:
	if _range_choice_locked:
		return
	_hovered_range_panel = range_id
	_refresh_range_panel_styles()


func _on_range_panel_hover_exit() -> void:
	_hovered_range_panel = -1
	_refresh_range_panel_styles()


func _on_range_panel_gui_input(event: InputEvent, range_id: int) -> void:
	if _range_choice_locked:
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			_on_range_pressed(range_id)


func _begin_rank_pick_phase() -> void:
	_selected_reward_range = -1
	_range_choice_locked = false
	_hovered_range_panel = -1
	_set_range_panels_interactive(true)
	_picked_index = -1
	_ability_entries.clear()
	_rewards_row().visible = false
	if _rank_pick_row() != null:
		_rank_pick_row().visible = false
	if _rank_pick_label_node != null:
		_rank_pick_label_node.text = (
			"Choose a tier frame above (ranks 1–3, 4–6, or 7). Your choice is final."
		)
	if _phase_label_node != null:
		_phase_label_node.text = "Then pick one of three random abilities from that tier."
	call_deferred("_refresh_range_panel_styles_after_layout")
	_clear_reward_row()
	_apply_rank_ball_visuals()
	_refresh_next_state()


func _refresh_range_panel_styles_after_layout() -> void:
	_update_range_panel_layout()
	_refresh_range_panel_styles()


func _on_range_pressed(range_id: int) -> void:
	if _range_choice_locked:
		return
	if range_id < 0 or range_id > 2:
		return
	var pool: Array = RankAbilityCatalog.reward_pool_for_reward_range(range_id).duplicate()
	if pool.is_empty():
		return
	_selected_reward_range = range_id
	_range_choice_locked = true
	_hovered_range_panel = -1
	_set_range_panels_interactive(false)
	pool.shuffle()
	var pick_count := mini(REWARD_SLOT_COUNT, pool.size())
	_ability_entries.clear()
	for j in range(pick_count):
		var entry: Dictionary = pool[j]
		_ability_entries.append(entry)
	_picked_index = 0 if pick_count > 0 else -1
	_rewards_row().visible = true
	const TIER_LABELS: Array[String] = ["ranks 1–3", "ranks 4–6", "rank 7"]
	var tier_label := TIER_LABELS[range_id] if range_id >= 0 and range_id < TIER_LABELS.size() else "rank 7"
	if _rank_pick_label_node != null:
		_rank_pick_label_node.text = "Tier locked: %s — pick one reward below." % tier_label
	if _phase_label_node != null:
		_phase_label_node.text = "Click a card, then Next to equip."
	_refresh_range_panel_styles()
	_refresh_reward_cards()
	_refresh_next_state()


func _cache_tip_labels() -> void:
	_rank_pick_label_node = get_node_or_null("Overlay/Card/SelectionPanel/RankPickLabel") as Label
	_phase_label_node     = get_node_or_null("Overlay/Card/PhaseLabel") as Label
	_reward_name_nodes.resize(REWARD_SLOT_COUNT)
	for i in range(REWARD_SLOT_COUNT):
		_reward_name_nodes[i] = get_node_or_null(
			"Overlay/Card/SelectionPanel/RewardsRow/RewardCard%d/Margin/VBox/Name" % i) as Label


func _on_reward_card_pressed(index: int) -> void:
	if index < 0 or index >= _ability_entries.size():
		return
	_picked_index = index
	_apply_reward_selection_visual()
	_apply_rank_ball_visuals()
	_refresh_next_state()


func _picked_ability_rank_slot() -> int:
	if _picked_index < 0 or _picked_index >= _ability_entries.size():
		return -1
	return clampi(int(_ability_entries[_picked_index].get("rank", 1)), 1, 7)


func _on_next_pressed() -> void:
	if _selected_reward_range < 0 or _picked_index < 0 or _picked_index >= _ability_entries.size():
		return
	var picked: Dictionary = _ability_entries[_picked_index]
	var slot_rank := int(picked.get("rank", 1))
	PlayerState.equip_rank_ability(slot_rank, picked)
	selection_completed.emit()
	queue_free()


func _on_collection_pressed() -> void:
	get_tree().current_scene.add_child(COLLECTION_SCENE.instantiate())


func _apply_rank_ball_visuals() -> void:
	var chosen_slot := _picked_ability_rank_slot()
	for rank in range(1, 8):
		var b := _top_rank_button(rank)
		var chosen := rank == chosen_slot
		var deco := (
			_make_orb_style(Color(0.816, 0.816, 0.816), Color(0.906, 0.0, 0.0), 4)
			if chosen
			else _make_rank_decor_style(rank)
		)
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
				var orb_idle := _make_orb_style(Color(0.816, 0.816, 0.816), Color(0.55, 0.55, 0.55), 0)
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
			orb.custom_minimum_size = DEFAULT_REWARD_ORB_SIZE
			orb.remove_theme_font_size_override("font_size")
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
			var ab_rank := clampi(int(e.get("rank", 1)), 1, 7)
			if lbl != null:
				lbl.text = str(e.get("name", ""))
				var data = Abilities.get_sprite_files(e.get("function", ""))
				orb.get_node("overlay").texture = data["overlay"]
			card.disabled = false
			if orb != null:
				orb.disabled = false
				orb.custom_minimum_size = _rank_bar_ball_size(ab_rank)
				orb.add_theme_font_size_override("font_size", _rank_bar_ball_font_size(ab_rank))
			card.modulate = Color.WHITE
		else:
			if lbl != null:
				lbl.text = "—"
			card.disabled = true
			if orb != null:
				orb.disabled = true
				orb.custom_minimum_size = DEFAULT_REWARD_ORB_SIZE
				orb.remove_theme_font_size_override("font_size")
			card.modulate = Color(1, 1, 1, 0.45)
	_apply_reward_selection_visual()
	_apply_rank_ball_visuals()


func _refresh_next_state() -> void:
	_next_button().disabled = _selected_reward_range < 0 or _picked_index < 0


func _top_rank_button(rank: int) -> Button:
	return _top_rank_buttons[rank - 1]


func _rank_pick_row() -> HBoxContainer:
	return $Overlay/Card/SelectionPanel/RankPickRow as HBoxContainer


func _rank_pick_label() -> Label:
	return _rank_pick_label_node


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


func _phase_label() -> Label:
	return _phase_label_node


func _next_button() -> Button:
	return $Overlay/Card/Next as Button


func _collection_button() -> Button:
	return $Overlay/Card/CollectionButton as Button
