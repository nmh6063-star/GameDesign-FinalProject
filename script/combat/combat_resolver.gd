extends RefCounted

func player_attack(enemy: Node, attack: int) -> bool:
	if enemy == null or not is_instance_valid(enemy):
		return false
	enemy.apply_attack(attack)
	return enemy.current_health <= 0


func enemy_attack_damage(enemy: Node) -> int:
	if enemy == null or not is_instance_valid(enemy):
		return 0
	return enemy.attack_damage
