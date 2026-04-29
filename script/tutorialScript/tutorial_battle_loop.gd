extends BattleLoop
class_name TutorialBattleLoop

# TUTORIAL ONLY — Subclass of BattleLoop used exclusively in tutorial.tscn.
# Do not reference this class from any non-tutorial scene or script.

const TutorialBallManager := preload("res://script/tutorialScript/tutorial_ball_manager.gd")

# Consumed by tutorial.gd for the scene transition on win.
signal tutorial_battle_finished(result_text: String)
# Consumed by tutorial.gd to show/hide the "Press H" hint and the cursor.
signal tutorial_show_hold_hint(show: bool)

const TUTORIAL_BALL_SEQUENCE := [
	{"id": "ball_normal", "rank": 4},
	{"id": "ball_normal", "rank": 4},
	{"id": "ball_normal", "rank": 4},
	{"id": "ball_normal", "rank": 4},
	{"id": "ball_normal", "rank": 1},
	{"id": "ball_normal", "rank": 7},
	{"id": "ball_normal", "rank": 7},
	{"id": "ball_normal", "rank": 7},
	{"id": "ball_normal", "rank": 7},
	{"id": "ball_normal", "rank": 7},
]

# MERGES_PER_MANA_PIPE is 5. Starting at 2 means the 3rd merge (8+8→16) tips
# progress to 5 and awards exactly 1 ammo.
const TUTORIAL_INITIAL_MERGE_PROGRESS := 2

# True while the rank-1 ball is in the placeholder; blocks drop and shoot input.
var _drop_blocked := false
# Ensures the hold-hint is only triggered once even if the sequence loops.
var _hold_hint_shown := false


func _begin_stage() -> void:
	_context.clear_battle_result()
	var tutorial_box := TutorialBallManager.new(
		_root, _ball_placeholder, _context, _target,
		_on_ball_dropped, BattleLoadout.queue_ball_pool_ids()
	)
	tutorial_box.apply_fixed_sequence(TUTORIAL_BALL_SEQUENCE)
	_box = tutorial_box
	_spawn_enemies()
	# Pre-damage the first enemy to 16/100 HP without triggering damage floaters.
	if not _enemy_slots.is_empty():
		var first := _enemy_slots[0] as EnemySlotController
		if first != null and first.enemy != null:
			first.enemy.current_health = 16
	_target.z_index = 999
	_hud.clear_result()
	track_ball(null)
	_sync_player_bar()
	_context.merge_progress = clampi(
		TUTORIAL_INITIAL_MERGE_PROGRESS, 0, BattleContext.MERGES_PER_MANA_PIPE - 1
	)
	sync_mana_hud()
	_sync_special_bar()
	set_physics_process(true)
	_begin_turn()


func ensure_ball_in_play() -> void:
	super.ensure_ball_in_play()
	# After the base spawns the ball, check if it is the rank-1 hold-hint ball.
	# Only trigger once per run (_hold_hint_shown guards against sequence repeats).
	var ball := _context.current_ball as BallBase
	if not _hold_hint_shown and is_instance_valid(ball) and ball.rank == 1:
		_hold_hint_shown = true
		_drop_blocked = true
		# Disable the ball's physics process so Input.is_action_just_pressed("drop")
		# inside ball_base._physics_process never fires while the hint is active.
		ball.set_physics_process(false)
		tutorial_show_hold_hint.emit(true)


func _handle_shoot_input() -> void:
	# Block all click / slow-mo input while the player must press H instead.
	if _drop_blocked:
		return
	super._handle_shoot_input()


func _handle_hold_input() -> void:
	if not _drop_blocked:
		super._handle_hold_input()
		return
	# Only accept the hold action (H key) while drop is blocked.
	if _context.phase != BattleContext.Phase.PLAY or _context.slow_mo_active:
		return
	if not Input.is_action_just_pressed(HOLD_ACTION):
		return
	if _box == null or not is_instance_valid(_context.current_ball):
		return
	# Re-enable physics before hold_swap so the ball can be reconfigured by it.
	_context.current_ball.set_physics_process(true)
	if _box.hold_swap(_context.current_ball):
		_drop_blocked = false
		tutorial_show_hold_hint.emit(false)
		track_ball(_context.current_ball)


func _should_show_post_battle_reward() -> bool:
	return false


func _finish_battle(text: String) -> void:
	if _context.has_battle_result():
		return
	super._finish_battle(text)
	tutorial_battle_finished.emit(text)
