extends CanvasLayer
class_name BattleHud

const ShootAmmo := preload("res://script/battle/state/ammo.gd")
const DAMAGE_FLOATER_SCENE := preload("res://scenes/damage_floater.tscn")
const PLAYER_DAMAGE_COLOR := Color(1, 0.3, 0.3)
const ENEMY_DAMAGE_COLOR := Color(0.92, 0.58, 0.06)
const HEAL_COLOR := Color(0.35, 0.92, 0.55)

@onready var _player_fill: ColorRect = $PlayerHealthBar/Fill
@onready var _player_hp_text: Label = $PlayerHealthBar/HPText
@onready var _player_hp_top: Label = $TopBar/PlayerHPText
@onready var _energy_label: Label = $EnergyLabel
@onready var _energy_badge_text: Label = $CostBadge/CostText
@onready var _result_label: Label = $ResultLabel
@onready var _shoot_ammo_hud = $ShootAmmoHUD
@onready var _damage_anchor_player: Marker2D = $DamageAnchorPlayer
@onready var _damage_anchor_enemy: Marker2D = $DamageAnchorEnemy


func sync_player(health: int, max_health: int) -> void:
	var text := "%d/%d" % [health, max_health]
	_player_fill.size.x = 100.0 * float(health) / float(max_health)
	_player_hp_text.text = text
	_player_hp_top.text = text


func sync_energy(current: int, max_value: int) -> void:
	_energy_label.visible = true
	_energy_badge_text.text = "%d/%d" % [current, max_value]


func sync_shoot_ammo(bullets: int, merge_progress: int) -> void:
	_shoot_ammo_hud.sync_state(bullets, merge_progress, ShootAmmo.MERGES_PER_BULLET)


func show_player_damage(amount: int) -> void:
	_show_damage(amount, _damage_anchor_player, PLAYER_DAMAGE_COLOR)


func show_enemy_damage(amount: int) -> void:
	_show_damage(amount, _damage_anchor_enemy, ENEMY_DAMAGE_COLOR)


func show_heal(amount: int) -> void:
	_show_damage(amount, _damage_anchor_player, HEAL_COLOR)


func clear_result() -> void:
	_result_label.visible = false


func show_result(text: String) -> void:
	_result_label.text = text
	_result_label.visible = true


func has_result() -> bool:
	return _result_label.visible


func _show_damage(amount: int, anchor: Marker2D, color: Color) -> void:
	if amount <= 0:
		return
	var floater = DAMAGE_FLOATER_SCENE.instantiate()
	add_child(floater)
	(floater as Label).global_position = anchor.global_position
	floater.play(amount, color)
