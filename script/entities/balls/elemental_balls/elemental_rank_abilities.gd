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
	"ice_shield",
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
	"contagion",
	"meteor_crash",
	"full_recovery",
	"chaos_rain",
	"overcharge",
	"mass_morph",
	"reflect_wall",
	"giant_core",
	"dot_siphon",
	"final_judgment",
	"apocalypse",
	"resurrection",
	"time_stop",
	"magic_flood",
	"miracle_cascade",
	"sacrifice_nova",
	"one_shower",
	"dot_echo",
	"thunder_fang",
	"tide_turner",
	"chaos_slash",
	"gatekeeper",
	"storm_surge",
	"baators_flame",
	"thunder_strike",
	"elbaphs_power",
	"decay",
	"regeneration",
	"weakness_brand",
	"lifesteal_field",
	"fortress",
	"guillotine",
	"second_wind",
	"overkill",
]

static var functions_by_id := {}

static var typing_by_id = {
		"strike": {
			"class": "alchemist",
		},
		"mend": {
			"class": "alchemist",
		},
		"venom": {
			"class": "alchemist",
		},
		"ember": {
			"class": "alchemist",
		},
		"guard": {
			"class": "alchemist",
		},
		"critical": {
			"class": "alchemist",
		},
		"refresh": {
			"class": "alchemist",
		},
		"heavy_strike": {
			"class": "alchemist",
		},
		"recovery": {
			"class": "alchemist",
		},
		"frost_touch": {
			"class": "alchemist",
		},
		"iron_guard": {
			"class": "alchemist",
		},
		"triple_shot": {
			"class": "alchemist",
		},
		"scatter_drop": {
			"class": "alchemist",
		},
		"critical_strike": {
			"class": "alchemist",
		},
		"pollution": {
			"class": "alchemist",
		},
		"fireburn": {
			"class": "alchemist",
		},
		"power_slash": {
			"class": "alchemist",
		},
		"toxic_burst": {
			"class": "alchemist",
		},
		"fireball": {
			"class": "alchemist",
		},
	"ice_shield": {
		"class": "alchemist",
	},
	"convert": {
		"class": "alchemist",
	},
	"reinforce": {
			"class": "alchemist",
		},
		"echo_shot": {
			"class": "alchemist",
		},
		"charm": {
			"class": "alchemist",
		},
		"cleave": {
			"class": "alchemist",
		},
		"greater_heal": {
			"class": "alchemist",
		},
		"bomb_orb": {
			"class": "alchemist",
		},
		"chain_spark": {
			"class": "alchemist",
		},
		"mirror_shield": {
			"class": "alchemist",
		},
		"corrupt_field": {
			"class": "alchemist",
		},
		"critical_edge": {
			"class": "alchemist",
		},
		"freeze_wave": {
			"class": "alchemist",
		},
		"giant_orb": {
			"class": "alchemist",
		},
		"consume_core": {
			"class": "alchemist",
		},
		"upgrade_pulse": {
			"class": "alchemist",
		},
		"poison_rain": {
			"class": "alchemist",
		},
		"time_drift": {
			"class": "alchemist",
		},
		"contagion": {
			"class": "alchemist",
		},
		"meteor_crash": {
			"class": "alchemist",
		},
		"full_recovery": {
			"class": "alchemist",
		},
		"chaos_rain": {
			"class": "alchemist",
		},
		"overcharge": {
			"class": "alchemist",
		},
		"mass_morph": {
			"class": "alchemist",
		},
		"reflect_wall": {
			"class": "alchemist",
		},
		"giant_core": {
			"class": "alchemist",
		},
		"dot_siphon": {
			"class": "alchemist",
		},
		"final_judgment": {
			"class": "alchemist",
		},
		"apocalypse": {
			"class": "alchemist",
		},
		"time_stop": {
			"class": "alchemist",
		},
		"magic_flood": {
			"class": "alchemist",
		},
		"miracle_cascade": {
			"class": "alchemist",
		},
		"sacrifice_nova": {
			"class": "alchemist",
		},
		"one_shower": {
			"class": "alchemist",
		},
		"dot_echo": {
		"class": "alchemist",
	},
	"thunder_fang": {"class": "alchemist"},
	"tide_turner":  {"class": "alchemist"},
	"chaos_slash":  {"class": "alchemist"},
	"gatekeeper":   {"class": "alchemist"},
	"storm_surge":  {"class": "alchemist"},
	"baators_flame":{"class": "alchemist"},
	"thunder_strike":{"class": "alchemist"},
	"elbaphs_power":  {"class": "alchemist"},
	"decay":          {"class": "alchemist"},
	"regeneration":   {"class": "alchemist"},
	"weakness_brand": {"class": "alchemist"},
	"lifesteal_field":{"class": "alchemist"},
	"fortress":       {"class": "alchemist"},
	"guillotine":     {"class": "alchemist"},
	"second_wind":    {"class": "alchemist"},
	"overkill":       {"class": "alchemist"},
	}

static var sprite_map = {
	"alchemist": [
		preload("res://assets/ball_sprites/flask1.png"),
		preload("res://assets/ball_sprites/flask2.png"),
		preload("res://assets/ball_sprites/flask3.png"),
		preload("res://assets/ball_sprites/flask4.png"),
		preload("res://assets/ball_sprites/flask5.png"),
		preload("res://assets/ball_sprites/flask6.png"),
		preload("res://assets/ball_sprites/flask7.png"),
		],
	"fire": [
		preload("res://assets/ball_sprites/flame1.png"),
		preload("res://assets/ball_sprites/flame2.png"),
		preload("res://assets/ball_sprites/flame3.png"),
		preload("res://assets/ball_sprites/flame4.png"),
		preload("res://assets/ball_sprites/flame5.png"),
		preload("res://assets/ball_sprites/flame6.png"),
		preload("res://assets/ball_sprites/flame7.png"),
		]
}
static func _init_registry() -> void:
	if not functions_by_id.is_empty():
		return
	for fn in functions:
		functions_by_id[fn] = [on_shot, on_shot]

static func get_function_info(function: String):
	var parsed := _parse(function)
	return typing_by_id[parsed["kind"]]

static func get_sprite_files(function: String):
	var base = sprite_map[get_function_info(function)["class"]]
	var overlay = null
	var parsed = _parse(function)["kind"]
	if ResourceLoader.exists("res://assets/ball_sprites/%s.png" % parsed):
		overlay = load("res://assets/ball_sprites/%s.png" % parsed)
	else:
		overlay = load("res://assets/ball_sprites/oops.png")
	return {
		"base": base,
		"overlay": overlay
	}

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

static func matching_function(_source: BallBase, function: String):
	_init_registry()
	var parsed := _parse(function)
	if parsed.is_empty():
		return false
	if not functions_by_id.has(parsed["kind"]):
		return false
	if _source.rank != parsed["rank"]:
		return false
	return true


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
