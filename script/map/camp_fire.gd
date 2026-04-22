extends CanvasLayer
class_name CampFireController


func _ready() -> void:
	$Heal2.pressed.connect(_on_heal_pressed)
	$UpgradeAimSize.pressed.connect(_on_upgrade_aim_pressed)


func _process(_delta: float) -> void:
	$Heal2/Upgrade2.position.y = 80.0 + sin(Time.get_ticks_msec() * 0.003) * 6.0


func _on_heal_pressed() -> void:
	PlayerState.player_health = PlayerState.player_max_health
	GameManager.complete_current_room()


func _on_upgrade_aim_pressed() -> void:
	PlayerState.aim_size_level += 1
	GameManager.complete_current_room()
