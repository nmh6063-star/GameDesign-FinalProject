extends ElementalRuleBase
class_name ElementalBallDark

@export var jitter := 8.0

static var functions: Array[String] = [
	"health_for_damage",
	"deploy_enchantment", #this one seems like hell to even touch. Will not be touching for now
	"slow_time", #holding off bc is a HEAVY interference
	"care_drop",
	"enbiggen", #damage multiplier not in yet
	"eye_for_an_arm",
	"create_copy",
	"darkness_consume"
]
static var functions_by_id := {
	functions[0]: [health_for_damage, on_shot, 1],
	functions[1]: [deploy_enchantment, can_trigger, 2],
	functions[2]: [slow_time, can_trigger, 3],
	functions[3]: [care_drop, on_merge, 4],
	functions[4]: [enbiggen, can_trigger, 5],
	functions[5]: [eye_for_an_arm, on_merge, 6],
	functions[6]: [create_copy, can_trigger, 7],
	functions[7]: [darkness_consume, on_shot, -1]
}

static func get_target_function(_source: BallBase, function: String, function_match: String):
	var function_data = functions_by_id[function]
	#print("CONDITIONS:")
	#print(_source.rank)
	#print(function_data[2])
	return function_data[1].get_method() == function_match and (_source.rank == function_data[2] || function_data[2] == -1)

static func can_trigger(_ctx: BattleContext, _source: BallBase, function: String) -> bool:
	functions_by_id[function][0].call(_ctx, _source)
	return false

static func apply(_ctx: BattleContext, _source: BallBase, function: String) -> void:
	functions_by_id[function][0].call(_ctx, _source)
	#push_error("BallEffectBase.apply() must be implemented")

static func on_shot(_ctx: BattleContext, _source: BallBase, function: String) -> void:
	functions_by_id[function][0].call(_ctx, _source)

static func on_merge(_ctx: BattleContext, _source: BallBase, function: String) -> void:
	functions_by_id[function][0].call(_ctx, _source)
	
static func deploy_enchantment(_ctx: BattleContext, _source: BallBase):
	pass

## Poison Apple: grant 3 charges of +10% damage that also cost 2 self-HP each.
## (UI: color the next 3 mana-ball slots black while charges remain.)
static func health_for_damage(_ctx: BattleContext, _source: BallBase):
	_ctx.player_statuses["poison_apple_charges"] = \
			int(_ctx.player_statuses.get("poison_apple_charges", 0)) + 3

static func slow_time(_ctx: BattleContext, _source: BallBase):
	pass

static func care_drop(_ctx: BattleContext, _source: BallBase):
	for i in range(5):
		_ctx.spawn_ball("ball_normal", Vector2(_source.global_position.x, -83), Vector2.ZERO, randi_range(1, 2))

static func enbiggen(_ctx: BattleContext, _source: BallBase):
	_source.data.merge_growth = 8
	pass
	
static func eye_for_an_arm(_ctx: BattleContext, _source: BallBase):
	_ctx.damage_enemy(_source.rank * 1.5, _ctx.active_enemy())
	_ctx.damage_player(_source.rank / 2)

## Clone: spawn a rank-7 ball copy, double all direct damage this battle,
## and permanently reduce max HP by 5%. Stacks up to 4 additional times.
static func create_copy(_ctx: BattleContext, _source: BallBase):
	var current_stacks := int(_ctx.player_statuses.get("clone_stacks", 0))
	if current_stacks >= 4:
		return
	_source.rank = 7
	var ball := _ctx.spawn_ball("ball_normal", _source.global_position, Vector2.ZERO, 7) as BallBase
	if ball != null:
		ball.rank = 7
	_ctx.player_statuses["clone_stacks"] = current_stacks + 1
	# Permanently reduce max HP by 5%
	var new_max := int(round(PlayerState.player_max_health * 0.95))
	PlayerState.player_max_health = new_max
	if PlayerState.player_health > new_max:
		PlayerState.player_health = new_max

## Passive: every shot deals ×1.5 damage but also hurts the player.
static func darkness_consume(_ctx: BattleContext, _source: BallBase):
	_ctx.damage_enemy(int(round(_source.rank * 3 * 1.5)), _ctx.active_enemy())
	_ctx._damage_player_raw(_source.rank)



	
#Match the function to the type

"""

func can_trigger(_ctx: BattleContext, _source: BallBase) -> bool:
	return true


func apply(_ctx: BattleContext, _source: BallBase) -> void:
	push_error("BallEffectBase.apply() must be implemented")


func tick(_ctx: BattleContext, _source: BallBase) -> void:
	pass


func shot_multiplier(_source: BallBase) -> float:
	return 1.0


func on_merge(_ctx: BattleContext, _source: BallBase, _other: BallBase) -> void:
	pass


func on_shot(_ctx: BattleContext, _source: BallBase) -> void:
	pass


func on_destroy(_ctx: BattleContext, _source: BallBase) -> void:
	pass
	"""
