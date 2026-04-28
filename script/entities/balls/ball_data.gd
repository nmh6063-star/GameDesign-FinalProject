extends Resource
class_name BallData

const NO_COLOR_STEP := Color(0, 0, 0, 0)

@export var id := ""
@export var display_name := ""
@export_multiline var description := ""
@export var tags: PackedStringArray = []
@export var spawn_weight := 1
@export var spawn_ranks := PackedInt32Array([1])
@export var symbol := ""
@export var tint := Color(0.5, 0.5, 0.5)
@export var outline_tint := NO_COLOR_STEP
@export var rank_tint_step := NO_COLOR_STEP
@export var base_radius := 20.0
@export var merge_growth := 5.0
@export var merge_rule: MergeRuleBase
@export var effects: Array[BallEffectBase] = []
var element_list = []


func has_tag(tag: String) -> bool:
	return tags.has(tag)


func participates_in_rank_merge() -> bool:
	return merge_rule != null and merge_rule.participates_in_rank_merge()


func is_elemental() -> bool:
	return participates_in_rank_merge()


func display_label(rank: int) -> String:
	return str(rank) if participates_in_rank_merge() else symbol


func display_color(rank: int) -> Color:
	if not participates_in_rank_merge():
		return tint
	var tint_step := rank_tint_step
	# Backward compatibility for existing .tres resources saved before rank rename.
	if tint_step == NO_COLOR_STEP:
		var legacy_tint_step = get("level_tint_step")
		if legacy_tint_step is Color:
			tint_step = legacy_tint_step
	return tint + tint_step * float(rank - 1)


func display_outline_color(rank: int) -> Color:
	return display_color(rank) if outline_tint.a == 0.0 else outline_tint


func radius_for_rank(rank: int) -> float:
	var radius := base_radius
	if not participates_in_rank_merge():
		return radius
	for i in range(1, rank):
		radius += merge_growth / float(i/2.0)
	return radius


func random_spawn_rank() -> int:
	var ranks := spawn_ranks
	if ranks.is_empty():
		# Backward compatibility for existing .tres resources saved before rank rename.
		var legacy_ranks = get("spawn_levels")
		if legacy_ranks is PackedInt32Array and not legacy_ranks.is_empty():
			ranks = legacy_ranks
	if ranks.is_empty():
		return 1
	var picked := int(ranks[randi() % ranks.size()])
	return clampi(picked, 1, 7)
