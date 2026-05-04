extends RefCounted
class_name EnemySlotController

const EnemyCatalog := preload("res://script/entities/enemies/enemy_catalog.gd")
const EnemyBase := preload("res://script/entities/enemies/enemy_base.gd")
const DOGICA_FONT := preload("res://assets/dogica/TTF/dogicabold.ttf")
const DAMAGE_RISE_PX := 60.0
const DAMAGE_DURATION := 0.8
const DAMAGE_FONT_PX := 46
const SHIELD_FONT_PX := 28
const DAMAGE_JITTER_X := 42.0
const DAMAGE_JITTER_Y := 28.0
const DAMAGE_RISE_JITTER_X := 26.0
const SHIELD_COLOR := Color(0.62, 0.72, 0.68, 1.0)

var _slot: Node2D
var _spawn: Marker2D
var _enemy_id := ""
var _ui_root: Node2D
var _bar: Control
var _background: ColorRect
var _fill: ColorRect
var _hp_label: Label
var _shield_bar: Control
var _shield_background: ColorRect
var _shield_fill: ColorRect
var _shield_label: Label
var _cooldown_ring: Node2D
var _selection_box: Control
var _damage_floaters: Node2D
var _damage_anchor: Marker2D
var _attack_tooltip: Panel
var _attack_summary_label: Label
var _attack_damage_label: Label
var _status_tag_label: Label

var enemy: EnemyBase
var _selected := false


func _init(slot: Node2D, spawn: Marker2D, enemy_id: String) -> void:
	_slot = slot
	_spawn = spawn
	_enemy_id = enemy_id
	_damage_anchor = _slot.get_node("DamageAnchorEnemy") as Marker2D
	_bind_ui()
	_style_ui()
	_ui_root.visible = false
	_bar.visible = false
	_cooldown_ring.visible = false
	_selection_box.visible = false
	_attack_tooltip.visible = false


func spawn_enemy() -> EnemyBase:
	if is_instance_valid(enemy):
		enemy.queue_free()
	enemy = null
	var enemy_scene := EnemyCatalog.scene_for_id(_enemy_id)
	var enemy_data := EnemyCatalog.data_for_id(_enemy_id)
	if _spawn == null or enemy_scene == null or enemy_data == null:
		_slot.visible = false
		_slot.process_mode = Node.PROCESS_MODE_DISABLED
		_ui_root.visible = false
		_bar.visible = false
		_cooldown_ring.visible = false
		_selection_box.visible = false
		_attack_tooltip.visible = false
		return null
	_slot.visible = true
	_slot.process_mode = Node.PROCESS_MODE_INHERIT
	_ui_root.visible = true
	enemy = enemy_scene.instantiate() as EnemyBase
	enemy.data = enemy_data
	enemy.position = _spawn.position
	_slot.add_child(enemy)
	enemy.setup()
	enemy.shield_restored.connect(func(amount: int) -> void:
		show_shield_gain(amount)
		sync_shield(enemy.shield(), enemy.max_shield())
	)
	return enemy


func set_selected(selected: bool) -> void:
	_selected = selected
	_selection_box.visible = selected and enemy != null and enemy.is_alive()


