extends Node2D
class_name EnemyBase

const EnemyData := preload("res://script/entities/enemies/enemy_data.gd")

signal damaged(amount: int)
signal shield_restored(amount: int)
signal defeated
signal action_requested

@export var data: EnemyData

var current_health := 0
var current_shield := 0
var _action_index := 0

@onready var _sprite := $Sprite2D as Sprite2D
@onready var _base_modulate: Color = _sprite.modulate
@onready var _flash_timer := $Timer as Timer
@onready var _attack_cooldown := $AttackCooldown as Timer


func _ready() -> void:
	add_to_group("enemy")
	reset()


func setup() -> void:
	reset()


func reset() -> void:
	current_health = max_health()
	current_shield = max_shield()
	_action_index = 0
	visible = true
	process_mode = Node.PROCESS_MODE_INHERIT
	_apply_visuals()
	_sprite.modulate = _base_modulate
	_restart_attack_cooldown()


func health() -> int:
	return current_health


func max_health() -> int:
	return data.max_health if data != null else 0


func shield() -> int:
	return current_shield


func max_shield() -> int:
	return data.max_shield if data != null else 0


func restore_shield(amount: int) -> void:
	if amount <= 0 or max_shield() <= 0:
		return
	var gained := mini(amount, max_shield() - current_shield)
	if gained <= 0:
		return
	current_shield += gained
	shield_restored.emit(gained)


func is_alive() -> bool:
	return current_health > 0


func take_damage(amount: int) -> int:
	return take_damage_with_context(amount, null)


func take_damage_with_context(amount: int, ctx: BattleContext = null) -> int:
	if amount <= 0 or not is_alive():
		return 0
	if current_shield > 0:
		var absorbed := mini(current_shield, amount)
		current_shield -= absorbed
		amount -= absorbed
		if amount <= 0:
			return 0
	var applied := mini(amount, current_health)
	damaged.emit(applied)
	current_health -= applied
	for effect in _effects():
		effect.on_hit(ctx, self, applied)
	if current_health == 0:
		for effect in _effects():
			effect.on_defeated(ctx, self)
		_attack_cooldown.stop()
		_flash_timer.stop()
		visible = false
		process_mode = Node.PROCESS_MODE_DISABLED
		defeated.emit()
	return applied


func on_turn(ctx: BattleContext) -> void:
	if not is_alive() or data == null or data.actions.is_empty():
		return
	for effect in _effects():
		effect.on_turn_start(ctx, self)
	var count := data.actions.size()
	for i in range(count):
		var idx := (_action_index + i) % count
		var action = data.actions[idx]
		if action == null:
			continue
		if action.can_use(ctx, self):
			_action_index = (idx + 1) % count
			for effect in _effects():
				effect.on_before_act(ctx, self, action)
			action.execute(ctx, self)
			for effect in _effects():
				effect.on_after_act(ctx, self, action)
			return


func next_action() -> EnemyActionBase:
	if data == null or data.actions.is_empty():
		return null
	return data.actions[_action_index]


func cooldown_left() -> float:
	return _attack_cooldown.time_left


func cooldown_total() -> float:
	return data.attack_interval if data != null else 0.0


func flash() -> void:
	_sprite.modulate = Color(18.892, 0.0, 0.0)
	_flash_timer.start()


func _on_timer_timeout() -> void:
	_sprite.modulate = _base_modulate


func _on_attack_cooldown_timeout() -> void:
	if not is_alive():
		return
	action_requested.emit()
	_restart_attack_cooldown()


func _restart_attack_cooldown() -> void:
	if data == null or data.attack_interval <= 0.0:
		_attack_cooldown.stop()
		return
	_attack_cooldown.wait_time = data.attack_interval
	_attack_cooldown.start()


func _apply_visuals() -> void:
	if data == null:
		return
	_sprite.texture = data.sprite_texture
	_sprite.region_enabled = data.sprite_region.size != Vector2.ZERO
	_sprite.region_rect = data.sprite_region
	_sprite.scale = data.sprite_scale
	_base_modulate = _sprite.modulate


func _effects() -> Array:
	return data.effects if data != null else []
