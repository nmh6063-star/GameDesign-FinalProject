extends Node2D
class_name EnemyHolderSlot

const BattleEnemy := preload("res://script/enemy/enemy.gd")
const DAMAGE_FLOATER_SCENE := preload("res://scenes/damage_floater.tscn")

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

func spawn_enemy() -> BattleEnemy:
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
	enemy.setup()
	return enemy

func set_selected(selected: bool) -> void:
	_selected = selected
	_selection_box.visible = selected and enemy != null and enemy.current_health > 0


func show_damage(amount: int, color: Color) -> void:
	if amount <= 0:
		return
	var floater = DAMAGE_FLOATER_SCENE.instantiate()
	_damage_floaters.add_child(floater)
	(floater as Label).position = damage_anchor.position
	floater.play(amount, color)


func sync_view() -> void:
	var alive := enemy != null and enemy.current_health > 0
	_bar.visible = alive
	_cooldown_ring.visible = alive and enemy.data.attack_interval > 0.0
	_selection_box.visible = _selected and alive
	if alive:
		_fill.size.x = _background.size.x * float(enemy.current_health) / float(enemy.data.max_health)
		_hp_label.text = "%d/%d" % [enemy.current_health, enemy.data.max_health]
		_cooldown_ring.call("sync", enemy.cooldown_left(), enemy.data.attack_interval)
