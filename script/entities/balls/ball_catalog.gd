extends RefCounted
class_name BallCatalog

const NORMAL_BALL_ID := "ball_normal"
const MAX_SPECIAL_SLOTS := 4
const ELEMENTAL_BALL_SCENE := preload("res://script/entities/balls/elemental_balls/elemental_ball_scene.tscn")
const MODIFIER_BALL_SCENE := preload("res://script/entities/balls/modifier_balls/modifier_ball_scene.tscn")
const IDS: Array[String] = [
	"ball_amplifier",
	"ball_bomb",
	"ball_duplication",
	"ball_heal",
	"ball_magnet",
	"ball_multiplication",
	NORMAL_BALL_ID,
]
const DATA_BY_ID := {
	IDS[0]: preload("res://data/balls/amplifier_ball.tres"),
	IDS[1]: preload("res://data/balls/bomb_ball.tres"),
	IDS[2]: preload("res://data/balls/duplication_ball.tres"),
	IDS[3]: preload("res://data/balls/heal_ball.tres"),
	IDS[4]: preload("res://data/balls/magnet_ball.tres"),
	IDS[5]: preload("res://data/balls/multiplication_ball.tres"),
	IDS[6]: preload("res://data/balls/normal_ball.tres"),
}


static func ids(include_normal: bool = true) -> Array[String]:
	var out: Array[String] = []
	for ball_id in IDS:
		if include_normal or ball_id != NORMAL_BALL_ID:
			out.append(ball_id)
	return out


static func is_special(ball_id: String) -> bool:
	return ball_id != NORMAL_BALL_ID


static func special_cost(ball_id: String) -> int:
	return 1


static func scene_for_id(ball_id: String) -> PackedScene:
	var data := data_for_id(ball_id)
	if data == null:
		return null
	return ELEMENTAL_BALL_SCENE if data.is_elemental() else MODIFIER_BALL_SCENE


static func data_for_id(ball_id: String) -> BallData:
	return DATA_BY_ID.get(ball_id) as BallData
