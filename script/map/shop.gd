extends CanvasLayer
class_name ShopController

signal selection_completed

const RankAbilityCatalog := preload("res://script/entities/balls/elemental_balls/rank_ability_catalog.gd")
const Abilities := preload("res://script/entities/balls/elemental_balls/elemental_rank_abilities.gd")

const SHOP_SLOT_COUNT := 5

## Matches reward_selection RankBall1–7 sizes.
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

# Cost per rank
const RANK_COST := [0, 30, 40, 70, 90, 120, 150, 200]

const _HOVER_TIP_BODY_WIDTH := 420.0
const _ABILITY_HOVER_MOUSE_OFFSET := Vector2(18, 18)

var _shop_items: Array = []  # Array of {ability: dict, cost: int, rank: int}
var _slot_purchased: Array[bool] = []
var _picked_shop_index: int = -1
var _hovered_shop_slot: int = -1
var _last_rank_bar_key: String = ""
var _last_shop_cards_key: String = ""

var _gold_label: Label
var _phase_label: Label
var _top_rank_buttons: Array[Button] = []

var _reward_style_idle: StyleBoxFlat
var _reward_style_selected: StyleBoxFlat
var _reward_style_hover: StyleBoxFlat

var _ability_hover_tip: Panel
var _ability_hover_margin: MarginContainer
var _ability_hover_vbox: VBoxContainer
var _ability_hover_title: Label
var _ability_hover_body: Label
var _ability_hover_stat: Label
var _hover_tip_key: String = ""

const sound := preload("res://script/game_manager/sound_manager.gd")


func _ready() -> void:
	_build_style_templates()
	_cache_top_rank_buttons()
	_cache_hover_tip()
	_disable_rank_ball_pointer_events()
	_build_gold_label()
	_populate_slots()
	_connect_signals()
	set_process(true)
	sound.play_sound_from_string("PokeMart", 0.25, true)


func _process(_delta: float) -> void:
	_update_hover_tip()


func _build_style_templates() -> void:
	_reward_style_idle = _make_reward_card_style(false)
	_reward_style_selected = _make_reward_card_style(true)
	_reward_style_hover = _make_reward_card_hover_style()


func _make_reward_card_hover_style() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(1, 0.96, 0.88)
	s.border_color = Color(0.85, 0.2, 0.2)
	s.set_border_width_all(3)
	s.set_corner_radius_all(12)
	return s


func _cache_hover_tip() -> void:
	_ability_hover_tip = get_node_or_null("HoverTip") as Panel
	_ability_hover_margin = get_node_or_null("HoverTip/MarginContainer") as MarginContainer
	_ability_hover_vbox = get_node_or_null("HoverTip/MarginContainer/VBox") as VBoxContainer
	_ability_hover_title = get_node_or_null("HoverTip/MarginContainer/VBox/TipTitle") as Label
	_ability_hover_body = get_node_or_null("HoverTip/MarginContainer/VBox/TipBody") as Label
	_ability_hover_stat = get_node_or_null("HoverTip/MarginContainer/VBox/TipStat") as Label
	if _ability_hover_tip != null:
		_ability_hover_tip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_ability_hover_tip.visible = false
		## Draw in viewport space so Card/Overlay layout never clips or skews the tooltip.
		_ability_hover_tip.top_level = true
	for lbl in [_ability_hover_title, _ability_hover_body, _ability_hover_stat]:
		if lbl != null:
			lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _invalidate_hover_visual_keys() -> void:
	_last_rank_bar_key = ""
	_last_shop_cards_key = ""
	_hover_tip_key = ""


func _shop_slot_under_mouse() -> int:
	var mp := get_viewport().get_mouse_position()
	for i in range(SHOP_SLOT_COUNT):
		if i < _slot_purchased.size() and _slot_purchased[i]:
			continue
		var cards := _shop_cards()
		var card := cards[i] if i < cards.size() else null
		if card == null or card.disabled:
			continue
		if card.get_global_rect().has_point(mp):
			return i
		var orb := _shop_card_orb(i)
		if orb != null and orb.visible and orb.get_global_rect().has_point(mp):
			return i
	return -1


func _rank_under_mouse() -> int:
	var mp := get_viewport().get_mouse_position()
	for rank in range(1, 8):
		var b := _top_rank_button(rank)
		if b == null or not b.visible or not is_instance_valid(b):
			continue
		if b.get_global_rect().has_point(mp):
			return rank
	return -1


