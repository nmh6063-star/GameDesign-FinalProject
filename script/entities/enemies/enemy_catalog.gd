extends RefCounted
class_name EnemyCatalog

const ENEMY_SCENE := preload("res://script/entities/enemies/enemy_scene.tscn")
const IDS: Array[String] = [
	"enemy1",
	"enemy2",
]
const DATA_BY_ID := {
	IDS[0]: preload("res://data/enemies/enemy1.tres"),
	IDS[1]: preload("res://data/enemies/enemy2.tres"),
}


static func ids() -> Array[String]:
	return IDS.duplicate()


static func scene_for_id(enemy_id: String) -> PackedScene:
	return ENEMY_SCENE if DATA_BY_ID.has(enemy_id) else null


static func data_for_id(enemy_id: String) -> EnemyData:
	return DATA_BY_ID.get(enemy_id) as EnemyData
