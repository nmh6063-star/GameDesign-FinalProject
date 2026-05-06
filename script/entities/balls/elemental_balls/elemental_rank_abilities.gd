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
]

static var functions_by_id := {}

static var typing_by_id = {
		"strike": {
			"class": "fire",
		},
		"mend": {
			"class": "fire",
		},
		"venom": {
			"class": "alchemist",
		},
		"ember": {
			"class": "alchemist",
		},
		"guard": {
			"class": "fire",
		},
		"critical": {
			"class": "fire",
		},
		"refresh": {
			"class": "alchemist",
		},
		"heavy_strike": {
			"class": "fire",
		},
		"recovery": {
			"class": "alchemist",
		},
		"frost_touch": {
			"class": "alchemist",
		},
		"iron_guard": {
			"class": "fire",
		},
		"triple_shot": {
			"class": "fire",
		},
		"scatter_drop": {
			"class": "alchemist",
		},
		"critical_strike": {
			"class": "fire",
		},
		"pollution": {
			"class": "alchemist",
		},
		"fireburn": {
			"class": "fire",
		},
		"power_slash": {
			"class": "fire",
		},
		"toxic_burst": {
			"class": "alchemist",
		},
		"fireball": {
			"class": "fire",
		},
	"ice_shield": {
		"class": "ice",
		"ability": "block"
	},
	"convert": {
		"class": "gambler",
		"ability": "misc"
	},
	"reinforce": {
			"class": "knight",
			"ability": "block_plus"
		},
		"echo_shot": {
			"class": "alchemist",
		},
		"charm": {
			"class": "alchemist",
		},
		"cleave": {
			"class": "fire",
		},
		"greater_heal": {
			"class": "alchemist",
		},
		"bomb_orb": {
			"class": "fire",
		},
		"chain_spark": {
			"class": "fire",
		},
		"mirror_shield": {
			"class": "alchemist",
		},
		"corrupt_field": {
			"class": "alchemist",
		},
		"critical_edge": {
			"class": "fire",
		},
		"freeze_wave": {
			"class": "alchemist",
		},
		"giant_orb": {
			"class": "fire",
		},
		"consume_core": {
			"class": "alchemist",
		},
		"upgrade_pulse": {
			"class": "fire",
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
			"class": "fire",
		},
		"full_recovery": {
			"class": "fire",
		},
		"chaos_rain": {
			"class": "fire",
		},
		"overcharge": {
			"class": "fire",
		},
		"mass_morph": {
			"class": "alchemist",
		},
		"reflect_wall": {
			"class": "alchemist",
		},
		"giant_core": {
			"class": "fire",
		},
		"dot_siphon": {
			"class": "alchemist",
		},
		"final_judgment": {
			"class": "fire",
		},
		"apocalypse": {
			"class": "fire",
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
			"class": "fire",
		},
		"one_shower": {
			"class": "fire",
		},
		"dot_echo": {
			"class": "alchemist",
		},
		"convert": {
			"class": "alchemist"
		}
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
	if FileAccess.file_exists("res://assets/ball_sprites/%s.png" % parsed):
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