func _hover_rank_from_shop_hovered_slot() -> int:
	if _hovered_shop_slot < 0 or _hovered_shop_slot >= SHOP_SLOT_COUNT:
		return -1
	if _hovered_shop_slot < _slot_purchased.size() and _slot_purchased[_hovered_shop_slot]:
		return -1
	if _hovered_shop_slot >= _shop_items.size():
		return -1
	return int(_shop_items[_hovered_shop_slot].get("rank", 1))


func _rank_bar_refresh_key() -> String:
	return "%d|%d" % [_hovered_shop_slot, _picked_shop_index]


func _maybe_refresh_rank_bar() -> void:
	var k := _rank_bar_refresh_key()
	if k == _last_rank_bar_key:
		return
	_last_rank_bar_key = k
	_refresh_rank_bar_visuals()


func _shop_cards_refresh_key() -> String:
	return "%d|%d" % [_picked_shop_index, _hovered_shop_slot]


func _maybe_refresh_shop_cards() -> void:
	var k := _shop_cards_refresh_key()
	if k == _last_shop_cards_key:
		return
	_last_shop_cards_key = k
	_apply_shop_selection_visual()


func _sync_shop_hover_layout_keys() -> void:
	_last_shop_cards_key = _shop_cards_refresh_key()
	_last_rank_bar_key = _rank_bar_refresh_key()


func _fill_shop_hover_tip(slot_index: int) -> void:
	if (
			_ability_hover_title == null
			or _ability_hover_body == null
			or _ability_hover_stat == null
	):
		return
	if slot_index < 0 or slot_index >= _shop_items.size():
		return
	var item: Dictionary = _shop_items[slot_index]
	var ability: Dictionary = item.get("ability", {})
	var rank: int = int(item.get("rank", 1))
	var cost: int = int(item.get("cost", 0))
	_ability_hover_title.text = str(ability.get("name", "?"))
	var desc := str(ability.get("description", ""))
	_ability_hover_body.text = desc if not desc.is_empty() else "—"
	_ability_hover_stat.text = "Rank %d  ·  %d G  ·  id: %s" % [
		rank, cost, str(ability.get("function", ""))
	]


func _fill_rank_hover_tip(rank: int) -> void:
	if (
			_ability_hover_title == null
			or _ability_hover_body == null
			or _ability_hover_stat == null
	):
		return
	var ability = PlayerState.elements.get(rank)
	if ability == null or not (ability is Dictionary):
		_ability_hover_title.text = "Rank %d" % rank
		_ability_hover_body.text = "No ability equipped."
		_ability_hover_stat.text = ""
		return
	_ability_hover_title.text = "Rank %d — %s" % [rank, str(ability.get("name", "?"))]
	var desc := str(ability.get("description", ""))
	_ability_hover_body.text = desc if not desc.is_empty() else "—"
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
	if _ability_hover_title != null:
		_ability_hover_title.custom_minimum_size = wrap
	if _ability_hover_body != null:
		_ability_hover_body.custom_minimum_size = wrap
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


func _update_hover_tip() -> void:
	if _ability_hover_tip == null:
		return
	_hovered_shop_slot = _shop_slot_under_mouse()
	_maybe_refresh_rank_bar()
	_maybe_refresh_shop_cards()

	var slot_i := _hovered_shop_slot
	var rank := _rank_under_mouse()
	var slot_ok := (
			slot_i >= 0
			and slot_i < _shop_items.size()
			and slot_i < _slot_purchased.size()
			and not _slot_purchased[slot_i]
	)
	var next_key := ""
	if slot_ok:
		next_key = "shop:%d" % slot_i
	elif rank >= 1:
		next_key = "rank:%d" % rank
	if next_key.is_empty():
		if _ability_hover_tip.visible:
			_ability_hover_tip.visible = false
		_hover_tip_key = ""
		return

	var content_changed := next_key != _hover_tip_key
	if content_changed:
		_hover_tip_key = next_key
		if slot_ok:
			_fill_shop_hover_tip(slot_i)
		else:
			_fill_rank_hover_tip(rank)

	## Size must run while visible — invisible controls often report wrong min sizes.
	_ability_hover_tip.visible = true
	if content_changed:
		_apply_hover_tip_size()
		call_deferred("_deferred_finalize_shop_hover_tip")
	_position_hover_tip()


