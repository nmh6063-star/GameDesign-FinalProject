extends RefCounted
class_name EnemySlotController

const EnemyCatalog := preload("res://script/entities/enemies/enemy_catalog.gd")
const EnemyBase := preload("res://script/entities/enemies/enemy_base.gd")
const DAMAGE_RISE_PX := 60.0
const DAMAGE_DURATION := 0.8
const DAMAGE_FONT_PX := 46

var _slot: Node2D
var _spawn: Marker2D
var _enemy_id := ""
var _ui_root: Node2D
var _bar: Control
var _background: ColorRect
var _fill: ColorRect
var _hp_label: Label
var _cooldown_ring: Node2D
var _selection_box: Control
var _damage_floaters: Node2D
var _damage_anchor: Marker2D

var enemy: EnemyBase
var _selected := false


func _init(slot: Node2D, spawn: Marker2D, enemy_id: String) -> void:
	_slot = slot
	_spawn = spawn
	_enemy_id = enemy_id
	_damage_anchor = _slot.get_node("DamageAnchorEnemy") as Marker2D
	_bind_ui()
	_ui_root.visible = false
	_bar.visible = false
	_cooldown_ring.visible = false
	_selection_box.visible = false
	_sync_ui_position()


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
		return null
	_slot.visible = true
	_slot.process_mode = Node.PROCESS_MODE_INHERIT
	_ui_root.visible = true
	_sync_ui_position()
	enemy = enemy_scene.instantiate() as EnemyBase
	enemy.data = enemy_data
	enemy.position = _spawn.position
	_slot.add_child(enemy)
	enemy.setup()
	return enemy


func set_selected(selected: bool) -> void:
	_selected = selected
	_selection_box.visible = selected and enemy != null and enemy.is_alive()


func show_damage(amount: int, color: Color) -> void:
	if amount <= 0:
		return
	_sync_ui_position()
	var floater := Label.new()
	_damage_floaters.add_child(floater)
	floater.position = _damage_anchor.position
	floater.text = str(amount)
	floater.modulate = color
	floater.modulate.a = 1.0
	floater.scale = Vector2.ONE
	floater.add_theme_font_size_override("font_size", DAMAGE_FONT_PX)
	var tween := _slot.create_tween()
	tween.set_parallel(true)
	tween.tween_property(floater, "position", floater.position + Vector2(0, -DAMAGE_RISE_PX), DAMAGE_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(floater, "scale", Vector2(1.48, 1.48), DAMAGE_DURATION * 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(floater, "modulate:a", 0.0, DAMAGE_DURATION).set_delay(DAMAGE_DURATION * 0.15)
	tween.set_parallel(false)
	tween.tween_callback(floater.queue_free)


func sync_view() -> void:
	_sync_ui_position()
	sync_realtime_view()


func sync_realtime_view() -> void:
	_sync_ui_position()
	var alive := enemy != null and enemy.is_alive()
	var cooldown_total: float = enemy.cooldown_total() if alive else 0.0
	_bar.visible = alive
	_cooldown_ring.visible = alive and cooldown_total > 0.0
	_selection_box.visible = _selected and alive
	if alive:
		_fill.size.x = _background.size.x * float(enemy.health()) / float(enemy.max_health())
		_hp_label.text = "%d/%d" % [enemy.health(), enemy.max_health()]
	if alive and cooldown_total > 0.0:
		_cooldown_ring.call("sync", enemy.cooldown_left(), cooldown_total)


func is_alive() -> bool:
	return enemy != null and enemy.is_alive()


func _bind_ui() -> void:
	_ui_root = _slot.get_tree().current_scene.get_node("UI/EnemyUi/%s" % _slot.name) as Node2D
	_bar = _ui_root.get_node("EnemyHealthBar") as Control
	_background = _ui_root.get_node("EnemyHealthBar/Background") as ColorRect
	_fill = _ui_root.get_node("EnemyHealthBar/Fill") as ColorRect
	_hp_label = _ui_root.get_node("EnemyHealthBar/Label") as Label
	_cooldown_ring = _ui_root.get_node("CooldownRing") as Node2D
	_selection_box = _ui_root.get_node("SelectionBox") as Control
	_damage_floaters = _ui_root.get_node("DamageFloaters") as Node2D


func _sync_ui_position() -> void:
	if _ui_root != null:
		_ui_root.position = _slot.get_global_transform_with_canvas().origin