func show_damage(amount: int, color: Color) -> void:
	if amount <= 0:
		return
	var floater := Label.new()
	_damage_floaters.add_child(floater)
	var jitter := Vector2(
		randf_range(-DAMAGE_JITTER_X, DAMAGE_JITTER_X),
		randf_range(-DAMAGE_JITTER_Y, DAMAGE_JITTER_Y)
	)
	floater.position = _damage_anchor.position + jitter
	floater.text = str(amount)
	floater.modulate = color
	floater.modulate.a = 1.0
	floater.scale = Vector2.ONE
	floater.add_theme_font_override("font", DOGICA_FONT)
	floater.add_theme_font_size_override("font_size", DAMAGE_FONT_PX)
	var rise_target := floater.position + Vector2(randf_range(-DAMAGE_RISE_JITTER_X, DAMAGE_RISE_JITTER_X), -DAMAGE_RISE_PX)
	var tween := _slot.create_tween()
	tween.set_parallel(true)
	tween.tween_property(floater, "position", rise_target, DAMAGE_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(floater, "scale", Vector2(1.48, 1.48), DAMAGE_DURATION * 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(floater, "modulate:a", 0.0, DAMAGE_DURATION).set_delay(DAMAGE_DURATION * 0.15)
	tween.set_parallel(false)
	tween.tween_callback(floater.queue_free)


func show_shield_gain(amount: int) -> void:
	if amount <= 0:
		return
	var floater := Label.new()
	_damage_floaters.add_child(floater)
	var jitter := Vector2(
		randf_range(-DAMAGE_JITTER_X, DAMAGE_JITTER_X),
		randf_range(-DAMAGE_JITTER_Y, DAMAGE_JITTER_Y)
	)
	floater.position = _damage_anchor.position + jitter
	floater.text = "+%d" % amount
	floater.modulate = SHIELD_COLOR
	floater.modulate.a = 1.0
	floater.scale = Vector2.ONE
	floater.add_theme_font_override("font", DOGICA_FONT)
	floater.add_theme_font_size_override("font_size", SHIELD_FONT_PX)
	var rise_target := floater.position + Vector2(randf_range(-DAMAGE_RISE_JITTER_X, DAMAGE_RISE_JITTER_X), -DAMAGE_RISE_PX)
	var tween := _slot.create_tween()
	tween.set_parallel(true)
	tween.tween_property(floater, "position", rise_target, DAMAGE_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(floater, "scale", Vector2(1.2, 1.2), DAMAGE_DURATION * 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(floater, "modulate:a", 0.0, DAMAGE_DURATION).set_delay(DAMAGE_DURATION * 0.15)
	tween.set_parallel(false)
	tween.tween_callback(floater.queue_free)


func sync_view() -> void:
	sync_realtime_view()


func sync_realtime_view() -> void:
	var alive := enemy != null and enemy.is_alive()
	var cooldown_total: float = enemy.cooldown_total() if alive else 0.0
	_bar.visible = alive
	_cooldown_ring.visible = alive and cooldown_total > 0.0
	_selection_box.visible = _selected and alive
	_attack_tooltip.visible = false
	if alive:
		_fill.size.x = _background.size.x * float(enemy.health()) / float(enemy.max_health())
		_hp_label.text = "%d/%d" % [enemy.health(), enemy.max_health()]
		sync_shield(enemy.shield(), enemy.max_shield())
	elif _shield_bar != null:
		_shield_bar.visible = false
	if alive and cooldown_total > 0.0:
		_cooldown_ring.call("sync", enemy.cooldown_left(), cooldown_total)
		_sync_attack_tooltip()


func is_alive() -> bool:
	return enemy != null and enemy.is_alive()


func sync_shield(shield: int, max_shield: int) -> void:
	if _shield_bar == null:
		return
	if shield <= 0 or max_shield <= 0:
		_shield_bar.visible = false
		return
	_shield_bar.visible = true
	_shield_fill.size.x = _shield_background.size.x * float(mini(shield, max_shield)) / float(max_shield)
	if _shield_label != null:
		_shield_label.text = "%d/%d" % [shield, max_shield]


func _bind_ui() -> void:
	_ui_root = _slot.get_node("EnemyUi") as Node2D
	_bar = _ui_root.get_node("EnemyHealthBar") as Control
	_background = _ui_root.get_node("EnemyHealthBar/Background") as ColorRect
	_fill = _ui_root.get_node("EnemyHealthBar/Fill") as ColorRect
	_hp_label = _ui_root.get_node("EnemyHealthBar/Label") as Label
	_shield_bar = _ui_root.get_node_or_null("EnemyShieldBar") as Control
	if _shield_bar != null:
		_shield_background = _shield_bar.get_node("Background") as ColorRect
		_shield_fill = _shield_bar.get_node("Fill") as ColorRect
		_shield_label = _shield_bar.get_node("Label") as Label
	_cooldown_ring = _ui_root.get_node("CooldownRing") as Node2D
	_selection_box = _ui_root.get_node("SelectionBox") as Control
	_damage_floaters = _ui_root.get_node("DamageFloaters") as Node2D
	_attack_tooltip = _ensure_tooltip_panel()
	_attack_summary_label = _attack_tooltip.get_node("Summary") as Label
	_attack_damage_label = _attack_tooltip.get_node("Damage") as Label
	_status_tag_label = _ensure_status_tag()


func _style_ui() -> void:
	_bar.position = Vector2(-52, 62)
	_bar.size = Vector2(112, 16)
	_background.color = Color(0.02, 0.02, 0.05, 1.0)
	_fill.color = Color(0.83, 0.06, 0.0, 1.0)
	if _shield_bar != null:
		_shield_bar.position = Vector2(-52, 80)
		_shield_bar.size = Vector2(112, 12)
		_shield_background.color = Color(0.02, 0.02, 0.05, 1.0)
		_shield_fill.color = Color(0.46, 0.54, 0.51, 1.0)
		_shield_bar.visible = false
	_hp_label.add_theme_font_override("font", DOGICA_FONT)
	_hp_label.add_theme_font_size_override("font_size", 9)
	_selection_box.position = Vector2(-56, -68)
	_selection_box.size = Vector2(122, 118)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1, 1, 1, 0)
	style.set_corner_radius_all(18)
	style.border_width_left = 4
	style.border_width_top = 4
	style.border_width_right = 4
	style.border_width_bottom = 4
	style.border_color = Color(0.94, 0.9, 0.39, 1.0)
	(_selection_box as Panel).add_theme_stylebox_override("panel", style)


func _ensure_tooltip_panel() -> Panel:
	var tooltip := _ui_root.get_node_or_null("AttackTooltip") as Panel
	if tooltip == null:
		tooltip = Panel.new()
		tooltip.name = "AttackTooltip"
		_ui_root.add_child(tooltip)
	tooltip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tooltip.position = Vector2(122, -22)
	tooltip.size = Vector2(154, 88)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.88, 0.88, 0.88, 0.96)
	style.set_corner_radius_all(18)
	tooltip.add_theme_stylebox_override("panel", style)
	tooltip.visible = false

	var summary := tooltip.get_node_or_null("Summary") as Label
	if summary == null:
		summary = Label.new()
		summary.name = "Summary"
		tooltip.add_child(summary)
	summary.mouse_filter = Control.MOUSE_FILTER_IGNORE
	summary.position = Vector2(10, 10)
	summary.size = Vector2(134, 46)
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary.add_theme_font_override("font", DOGICA_FONT)
	summary.add_theme_font_size_override("font_size", 8)

	var damage := tooltip.get_node_or_null("Damage") as Label
	if damage == null:
		damage = Label.new()
		damage.name = "Damage"
		tooltip.add_child(damage)
	damage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	damage.position = Vector2(10, 58)
	damage.size = Vector2(134, 16)
	damage.add_theme_font_override("font", DOGICA_FONT)
	damage.add_theme_font_size_override("font_size", 8)
	return tooltip


func _sync_attack_tooltip() -> void:
	if enemy == null or enemy.data == null:
		_attack_tooltip.visible = false
		return
	_attack_summary_label.text = _action_summary()
	_attack_damage_label.text = "Damage: %d" % enemy.data.attack_damage
	_attack_tooltip.visible = _is_hovering_cooldown()


func sync_status_tag(ctx: BattleContext) -> void:
	if _status_tag_label == null:
		return
	if enemy == null or not enemy.is_alive():
		_status_tag_label.text = ""
		return
	var st := ctx.status_for_enemy(enemy)
	var tags: Array[String] = []
	var poison := int(st.get("poison_stack", 0))
	if poison > 0:
		tags.append("Poison %d" % poison)
	var burn := int(st.get("burn_stack", 0))
	if burn > 0:
		tags.append("Burn %d" % burn)
	var freeze := int(st.get("freeze_stack", 0))
	if freeze > 0:
		tags.append("Freeze %d" % freeze)
	var charm := int(st.get("charm_stack", 0))
	if charm > 0:
		tags.append("Charm %d" % charm)
	_status_tag_label.text = " | ".join(tags)


func _is_hovering_cooldown() -> bool:
	var radius := float(_cooldown_ring.get("radius")) + 8.0
	return _slot.get_global_mouse_position().distance_to(_cooldown_ring.global_position) <= radius


func _action_summary() -> String:
	if enemy == null or enemy.data == null or enemy.data.actions.is_empty():
		return "Enemy attack."
	var action = enemy.data.actions[0]
	var script_path := ""
	if action != null and action.get_script() != null:
		script_path = String(action.get_script().resource_path)
	if script_path.ends_with("rock_drop_action.gd"):
		return "Drops a rock onto\nthe board."
	return "Direct player\nattack."


func _ensure_status_tag() -> Label:
	var label := _ui_root.get_node_or_null("StatusTag") as Label
	if label == null:
		label = Label.new()
		label.name = "StatusTag"
		_ui_root.add_child(label)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.position = Vector2(-52, 42)
	label.size = Vector2(180, 16)
	label.add_theme_font_override("font", DOGICA_FONT)
	label.add_theme_font_size_override("font_size", 8)
	return label