func _deferred_finalize_shop_hover_tip() -> void:
	if _ability_hover_tip == null or not _ability_hover_tip.visible:
		return
	_apply_hover_tip_size()
	_position_hover_tip()


func _position_hover_tip() -> void:
	if _ability_hover_tip == null or not _ability_hover_tip.visible:
		return
	var mp := get_viewport().get_mouse_position()
	_ability_hover_tip.global_position = mp + _ABILITY_HOVER_MOUSE_OFFSET
	_clamp_control_to_viewport(_ability_hover_tip)


func _make_orb_style(fill: Color, border: Color, bw: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fill
	s.border_color = border
	s.set_border_width_all(bw)
	s.set_corner_radius_all(999)
	return s


func _make_rank_decor_style(_rank: int) -> StyleBoxFlat:
	return _make_orb_style(Color(0.816, 0.816, 0.816), Color(0.55, 0.55, 0.55), 0)


func _make_reward_card_style(selected: bool) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(1, 0.96, 0.88) if selected else Color(0.98, 0.94, 0.82)
	s.border_color = Color(0.9, 0.15, 0.12) if selected else Color(0.6, 0.5, 0.35)
	s.set_border_width_all(4 if selected else 2)
	s.set_corner_radius_all(12)
	return s


func _rank_bar_ball_size(rank: int) -> Vector2:
	var i := clampi(rank, 1, 7) - 1
	return _RANK_BAR_ORB_SIZES[i]


func _rank_bar_ball_font_size(rank: int) -> int:
	var i := clampi(rank, 1, 7) - 1
	return _RANK_BAR_ORB_FONT_SIZES[i]


func _cache_top_rank_buttons() -> void:
	_top_rank_buttons.clear()
	for rank in range(1, 8):
		var button := get_node_or_null("Overlay/Card/TopBar/RankOrbs/RankBall%d" % rank) as Button
		if button != null:
			_top_rank_buttons.append(button)


func _disable_rank_ball_pointer_events() -> void:
	var orbs_row := get_node_or_null("Overlay/Card/TopBar/RankOrbs") as Control
	if orbs_row != null:
		orbs_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for rank in range(1, 8):
		var b := _top_rank_button(rank)
		if b != null:
			b.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _top_rank_button(rank: int) -> Button:
	if rank >= 1 and rank <= _top_rank_buttons.size():
		return _top_rank_buttons[rank - 1]
	return null


func _build_gold_label() -> void:
	_gold_label = Label.new()
	_gold_label.add_theme_font_override("font",
		load("res://assets/dogica/TTF/dogicabold.ttf") as Font)
	_gold_label.add_theme_font_size_override("font_size", 13)
	_gold_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.2))
	_gold_label.layout_mode = 0
	_gold_label.offset_left = 24.0
	_gold_label.offset_top = 62.0
	_gold_label.offset_right = 912.0
	_gold_label.offset_bottom = 82.0
	_gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	$Overlay/Card.add_child(_gold_label)
	_refresh_gold_label()


func _refresh_gold_label() -> void:
	if _gold_label != null:
		_gold_label.text = "Gold: %d" % PlayerState.player_gold


# ── Populate shop slots ────────────────────────────────────────────────────────

func _populate_slots() -> void:
	_shop_items.clear()
	_slot_purchased.clear()
	for _j in range(SHOP_SLOT_COUNT):
		_slot_purchased.append(false)
	_picked_shop_index = -1
	_invalidate_hover_visual_keys()

	var rng := RandomNumberGenerator.new()
	rng.randomize()

	for i in range(SHOP_SLOT_COUNT):
		var rank: int = rng.randi_range(1, 7)
		var all_options: Array = RankAbilityCatalog.reward_options_for_rank(rank)
		all_options.append(RankAbilityCatalog.default_element_for_rank(rank))
		var ability: Dictionary = all_options[rng.randi() % all_options.size()]
		var cost: int = RANK_COST[rank]
		_shop_items.append({"ability": ability, "cost": cost, "rank": rank})

	_refresh_shop_slot_labels_and_orbs()
	_hovered_shop_slot = _shop_slot_under_mouse()
	_apply_shop_selection_visual()
	_refresh_rank_bar_visuals()
	_sync_shop_hover_layout_keys()
	_refresh_phase_and_buy()


