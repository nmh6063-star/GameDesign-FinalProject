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

static func health_for_damage(_ctx: BattleContext, _source: BallBase):
	_ctx.damage_enemy(_source.level * 3, _ctx.active_enemy())
	#print("SHOT SUCCESS")
	#_ctx.consume_ball(_source)
	pass

static func slow_time(_ctx: BattleContext, _source: BallBase):
	pass

static func care_drop(_ctx: BattleContext, _source: BallBase):
	for i in range(5):
		_ctx.spawn_ball("ball_normal", Vector2(_source.global_position.x, -83), Vector2.ZERO, randi_range(1, 2))

static func enbiggen(_ctx: BattleContext, _source: BallBase):
	_source.data.merge_growth = 8
	pass
	
static func eye_for_an_arm(_ctx: BattleContext, _source: BallBase):
	_ctx.damage_enemy(_source.level*1.5, _ctx.active_enemy())
	_ctx.damage_player(_source.level/2)

static func create_copy(_ctx: BattleContext, _source: BallBase):
	_source.rank = 8
	var ball = _ctx.spawn_ball("ball_normal", _source.global_position, Vector2.ZERO, _source.level) as BallBase
	ball.rank = 8
	#_ctx.consume_ball(_source)
	pass

static func darkness_consume(_ctx: BattleContext, _source: BallBase):
	_ctx.damage_enemy(_source.level * 3, _ctx.active_enemy())
	_ctx.damage_player(_source.level)



	
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
