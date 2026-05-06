extends EnemyActionBase
class_name FogBoardAction

const FogBoard := preload("res://scenes/visual_effects/FogBoard.tscn")
const _ICON := preload("res://assets/enemies/attack_icon/fog icon no back.png")


func execute(_ctx: BattleContext, enemy: EnemyBase) -> void:
	var fog := FogBoard.instantiate()
	enemy.add_sibling(fog)


func action_name() -> String:
	return "Fog Board"


func icon_texture() -> Texture2D:
	return _ICON


func damage_amount(_enemy: EnemyBase) -> int:
	return 0


func special_effect() -> String:
	return "Covers the board in fog"