func _shop_cards() -> Array[Button]:
	var cards: Array[Button] = []
	var row := get_node_or_null("Overlay/Card/SelectionPanel/ShopRow") as Node
	if row == null:
		return cards
	for child in row.get_children():
		if child is Button:
			cards.append(child as Button)
	return cards


func _shop_card_orb(index: int) -> Button:
	var card := _shop_cards()[index] if index >= 0 and index < _shop_cards().size() else null
	if card == null:
		return null
	return card.get_node_or_null("Margin/VBox/Orb") as Button


func _shop_card_name(index: int) -> Label:
	var card := _shop_cards()[index] if index >= 0 and index < _shop_cards().size() else null
	if card == null:
		return null
	return card.get_node_or_null("Margin/VBox/Name") as Label


func _ensure_orb_overlay(parent: Control) -> TextureRect:
	var tr := parent.get_node_or_null("overlay") as TextureRect
	if tr != null:
		return tr
	tr = TextureRect.new()
	tr.name = "overlay"
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tr.pivot_offset = Vector2(18, 18)
	tr.set_anchors_preset(Control.PRESET_CENTER)
	tr.offset_left = -18.0
	tr.offset_top = -18.0
	tr.offset_right = 18.0
	tr.offset_bottom = 18.0
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	parent.add_child(tr)
	return tr


func _apply_ability_on_overlay(parent: Control, ability: Dictionary) -> void:
	var tr := _ensure_orb_overlay(parent)
	var fn := str(ability.get("function", ""))
	if fn.is_empty():
		tr.visible = false
		tr.texture = null
		return
	tr.visible = true
	var data = Abilities.get_sprite_files(fn)
	tr.texture = data["overlay"]
	var px := parent.custom_minimum_size.x
	var factor := clampf(px / 72.0, 0.55, 1.15)
	tr.scale = Vector2(factor * 2.0, factor * 2.0)


func _refresh_shop_slot_labels_and_orbs() -> void:
	for i in range(SHOP_SLOT_COUNT):
		if i >= _shop_items.size():
			break
		var item: Dictionary = _shop_items[i]
		var ability: Dictionary = item.get("ability", {})
		var cost: int = int(item.get("cost", 0))
		var rank: int = int(item.get("rank", 1))
		var lbl := _shop_card_name(i)
		if lbl != null:
			lbl.text = "%s\nRank %d\n%d G" % [ability.get("name", "?"), rank, cost]
		var orb := _shop_card_orb(i)
		if orb != null:
			orb.text = ""
			orb.custom_minimum_size = _rank_bar_ball_size(rank)
			orb.add_theme_font_size_override("font_size", _rank_bar_ball_font_size(rank))
			_apply_ability_on_overlay(orb, ability)
			orb.tooltip_text = ""
		var card := _shop_cards()[i] if i < _shop_cards().size() else null
		if card != null:
			card.tooltip_text = ""


