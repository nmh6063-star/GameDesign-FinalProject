extends Node
class_name PlaygroundController
## Minimal BattleContext controller for the Playground debug scene.
## Implements just enough of the battle_loop.gd controller interface so that
## RankAbilityEffects.execute() can run against a DummyEnemy.

signal damage_dealt(amount: int, total_dealt: int)
signal player_healed(amount: int)
signal log_message(text: String)

var dummy_enemy: DummyEnemy
## Called back by the playground scene to sync the HP display.
var on_hp_changed: Callable


func damage_enemy(amount: int, _enemy = null, _ctx = null) -> void:
	if dummy_enemy == null or not dummy_enemy.is_alive():
		return
	var applied := dummy_enemy.take_damage_with_context(amount, null)
	if on_hp_changed.is_valid():
		on_hp_changed.call()
	damage_dealt.emit(applied, dummy_enemy.current_health)
	log_message.emit("Dealt [color=orange]%d[/color] dmg → HP %d" % [applied, dummy_enemy.current_health])


func damage_all_enemies(amount: int, _ctx = null) -> void:
	damage_enemy(amount, null, _ctx)


func heal_player(amount: int) -> void:
	PlayerState.heal(amount)
	player_healed.emit(amount)
	log_message.emit("Healed player [color=lime]%d[/color] → %d/%d HP" % [
		amount, PlayerState.player_health, PlayerState.player_max_health])


func damage_player(amount: int) -> void:
	log_message.emit("[color=red]Player would take %d damage[/color] (ignored in playground)" % amount)


func active_enemy() -> DummyEnemy:
	return dummy_enemy


func _alive_enemy_slots() -> Array:
	if dummy_enemy != null and dummy_enemy.is_alive():
		return [{"enemy": dummy_enemy}]
	return []


func active_balls() -> Array:
	return []


func effect_balls() -> Array:
	return []


func spawn_ball_copy(_source, _offset: Vector2 = Vector2.ZERO):
	log_message.emit("[color=gray]spawn_ball_copy ignored in playground[/color]")
	return null


func spawn_ball(_ball_id: String, _origin: Vector2, _impulse: Vector2 = Vector2.ZERO, _rank: int = 1):
	log_message.emit("[color=gray]spawn_ball('%s') ignored in playground[/color]" % _ball_id)
	return null


func drop_ball_in_box(_ball_id: String, _rank: int = 1):
	log_message.emit("[color=gray]drop_ball_in_box('%s') ignored in playground[/color]" % _ball_id)
	return null


func drop_zone_global() -> Vector2:
	return Vector2.ZERO  # playground controller has no box; _safe_origin will use fallback


func burst_knock_on_balls(_origin: Vector2, _strength_scale: float = 1.0) -> void:
	pass


func sync_mana_hud() -> void:
	pass


func sync_combo_hud() -> void:
	pass
