extends Node2D
class_name TutorialController

# TUTORIAL ONLY — Director script for tutorial.tscn (attached to the Tutorial root node).

const TUTORIAL_COMPLETE_SCENE := "res://scenes/tutorial_complete.tscn"

const CURSOR_LEFT           := Vector2(-60, -33)
const CURSOR_RIGHT          := Vector2(202, -33)
const CURSOR_SWEEP_DURATION := 1.5

@onready var _battle_controller: TutorialBattleLoop = $BallHolder/BattleController
@onready var _cursor: AnimatedSprite2D = $AnimatedSprite2D
# $Title is the "Press H to hold balls you don't need" label added in the scene.
@onready var _title: TextEdit = $Holdhint

var _cursor_active := false
var _move_tween: Tween


func _ready() -> void:
	_battle_controller.tutorial_battle_finished.connect(_on_battle_finished)
	_battle_controller.tutorial_show_hold_hint.connect(_on_hold_hint)
	_title.visible = false
	_show_cursor()


func _on_battle_finished(result: String) -> void:
	if result != "Stage Clear":
		return
	await get_tree().create_timer(1.5).timeout
	if is_inside_tree():
		get_tree().change_scene_to_file(TUTORIAL_COMPLETE_SCENE)


func _on_hold_hint(show: bool) -> void:
	if show:
		_hide_cursor()
		_title.visible = true
	else:
		_title.visible = false
		_show_cursor()


# ── Cursor helpers ────────────────────────────────────────────────────────────

func _show_cursor() -> void:
	_cursor_active = true
	_cursor.visible = true
	_cursor.play("idle")
	_start_cursor_movement()
	_run_click_cycle()


func _hide_cursor() -> void:
	_cursor_active = false
	_cursor.visible = false
	if _move_tween:
		_move_tween.kill()
		_move_tween = null


func _start_cursor_movement() -> void:
	if _move_tween:
		_move_tween.kill()
	_move_tween = create_tween().set_loops()
	_move_tween.tween_property(_cursor, "position", CURSOR_RIGHT, CURSOR_SWEEP_DURATION) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_move_tween.tween_property(_cursor, "position", CURSOR_LEFT, CURSOR_SWEEP_DURATION) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


# Plays the "click" animation every 2! s while the cursor is active.
func _run_click_cycle() -> void:
	while is_inside_tree() and _cursor_active:
		await get_tree().create_timer(2.0).timeout
		if not is_inside_tree() or not _cursor_active:
			return
		_cursor.play("click")
		await _cursor.animation_finished
		if not is_inside_tree() or not _cursor_active:
			return
		_cursor.play("idle")
