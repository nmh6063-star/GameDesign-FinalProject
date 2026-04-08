extends Node2D
class_name EnemyHolderSlot

const BattleEnemy := preload("res://script/enemy/enemy.gd")
const DAMAGE_RISE_PX := 60.0
const DAMAGE_DURATION := 0.8
const DAMAGE_FONT_PX := 46

@onready var damage_anchor: Marker2D = $DamageAnchorEnemy
@onready var _spawn = $EnemySpawn
@onready var _bar := $EnemyHealthBar as Control
@onready var _background := $EnemyHealthBar/Background as ColorRect
@onready var _fill := $EnemyHealthBar/Fill as ColorRect
@onready var _hp_label := $EnemyHealthBar/Label as Label
@onready var _cooldown_ring: Node2D = $CooldownRing
@onready var _selection_box := $SelectionBox as Control
@onready var _damage_floaters := $DamageFloaters as Node2D

var enemy: BattleEnemy
var _selected := false

func spawn_enemy(attack_clock_mode: int = BattleEnemy.AttackClock.REAL_TIME) -> BattleEnemy:
	enemy = null
	if _spawn.enemy_scene == null:
		visible = false
		process_mode = Node.PROCESS_MODE_DISABLED
		_bar.visible = false
		_cooldown_ring.visible = false
		_selection_box.visible = false
		return null
	visible = true
	process_mode = Node.PROCESS_MODE_INHERIT
	enemy = _spawn.enemy_scene.instantiate() as BattleEnemy
	add_child(enemy)
	enemy.position = _spawn.position
	enemy.setup(attack_clock_mode)
	return enemy

func set_selected(selected: bool) -> void:
	_selected = selected
	_selection_box.visible = selected and enemy != null and enemy.current_health > 0


func show_damage(amount: int, color: Color) -> void:
	if amount <= 0:
		return
	var floater := Label.new()
	_damage_floaters.add_child(floater)
	floater.position = damage_anchor.position
	floater.text = str(amount)
	floater.modulate = color
	floater.modulate.a = 1.0
	floater.scale = Vector2.ONE
	floater.add_theme_font_size_override("font_size", DAMAGE_FONT_PX)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(floater, "position", floater.position + Vector2(0, -DAMAGE_RISE_PX), DAMAGE_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(floater, "scale", Vector2(1.48, 1.48), DAMAGE_DURATION * 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(floater, "modulate:a", 0.0, DAMAGE_DURATION).set_delay(DAMAGE_DURATION * 0.15)
	tween.set_parallel(false)
	tween.tween_callback(floater.queue_free)


func sync_view() -> void:
	var alive := enemy != null and enemy.current_health > 0
	var cooldown_total: float = enemy.cooldown_total() if alive else 0.0
	_bar.visible = alive
	_cooldown_ring.visible = alive and cooldown_total > 0.0
	_selection_box.visible = _selected and alive
	if alive:
		_fill.size.x = _background.size.x * float(enemy.current_health) / float(enemy.data.max_health)
		_hp_label.text = "%d/%d" % [enemy.current_health, enemy.data.max_health]
		_cooldown_ring.call("sync", enemy.cooldown_left(), cooldown_total)
