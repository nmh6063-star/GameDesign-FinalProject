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
			"class": "knight",
			"ability": "hit"
		},
		"mend": {
			"class": "knight",
			"ability": "heal"
		},
		"venom": {
			"class": "poison",
			"ability": "dot"
		},
		"ember": {
			"class": "fire",
			"ability": "dot"
		},
		"guard": {
			"class": "knight",
			"ability": "block"
		},
		"critical": {
			"class": "knight",
			"ability": "crit"
		},
		"refresh": {
			"class": "knight",
			"ability": "misc"
		},
		"heavy_strike": {
			"class": "knight",
			"ability": "hit"
		},
		"recovery": {
			"class": "knight",
			"ability": "heal"
		},
		"frost_touch": {
			"class": "ice",
			"ability": "misc"
		},
		"iron_guard": {
			"class": "knight",
			"ability": "block_plus"
		},
		"triple_shot": {
			"class": "gambler",
			"ability": "hit"
		},
		"scatter_drop": {
			"class": "gambler",
			"ability": "misc"
		},
		"critical_strike": {
			"class": "gambler",
			"ability": "crit"
		},
		"pollution": {
			"class": "poison",
			"ability": "crit"
		},
		"fireburn": {
			"class": "fire",
			"ability": "dot"
		},
		"power_slash": {
			"class": "knight",
			"ability": "hit"
		},
		"toxic_burst": {
			"class": "poison",
			"ability": "bomb"
		},
		"fireball": {
			"class": "fire",
			"ability": "dot"
		},
		"ice_lance": {
			"class": "ice",
			"ability": "dot"
		},
		"reinforce": {
			"class": "knight",
			"ability": "block_plus"
		},
		"echo_shot": {
			"class": "knight",
			"ability": "misc"
		},
		"charm": {
			"class": "gambler",
			"ability": "misc"
		},
		"cleave": {
			"class": "knight",
			"ability": "hit"
		},
		"greater_heal": {
			"class": "knight",
			"ability": "heal"
		},
		"bomb_orb": {
			"class": "knight",
			"ability": "bomb"
		},
		"chain_spark": {
			"class": "gambler",
			"ability": "hit"
		},
		"mirror_shield": {
			"class": "gambler",
			"ability": "misc"
		},
		"corrupt_field": {
			"class": "poison",
			"ability": "misc"
		},
		"critical_edge": {
			"class": "gambler",
			"ability": "crit"
		},
		"freeze_wave": {
			"class": "ice",
			"ability": "block"
		},
		"giant_orb": {
			"class": "gambler",
			"ability": "misc"
		},
		"consume_core": {
			"class": "gambler",
			"ability": "crit"
		},
		"upgrade_pulse": {
			"class": "gambler",
			"ability": "misc"
		},
		"poison_rain": {
			"class": "poison",
			"ability": "dot"
		},
		"time_drift": {
			"class": "gambler",
			"ability": "misc"
		},
		"contagion": {
			"class": "poison",
			"ability": "misc"
		},
		"meteor_crash": {
			"class": "gambler",
			"ability": "crit"
		},
		"full_recovery": {
			"class": "knight",
			"ability": "heal"
		},
		"chaos_rain": {
			"class": "gambler",
			"ability": "misc"
		},
		"overcharge": {
			"class": "knight",
			"ability": "crit"
		},
		"mass_morph": {
			"class": "gambler",
			"ability": "misc"
		},
		"reflect_wall": {
			"class": "gambler",
			"ability": "misc"
		},
		"giant_core": {
			"class": "gambler",
			"ability": "misc"
		},
		"dot_siphon": {
			"class": "knight",
			"ability": "heal"
		},
		"final_judgment": {
			"class": "knight",
			"ability": "crit"
		},
		"apocalypse": {
			"class": "knight",
			"ability": "crit"
		},
		"time_stop": {
			"class": "ice",
			"ability": "misc"
		},
		"magic_flood": {
			"class": "gambler",
			"ability": "misc"
		},
		"miracle_cascade": {
			"class": "gambler",
			"ability": "misc"
		},
		"sacrifice_nova": {
			"class": "poison",
			"ability": "crit"
		},
		"one_shower": {
			"class": "gambler",
			"ability": "misc"
		},
		"dot_echo": {
			"class": "fire",
			"ability": "dot"
		},
	}

static var sprite_map = {
	"block": preload("res://assets/ball_sprites/block.png"),
	"block_plus": preload("res://assets/ball_sprites/block_plus.png"),
	"bomb": preload("res://assets/ball_sprites/bomb.png"),
	"crit": preload("res://assets/ball_sprites/crit.png"),
	"dot": preload("res://assets/ball_sprites/dot.png"),
	"fire": preload("res://assets/ball_sprites/fire.png"),
	"gambler": preload("res://assets/ball_sprites/gambler.png"),
	"heal": preload("res://assets/ball_sprites/heal.png"),
	"hit": preload("res://assets/ball_sprites/hit.png"),
	"ice": preload("res://assets/ball_sprites/ice.png"),
	"knight": preload("res://assets/ball_sprites/knight.png"),
	"misc": preload("res://assets/ball_sprites/misc.png"),
	"poison": preload("res://assets/ball_sprites/skull.png")
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
	var overlay = sprite_map[get_function_info(function)["ability"]]
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
