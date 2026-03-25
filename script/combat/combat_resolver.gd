extends RefCounted

func player_attack(enemy: Node, attack: int) -> bool:
	enemy.apply_attack(attack)
	return enemy.current_health <= 0


func enemy_attack_damage(enemy: Node) -> int:
	return enemy.attack_damage