func _apply_shop_selection_visual() -> void:
	for i in range(SHOP_SLOT_COUNT):
		var card := _shop_cards()[i] if i < _shop_cards().size() else null
		var orb := _shop_card_orb(i)
		if card == null:
			continue
		var sold := i < _slot_purchased.size() and _slot_purchased[i]
		if sold:
			card.modulate = Color(1, 1, 1, 0.45)
			card.add_theme_stylebox_override("normal", _reward_style_idle.duplicate())
			card.add_theme_stylebox_override("hover", _reward_style_idle.duplicate())
			card.add_theme_stylebox_override("pressed", _reward_style_idle.duplicate())
			if orb != null:
				var orb_idle := _make_orb_style(Color(0.816, 0.816, 0.816), Color(0.55, 0.55, 0.55), 0)
				orb.add_theme_stylebox_override("normal", orb_idle)
				orb.add_theme_stylebox_override("hover", orb_idle.duplicate())
				orb.add_theme_stylebox_override("pressed", orb_idle.duplicate())
				orb.add_theme_stylebox_override("focus", orb_idle.duplicate())
			continue
		card.modulate = Color.WHITE
		var picked := i == _picked_shop_index and _picked_shop_index >= 0
		var hovered := i == _hovered_shop_slot and _hovered_shop_slot >= 0
		if picked:
			card.add_theme_stylebox_override("normal", _reward_style_selected.duplicate())
			card.add_theme_stylebox_override("hover", _reward_style_selected.duplicate())
			card.add_theme_stylebox_override("pressed", _reward_style_selected.duplicate())
			if orb != null:
				var orb_sel := _make_orb_style(Color(0.816, 0.816, 0.816), Color(0.906, 0.0, 0.0), 4)
				orb.add_theme_stylebox_override("normal", orb_sel)
				orb.add_theme_stylebox_override("hover", orb_sel.duplicate())
				orb.add_theme_stylebox_override("pressed", orb_sel.duplicate())
				orb.add_theme_stylebox_override("focus", orb_sel.duplicate())
		elif hovered:
			var hov := _reward_style_hover.duplicate()
			card.add_theme_stylebox_override("normal", hov)
			card.add_theme_stylebox_override("hover", hov.duplicate())
			card.add_theme_stylebox_override("pressed", hov.duplicate())
			if orb != null:
				var orb_h := _make_orb_style(Color(0.816, 0.816, 0.816), Color(0.85, 0.2, 0.2), 3)
				orb.add_theme_stylebox_override("normal", orb_h)
				orb.add_theme_stylebox_override("hover", orb_h.duplicate())
				orb.add_theme_stylebox_override("pressed", orb_h.duplicate())
				orb.add_theme_stylebox_override("focus", orb_h.duplicate())
		else:
			card.add_theme_stylebox_override("normal", _reward_style_idle.duplicate())
			var h_idle := _reward_style_idle.duplicate()
			card.add_theme_stylebox_override("hover", h_idle.duplicate())
			card.add_theme_stylebox_override("pressed", _reward_style_idle.duplicate())
			if orb != null:
				var orb_idle := _make_orb_style(Color(0.816, 0.816, 0.816), Color(0.55, 0.55, 0.55), 0)
				var orb_idle_h := orb_idle.duplicate()
				orb.add_theme_stylebox_override("normal", orb_idle)
				orb.add_theme_stylebox_override("hover", orb_idle_h)
				orb.add_theme_stylebox_override("pressed", orb_idle.duplicate())
				orb.add_theme_stylebox_override("focus", orb_idle.duplicate())


func _preview_rank_for_pick() -> int:
	if _picked_shop_index < 0 or _picked_shop_index >= _shop_items.size():
		return -1
	return int(_shop_items[_picked_shop_index].get("rank", 1))


func _refresh_rank_bar_visuals() -> void:
	var preview_rank := _preview_rank_for_pick()
	var hover_rank := _hover_rank_from_shop_hovered_slot()
	for rank in range(1, 8):
		var b := _top_rank_button(rank)
		if b == null:
			continue
		var swap_highlight := preview_rank == rank and _picked_shop_index >= 0
		var hover_ring := hover_rank == rank and hover_rank >= 0
		var ability_shown: Dictionary
		if swap_highlight and _picked_shop_index < _shop_items.size():
			ability_shown = _shop_items[_picked_shop_index].get("ability", {}) as Dictionary
		else:
			var eq = PlayerState.elements.get(rank)
			ability_shown = eq if eq is Dictionary else {}
		_apply_ability_on_overlay(b, ability_shown)

		var ring_red := swap_highlight or hover_ring
		var deco := (
			_make_orb_style(Color(0.816, 0.816, 0.816), Color(0.906, 0.0, 0.0), 4)
			if ring_red
			else _make_rank_decor_style(rank)
		)
		b.add_theme_stylebox_override("normal", deco)
		b.add_theme_stylebox_override("hover", deco.duplicate())
		b.add_theme_stylebox_override("pressed", deco.duplicate())
		b.add_theme_stylebox_override("focus", deco.duplicate())


