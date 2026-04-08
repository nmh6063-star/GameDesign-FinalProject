extends Resource
class_name EnemyData

@export var id := ""
@export var display_name := ""
@export var max_health := 50
@export var attack_damage := 10
@export var attack_interval := 5.0
@export var actions: Array[EnemyAction] = []
