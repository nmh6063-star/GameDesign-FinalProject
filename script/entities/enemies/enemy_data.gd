extends Resource
class_name EnemyData

@export var id := ""
@export var display_name := ""
@export var sprite_texture: Texture2D
@export var sprite_region := Rect2()
@export var sprite_scale := Vector2.ONE
@export var max_health := 50
@export var max_shield := 0
@export var attack_damage := 10
@export var attack_interval := 5.0
@export var actions: Array[EnemyActionBase] = []
@export var effects: Array[EnemyEffectBase] = []

## Global tuning: exported `attack_damage` is halved when applied to the player.
const DAMAGE_TO_PLAYER_MULT := 0.5
## Shorter wait between attacks (half the exported interval = ~2× attack frequency).
const ATTACK_INTERVAL_MULT := 0.5


func effective_attack_damage() -> int:
	if attack_damage <= 0:
		return attack_damage
	return maxi(1, int(round(float(attack_damage) * DAMAGE_TO_PLAYER_MULT)))


func effective_attack_interval() -> float:
	if attack_interval <= 0.0:
		return attack_interval
	# Avoid pathological near-zero timers if data is already very small.
	return maxf(0.05, attack_interval * ATTACK_INTERVAL_MULT)
