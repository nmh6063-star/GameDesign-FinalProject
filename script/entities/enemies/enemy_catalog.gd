extends RefCounted
class_name EnemyCatalog

const ENEMY_SCENE := preload("res://script/entities/enemies/enemy_scene.tscn")
const IDS: Array[String] = [
	"enemy1",
	"enemy2",
	"enemy_tutorial",  # TUTORIAL ONLY: used exclusively in tutorial.tscn
	"enemy_chicken",
	"enemy_stone_thrower",
	"enemy_fire",
	"enemy_ice",
	"enemy_spider_queen",
	"enemy_small_spider",
	"enemy_knight",
	"enemy_guard",
	"enemy_small_soldier",
	"enemy_mage",
	"enemy_machine_core",
	"enemy_playground",
	"enemy1-tutorial",
]
const DATA_BY_ID := {
	IDS[0]: preload("res://data/enemies/enemy1.tres"),
	IDS[1]: preload("res://data/enemies/enemy2.tres"),
	IDS[2]: preload("res://data/enemies/enemy_tutorial.tres"),  # TUTORIAL ONLY
	IDS[3]: preload("res://data/enemies/enemy_chicken.tres"),
	IDS[4]: preload("res://data/enemies/enemy_stone_thrower.tres"),
	IDS[5]: preload("res://data/enemies/enemy_fire.tres"),
	IDS[6]: preload("res://data/enemies/enemy_ice.tres"),
	IDS[7]: preload("res://data/enemies/enemy_spider_queen.tres"),
	IDS[8]: preload("res://data/enemies/enemy_small_spider.tres"),
	IDS[9]: preload("res://data/enemies/enemy_knight.tres"),
	IDS[10]: preload("res://data/enemies/enemy_guard.tres"),
	IDS[11]: preload("res://data/enemies/enemy_small_soldier.tres"),
	IDS[12]: preload("res://data/enemies/enemy_mage.tres"),
	IDS[13]: preload("res://data/enemies/enemy_machine_core.tres"),
	IDS[14]: preload("res://data/enemies/enemy_playground.tres"),
	IDS[15]: preload("res://data/enemies/enemy1-tutorial.tres"),
}


static func ids() -> Array[String]:
	return IDS.duplicate()


static func scene_for_id(enemy_id: String) -> PackedScene:
	return ENEMY_SCENE if DATA_BY_ID.has(enemy_id) else null


static func data_for_id(enemy_id: String) -> EnemyData:
	return DATA_BY_ID.get(enemy_id) as EnemyData
