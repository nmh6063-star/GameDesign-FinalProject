extends ElementalRuleBase
class_name ElementalRankAbilities

const RankAbilityEffects := preload("res://script/entities/balls/elemental_balls/rank_ability_effects.gd")

static var functions: Array[String] = [
	"strike",
	"mend",
	"venom",
	"ember",
	"guard",
	"critical",
	"refresh",
	"heavy_strike",
	"recovery",
	"frost_touch",
	"iron_guard",
	"triple_shot",
	"scatter_drop",
	"critical_strike",
	"pollution",
	"fireburn",
	"power_slash",
	"toxic_burst",
	"fireball",
	"ice_lance",
	"reinforce",
	"convert",
	"echo_shot",
	"charm",
	"cleave",
	"greater_heal",
	"bomb_orb",
	"chain_spark",
	"mirror_shield",
	"corrupt_field",
	"critical_edge",
	"freeze_wave",
	"giant_orb",
	"consume_core",
	"upgrade_pulse",
	"poison_rain",
	"time_drift",
	"meteor_crash",
	"full_recovery",
	"chaos_rain",
	"overcharge",
	"mass_morph",
	"reflect_wall",
	"giant_core",
	"final_judgment",
	"apocalypse",
	"resurrection",
	"time_stop",
	"magic_flood",
	"miracle_cascade",
	"sacrifice_nova",
	"one_shower",
]

static var functions_by_id := {}

static func _init_registry() -> void:
	if not functions_by_id.is_empty():
		return
	for fn in functions:
		functions_by_id[fn] = [on_shot, on_shot]


static func get_target_function(_source: BallBase, function: String, function_match: String) -> bool:
	_init_registry()
	var parsed := _parse(function)
	if parsed.is_empty():
		return false
	if not functions_by_id.has(parsed["kind"]):
		return false
	if _source.rank != parsed["rank"]:
		return false
	var function_data: Array = functions_by_id[parsed["kind"]]
	return function_data[1].get_method() == function_match


static func can_trigger(_ctx: BattleContext, _source: BallBase, function: String) -> bool:
	return false


static func apply(_ctx: BattleContext, _source: BallBase, function: String) -> void:
	pass


static func on_shot(_ctx: BattleContext, _source: BallBase, function: String) -> void:
	var parsed := _parse(function)
	if parsed.is_empty():
		return
	if _source.rank != parsed["rank"]:
		return
	RankAbilityEffects.execute(_ctx, _source, String(parsed["kind"]), int(parsed["rank"]))


static func on_merge(_ctx: BattleContext, _source: BallBase, function: String) -> void:
	pass


static func _parse(function: String) -> Dictionary:
	var idx := function.rfind("_")
	if idx < 0:
		return {}
	var rank := function.substr(idx + 1).to_int()
	if rank < 1 or rank > 7:
		return {}
	var kind := function.substr(0, idx)
	return {"kind": kind, "rank": rank}
