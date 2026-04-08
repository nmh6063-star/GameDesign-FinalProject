extends Resource
class_name MergeRule


func participates_in_level_merge() -> bool:
	return false


func can_merge(_ctx, _a, _b) -> bool:
	return false


func resolve(_ctx, _a, _b) -> void:
	push_error("MergeRule.resolve() must be implemented")
