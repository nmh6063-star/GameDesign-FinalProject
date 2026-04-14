extends Node2D
class_name EnemyBase

const EnemyData := preload("res://script/entities/enemies/enemy_data.gd")

signal damaged(amount: int)
signal defeated
signal action_requested

@export var data: EnemyData

var current_health := 0

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
	visible = true
	process_mode = Node.PROCESS_MODE_INHERIT
	_apply_visuals()
	_sprite.modulate = _base_modulate
	_restart_attack_cooldown()


func health() -> int:
	return current_health


func max_health() -> int:
	return data.max_health if data != null else 0


func is_alive() -> bool:
	return current_health > 0


func take_damage(amount: int) -> int:
	return take_damage_with_context(amount, null)


func take_damage_with_context(amount: int, ctx: BattleContext = null) -> int:
	if amount <= 0 or not is_alive():
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
	if not is_alive() or data == null:
		return
	for effect in _effects():
		effect.on_turn_start(ctx, self)
	for action in data.actions:
		if action.can_use(ctx, self):
			for effect in _effects():
				effect.on_before_act(ctx, self, action)
			action.execute(ctx, self)
			for effect in _effects():
				effect.on_after_act(ctx, self, action)
			return


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
