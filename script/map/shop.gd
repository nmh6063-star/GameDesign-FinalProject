extends CanvasLayer
class_name ShopController

signal selection_completed

const RankAbilityCatalog := preload("res://script/entities/balls/elemental_balls/rank_ability_catalog.gd")

# Cost per rank
const RANK_COST := [0, 30, 40, 70, 90, 120, 150, 200]

var _shop_items: Array = []  # Array of {ability: dict, cost: int}
var _gold_label: Label


func _ready() -> void:
	_build_gold_label()
	_populate_slots()
	_connect_signals()


func _build_gold_label() -> void:
	_gold_label = Label.new()
	_gold_label.add_theme_font_override("font",
		load("res://assets/dogica/TTF/dogicabold.ttf") as Font)
	_gold_label.add_theme_font_size_override("font_size", 16)
	_gold_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.2))
	_gold_label.layout_mode = 0
	_gold_label.offset_left  = -100.0
	_gold_label.offset_top   = 100.0
	_gold_label.offset_right = 900.0
	_gold_label.offset_bottom = 132.0
	_gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	$Overlay/Card.add_child(_gold_label)
	_refresh_gold_label()


func _refresh_gold_label() -> void:
	if _gold_label != null:
		_gold_label.text = "Your Gold: %d" % PlayerState.player_gold


# ── Populate shop slots ────────────────────────────────────────────────────────

func _populate_slots() -> void:
	_shop_items.clear()
	var rng := RandomNumberGenerator.new()
	rng.randomize()

	var name_labels := _name_labels()
	var buttons := _slot_buttons()

	for i in range(buttons.size()):
		# Pick a random rank (1-7), weighted toward lower ranks for affordable items
		var rank: int = rng.randi_range(1, 7)
		# 60% chance to draw from reward options, 40% default
		var all_options: Array = RankAbilityCatalog.reward_options_for_rank(rank)
		all_options.append(RankAbilityCatalog.default_element_for_rank(rank))
		var ability: Dictionary = all_options[rng.randi() % all_options.size()]
		var cost: int = RANK_COST[rank]

		_shop_items.append({"ability": ability, "cost": cost, "rank": rank})

		# What does this replace? Show the currently-equipped ability at this rank.
		var current_ability = PlayerState.elements.get(rank)
		var current_name := "None" if current_ability == null else String(current_ability.get("name", "?"))

		# Label shows: name / cost / what it replaces.  Full description appears as tooltip on hover.
		if i < name_labels.size() and name_labels[i] != null:
			name_labels[i].text = (
				"%s\n\n%d G\n──────\n⬇ Replaces:\n%s" % [
					ability.get("name", "?"), cost, current_name
				]
			)
			name_labels[i].offset_top   = 100.0
			name_labels[i].offset_bottom = 218.0
			name_labels[i].autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			name_labels[i].vertical_alignment = VERTICAL_ALIGNMENT_TOP

		if i < buttons.size() and buttons[i] != null:
			buttons[i].disabled = false
			_tint_slot_by_rank(buttons[i], rank)
			# Full description shown on hover via Godot's built-in tooltip.
			buttons[i].tooltip_text = (
				"[Rank %d]  %s\n%s" % [rank, ability.get("name", "?"), ability.get("description", "")]
			)
			# Draw a rank badge (big number) in the PreviewRoot area.
			_add_rank_badge(buttons[i], rank)


func _tint_slot_by_rank(btn: Button, rank: int) -> void:
	var tint := _rank_color(rank)
	var sb := StyleBoxFlat.new()
	sb.bg_color = tint.darkened(0.6)
	sb.border_color = tint.lightened(0.15)
	sb.set_border_width_all(3)
	for s in range(4):
		sb.set_corner_radius(s, 18)
	btn.add_theme_stylebox_override("normal", sb)
	var sb_h := sb.duplicate() as StyleBoxFlat
	sb_h.bg_color = tint.darkened(0.45)
	btn.add_theme_stylebox_override("hover", sb_h)

	var sb_d := sb.duplicate() as StyleBoxFlat
	sb_d.bg_color = Color(0.18, 0.18, 0.22)
	sb_d.border_color = Color(0.4, 0.4, 0.5)
	btn.add_theme_stylebox_override("disabled", sb_d)


