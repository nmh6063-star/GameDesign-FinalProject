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
