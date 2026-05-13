extends BattleLoop
class_name TutorialBattleLoop

signal first_ball_dropped
signal first_merge_done
signal first_pip_filled
signal mana_depleted
signal battle_finished
signal topped_out

var _drops := 0
var _merge_announced := false
var _pip_announced := false
var _pip_depleted_announced := false
var _pip_cap = 0


func _override_enemy_ids_from_stage() -> void:
	pass


func _on_ball_dropped() -> void:
	super._on_ball_dropped()
	_drops += 1
	if _drops == 1:
		first_ball_dropped.emit()


func sync_mana_hud() -> void:
	super.sync_mana_hud()
	if not _merge_announced and _context.combo >= 1:
		_merge_announced = true
		first_merge_done.emit()
	if not _pip_announced and _context.mana_pipes >= 1:
		_pip_announced = true
		first_pip_filled.emit()
	if _pip_announced and not _pip_depleted_announced and _context.mana_pipes < _pip_cap:
		_pip_depleted_announced = true
		mana_depleted.emit()
	_pip_cap = _context.mana_pipes

func _topout():
	super._topout()
	if get_node_or_null("/root/TOPOUT"):
		topped_out.emit()


func _finish_battle(text: String) -> void:
	if _context.has_battle_result():
		return
	if _context.slow_mo_active:
		_exit_slow_mo()
	_context.finish_battle(text)
	_context.phase = BattleContext.Phase.RESOLVE
	_context.lock_resolution()
	_clear_current_ball()
	_target.visible = false
	set_physics_process(false)
	_hud.show_result(text)
	if text == "Stage Clear":
		await get_tree().create_timer(1.1).timeout
		if is_inside_tree():
			battle_finished.emit()