func _refresh_phase_and_buy() -> void:
	if _phase_label == null:
		_phase_label = get_node_or_null("Overlay/Card/SelectionPanel/PhaseLabel") as Label
	var buy_btn := _buy_button()

	var can_buy := false
	if _picked_shop_index >= 0 and _picked_shop_index < _shop_items.size():
		if _picked_shop_index < _slot_purchased.size() and not _slot_purchased[_picked_shop_index]:
			var cost: int = int(_shop_items[_picked_shop_index].get("cost", 0))
			can_buy = PlayerState.player_gold >= cost

	if buy_btn != null:
		buy_btn.disabled = not can_buy

	if _phase_label != null:
		if _picked_shop_index < 0:
			_phase_label.text = "Select an offer, then Buy."
		elif _picked_shop_index < _slot_purchased.size() and _slot_purchased[_picked_shop_index]:
			_phase_label.text = "That item is sold."
		elif not can_buy:
			var need := int(_shop_items[_picked_shop_index].get("cost", 0))
			_phase_label.text = "Not enough gold (need %d G)." % need
		else:
			_phase_label.text = "Buy equips this ball — rank slot updates above."


# ── Signals ────────────────────────────────────────────────────────────────────

func _connect_signals() -> void:
	for i in range(SHOP_SLOT_COUNT):
		var card := _shop_cards()[i] if i < _shop_cards().size() else null
		if card == null:
			continue
		card.pressed.connect(sound.play_sound_from_string.bind("click"))
		card.pressed.connect(_on_shop_card_pressed.bind(i))
		var orb := _shop_card_orb(i)
		if orb != null:
			orb.pressed.connect(_on_shop_card_pressed.bind(i))
			orb.pressed.connect(sound.play_sound_from_string.bind("click"))
	if _buy_button() != null:
		_buy_button().pressed.connect(_on_buy_pressed)
		_buy_button().pressed.connect(sound.play_sound_from_string.bind("cashout"))
	_continue_button().pressed.connect(sound.play_sound_from_string.bind("click"))
	_continue_button().pressed.connect(_switch_songs)
	_continue_button().pressed.connect(_on_continue_pressed)

func _switch_songs():
	for child in get_node("/root").get_children():
		if child.name.contains("player"):
			child.queue_free()
	sound.play_sound_from_string("Beneath The Mask", 0.25, true)


func _on_shop_card_pressed(index: int) -> void:
	if index < 0 or index >= SHOP_SLOT_COUNT:
		return
	if index < _slot_purchased.size() and _slot_purchased[index]:
		return
	if index >= _shop_items.size():
		return
	_picked_shop_index = index
	_apply_shop_selection_visual()
	_refresh_rank_bar_visuals()
	_sync_shop_hover_layout_keys()
	_refresh_phase_and_buy()


func _on_buy_pressed() -> void:
	if _picked_shop_index < 0 or _picked_shop_index >= _shop_items.size():
		return
	if _picked_shop_index < _slot_purchased.size() and _slot_purchased[_picked_shop_index]:
		return
	var item: Dictionary = _shop_items[_picked_shop_index]
	var cost: int = int(item.get("cost", 0))
	var ability: Dictionary = item.get("ability", {})
	var rank: int = int(item.get("rank", 1))

	if PlayerState.player_gold < cost:
		var btn := _shop_cards()[_picked_shop_index] if _picked_shop_index < _shop_cards().size() else null
		if btn != null:
			var tween := create_tween()
			tween.tween_property(btn, "modulate", Color(1, 0.3, 0.3), 0.1)
			tween.tween_property(btn, "modulate", Color.WHITE, 0.3)
		_refresh_phase_and_buy()
		return

	PlayerState.spend_gold(cost)
	PlayerState.equip_rank_ability(rank, ability)
	_slot_purchased[_picked_shop_index] = true
	var lbl := _shop_card_name(_picked_shop_index)
	if lbl != null:
		lbl.text = "Sold ✓\n\n%s" % ability.get("name", "?")
	var card := _shop_cards()[_picked_shop_index] if _picked_shop_index < _shop_cards().size() else null
	if card != null:
		card.disabled = true
	var orb := _shop_card_orb(_picked_shop_index)
	if orb != null:
		orb.disabled = true

	_picked_shop_index = -1
	_invalidate_hover_visual_keys()
	_hovered_shop_slot = _shop_slot_under_mouse()
	_refresh_gold_label()
	_apply_shop_selection_visual()
	_refresh_rank_bar_visuals()
	_sync_shop_hover_layout_keys()
	_refresh_phase_and_buy()


func _on_continue_pressed() -> void:
	selection_completed.emit()
	GameManager.complete_current_room()


func _buy_button() -> Button:
	return get_node_or_null("Overlay/Card/BottomRow/Buy") as Button


func _continue_button() -> Button:
	return $Overlay/Card/BottomRow/Continue as Button
