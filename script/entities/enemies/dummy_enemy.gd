extends EnemyBase
class_name DummyEnemy

## Lightweight stand-in enemy used by the Playground scene.
## Bypasses the scene-node requirements of EnemyBase (Sprite2D, Timers).

const DUMMY_HP := 99999


func _ready() -> void:
	add_to_group("enemy")
	current_health = DUMMY_HP


func is_alive() -> bool:
	return current_health > 0


func max_health() -> int:
	return DUMMY_HP


func take_damage_with_context(amount: int, _ctx = null) -> int:
	if amount <= 0 or not is_alive():
		return 0
	var applied := mini(amount, current_health)
	current_health -= applied
	damaged.emit(applied)
	return applied


func take_damage(amount: int) -> int:
	return take_damage_with_context(amount, null)


func reset() -> void:
	current_health = DUMMY_HP


func flash() -> void:
	pass


func cooldown_left() -> float:
	return 0.0


func cooldown_total() -> float:
	return 0.0
