extends ElementalRuleBase
class_name ElementalBallGambler

@export var jitter := 8.0

static var functions: Array[String] = [
	"buy_in",
	"roll_for_initiative",
	"gambling_fallacy"
]
static var functions_by_id := {
	functions[0]: [buy_in, on_merge, 1],
	functions[1]: [roll_for_initiative, can_trigger, 7],
	functions[2]: [gambling_fallacy, on_shot, -1]
}

static func get_target_function(_source: BallBase, function: String, function_match: String):
	var function_data = functions_by_id[function]
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

static func buy_in():
	print("AT LEASt thIS WORKS")
	pass

static func roll_for_initiative():
	pass

static func gambling_fallacy(_ctx: BattleContext, _source: BallBase):
	if randi_range(1, 2) == 1:
		_ctx.damage_player(_source.level)
	else:
		_ctx.damage_enemy(_source.level * 2, _ctx.active_enemy())


	
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