func _rank_color(rank: int) -> Color:
	match rank:
		1: return Color(0.75, 0.75, 0.75)
		2: return Color(0.3, 0.85, 0.3)
		3: return Color(0.35, 0.55, 1.0)
		4: return Color(0.8, 0.35, 0.9)
		5: return Color(1.0, 0.85, 0.2)
		6: return Color(1.0, 0.5, 0.15)
		7: return Color(1.0, 0.25, 0.25)
	return Color.WHITE


# ── Signals ────────────────────────────────────────────────────────────────────

func _connect_signals() -> void:
	var buttons := _slot_buttons()
	for i in range(buttons.size()):
		if buttons[i] == null:
			continue
		buttons[i].pressed.connect(_on_slot_pressed.bind(i))
		buttons[i].mouse_entered.connect(_on_slot_hovered.bind(i))
		buttons[i].mouse_exited.connect(_on_slot_unhovered)
	_continue_button().pressed.connect(_on_continue_pressed)
	_continue_button().disabled = false


func _on_slot_hovered(_index: int) -> void:
	pass  # Tooltip is handled by Godot's built-in tooltip_text on the Button.


func _on_slot_unhovered() -> void:
	pass


func _on_slot_pressed(index: int) -> void:
	if index >= _shop_items.size():
		return
	var item: Dictionary = _shop_items[index]
	var cost: int = int(item.get("cost", 0))
	var ability: Dictionary = item.get("ability", {})
	var rank: int = int(item.get("rank", 1))

	if PlayerState.player_gold < cost:
		# Flash the slot red to indicate can't afford
		var btn := _slot_buttons()[index]
		if btn != null:
			var tween := create_tween()
			tween.tween_property(btn, "modulate", Color(1, 0.3, 0.3), 0.1)
			tween.tween_property(btn, "modulate", Color(1, 1, 1), 0.3)
		return

	PlayerState.spend_gold(cost)
	PlayerState.equip_rank_ability(rank, ability)
	_slot_buttons()[index].disabled = true
	_refresh_gold_label()

	# Update the label to confirm purchase and clear the "replaces" info.
	var name_labels := _name_labels()
	if index < name_labels.size() and name_labels[index] != null:
		name_labels[index].text = "✓ Purchased!\n\n%s\n──────\n(slot updated)" % ability.get("name", "?")


func _on_continue_pressed() -> void:
	selection_completed.emit()
	GameManager.complete_current_room()


# ── Rank badge ─────────────────────────────────────────────────────────────────

## Adds (or updates) a large rank-number label inside the button's PreviewRoot.
func _add_rank_badge(btn: Button, rank: int) -> void:
	var preview := btn.get_node_or_null("PreviewRoot") as Node2D
	if preview == null:
		return
	# Reuse an existing badge if present (e.g. when re-rolling).
	var badge := preview.get_node_or_null("RankBadge") as Label
	if badge == null:
		badge = Label.new()
		badge.name = "RankBadge"
		badge.add_theme_font_override("font",
			load("res://assets/dogica/TTF/dogicabold.ttf") as Font)
		badge.add_theme_font_size_override("font_size", 38)
		badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		badge.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		badge.layout_mode = 0
		badge.offset_left   = -42.0
		badge.offset_top    = -28.0
		badge.offset_right  =  42.0
		badge.offset_bottom =  28.0
		preview.add_child(badge)
	badge.text = "R%d" % rank
	badge.add_theme_color_override("font_color", _rank_color(rank).lightened(0.25))


# ── Node helpers ───────────────────────────────────────────────────────────────

func _slot_buttons() -> Array[Button]:
	var buttons: Array[Button] = []
	for button in $Overlay/Card/Slots.get_children():
		if button is Button:
			buttons.append(button as Button)
	return buttons


func _name_labels() -> Array[Label]:
	return [
		$Overlay/Card/Slots/item1/Name as Label,
		$Overlay/Card/Slots/item2/Name as Label,
		$Overlay/Card/Slots/item3/Name as Label,
		$Overlay/Card/Slots/Slot3/Name as Label,
		$Overlay/Card/Slots/item4/Name as Label,
	]


func _continue_button() -> Button:
	return $Overlay/Card/Continue as Button
