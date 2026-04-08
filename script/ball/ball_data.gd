extends Resource
class_name BallData

const NO_COLOR_STEP := Color(0, 0, 0, 0)

@export var id := ""
@export var display_name := ""
@export var tags: PackedStringArray = []
@export var spawn_weight := 1
@export var spawn_levels := PackedInt32Array([1])
@export var symbol := ""
@export var tint := Color(0.5, 0.5, 0.5)
@export var level_tint_step := NO_COLOR_STEP
@export var base_radius := 20.0
@export var merge_growth := 5.0
@export var merge_rule: MergeRule
@export var effects: Array[BallEffect] = []


func has_tag(tag: String) -> bool:
	return tags.has(tag)


func participates_in_level_merge() -> bool:
	return merge_rule.participates_in_level_merge()


func display_label(level: int) -> String:
	return str(level) if participates_in_level_merge() else symbol


func display_color(level: int) -> Color:
	if not participates_in_level_merge():
		return tint
	return tint + level_tint_step * float(level - 1)


func radius_for_level(level: int) -> float:
	var radius := base_radius
	if not participates_in_level_merge():
		return radius
	for i in range(1, level):
		radius += merge_growth / float(i)
	return radius


func random_spawn_level() -> int:
	return int(spawn_levels[randi() % spawn_levels.size()])
