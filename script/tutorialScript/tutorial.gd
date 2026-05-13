extends Node2D
class_name TutorialController

const CURSOR_START          := Vector2(584, -42)
const CURSOR_END            := Vector2(-71, -42)
const CURSOR_SWEEP_DURATION := 2

const ATTACK_CURSOR_START   := Vector2(-72, 236)
const ATTACK_CURSOR_END     := Vector2(543, 236)

@onready var _cursor: AnimatedSprite2D          = $Mouse
@onready var _mouse_for_attack: AnimatedSprite2D = $MouseForAttack
@onready var _battle_controller: TutorialBattleLoop = $BallHolder/BattleController

var _cursor_active := false
var _move_tween: Tween
var _click_pending := false
var _tip_queue: Array[String] = []
var _tip_running := false
var _pending_attack_cursor := false
var _attack_phase_active := false
var _hold_x_canvas: CanvasLayer = null
var _hold_x_label: Label = null
var toppedout = false
var stop_shoot = false
var final_tip = false

signal _dismissed


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for child in get_children():
		child.process_mode = Node.PROCESS_MODE_PAUSABLE
	_mouse_for_attack.visible = false
	_battle_controller.first_ball_dropped.connect(_on_first_ball_dropped)
	_battle_controller.first_merge_done.connect(_on_first_merge)
	_battle_controller.first_pip_filled.connect(_on_first_pip)
	_battle_controller.mana_depleted.connect(_on_mana_depleted)
	_battle_controller.topped_out.connect(_on_toppedout)
	_battle_controller.battle_finished.connect(_on_battle_finished)
	_show_cursor()


func _input(event: InputEvent) -> void:
	if _click_pending and event is InputEventMouseButton and event.pressed:
		get_viewport().set_input_as_handled()
		_click_pending = false
		_dismissed.emit()


func _process(_delta: float) -> void:
	if not _attack_phase_active:
		return
	var holding = _battle_controller._context.slow_mo_active
	_mouse_for_attack.visible = holding
	if _hold_x_label:
		_hold_x_label.visible = not holding
	if stop_shoot and _battle_controller._context.slow_mo_active:
		Input.action_press("drop")


# ── Tip triggers ─────────────────────────────────────────────────────────────

func _on_first_ball_dropped() -> void:
	await get_tree().create_timer(1.0).timeout
	_hide_cursor()
	_enqueue_tip("Try merging balls with the same rank")
	#_enqueue_tip("1234567890123456789012345678901234567890123456789012345678901234567890")


func _on_first_merge() -> void:
	await get_tree().create_timer(0.3).timeout
	_enqueue_tip("Great merge! \n Maintaining combos of 10 gives you 1 mana pipe")
	_enqueue_tip("Combos are made by doing \nmultiple merges within a given time frame. \nStack merges to build combos!")
	_enqueue_tip("Merges follow the order on the right. \nGoing from ranks 1-7 to the color white. \nTry building a combo of 10 now!")


func _on_first_pip() -> void:
	await get_tree().create_timer(0.3).timeout
	_pending_attack_cursor = true
	_enqueue_tip("Mana pipe filled! \nPress X to enter aim mode, \nthen click a ball to spend a pipe and shoot it.")


func _on_mana_depleted() -> void:
	if !stop_shoot:
		stop_shoot = true
		_attack_phase_active = false
		_mouse_for_attack.visible = false
		if _hold_x_canvas:
			_hold_x_canvas.queue_free()
			_hold_x_canvas = null
			_hold_x_label = null
		_force_topout()

func _force_topout():
	await get_tree().create_timer(1.0).timeout
	_enqueue_tip("Nice Shot! \nBeware of topouts! \nTopouts occur when you try to drop a ball \nwhile overlapping another ball. \n To demonstrate, try dropping a ball \non top of the filled board...")

func spawn_set():
	await get_tree().create_timer(0.5).timeout
	var new_node := Node2D.new()
	new_node.name = "TOPOUT"
	Engine.get_main_loop().root.add_child(new_node)
	for i in range(15):
		_battle_controller._context.drop_ball_in_box("ball_normal", 7)

func _on_toppedout():
	await get_tree().create_timer(1.0).timeout
	toppedout = true
	_enqueue_tip("Topouts deal damange, clear your board, \nand take away a mana pipe! \nMake sure to avoid topping out if you can!")
	_enqueue_tip("Throughout your run you will find \nvarious different ball types. \nThe higher the rank of the ball, \nthe more powerful the abilities. \nTry out different combinations as you play \nto find the best way to win!")


func _on_battle_finished() -> void:
	await get_tree().create_timer(0.5).timeout
	for child in get_tree().root.get_children():
		if child.name.contains("player"):
			child.queue_free()
	get_node("/root/TOPOUT").queue_free()
	get_tree().change_scene_to_file("res://scenes/menu_screen.tscn")


func _enqueue_tip(text: String) -> void:
	_tip_queue.append(text)
	if not _tip_running:
		_drain_queue()


func _drain_queue() -> void:
	_tip_running = true
	while not _tip_queue.is_empty():
		await _show_tip(_tip_queue.pop_front())
	_tip_running = false
	if _pending_attack_cursor:
		_pending_attack_cursor = false
		_start_attack_phase()


# ── Overlay ───────────────────────────────────────────────────────────────────

func _show_tip(text: String) -> void:
	get_tree().paused = true

	var sw := get_viewport().get_visible_rect().size.x
	var sh := get_viewport().get_visible_rect().size.y

	var canvas := CanvasLayer.new()
	canvas.layer = 20
	canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(canvas)

	_add_dark_rect(canvas, 0, 0, sw, sh)

	var body := Label.new()
	body.position = Vector2(650, 300)
	body.text     = ""
	canvas.add_child(body)

	var hint_canvas := CanvasLayer.new()
	hint_canvas.layer = 21
	hint_canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(hint_canvas)

	var hint := Label.new()
	hint.text     = "Click to continue"
	hint.position = Vector2(500, 600)
	hint.visible  = false
	hint_canvas.add_child(hint)

	for ch in text:
		body.text += ch
		await get_tree().create_timer(0.04, true).timeout
		if not is_inside_tree():
			_cleanup_tip(canvas, hint_canvas)
			return

	await get_tree().create_timer(2.0, true).timeout
	if not is_inside_tree():
		_cleanup_tip(canvas, hint_canvas)
		return

	hint.visible   = true
	_click_pending = true
	await _dismissed

	_cleanup_tip(canvas, hint_canvas)


func _cleanup_tip(canvas: CanvasLayer, hint_canvas: CanvasLayer) -> void:
	canvas.queue_free()
	hint_canvas.queue_free()
	get_tree().paused = false
	if stop_shoot and !toppedout:
		spawn_set()
	elif toppedout and !final_tip:
		final_tip = true
	elif final_tip:
		_on_battle_finished()


func _add_dark_rect(parent: Node, x: float, y: float, w: float, h: float) -> void:
	if w <= 0.0 or h <= 0.0:
		return
	var r := ColorRect.new()
	r.position     = Vector2(x, y)
	r.size         = Vector2(w, h)
	r.color        = Color(0, 0, 0, 0.75)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(r)


# ── Attack cursor ─────────────────────────────────────────────────────────────

func _start_attack_phase() -> void:
	_hold_x_canvas = CanvasLayer.new()
	_hold_x_canvas.layer = 10
	_hold_x_canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_hold_x_canvas)
	_hold_x_label = Label.new()
	_hold_x_label.text = "Press X"
	_hold_x_label.position = Vector2(650, 300)
	_hold_x_canvas.add_child(_hold_x_label)
	_mouse_for_attack.position = ATTACK_CURSOR_START
	_mouse_for_attack.visible = false
	_mouse_for_attack.play("idle")
	var t := create_tween().set_loops()
	t.tween_property(_mouse_for_attack, "position", ATTACK_CURSOR_END, CURSOR_SWEEP_DURATION) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(_mouse_for_attack, "position", ATTACK_CURSOR_START, CURSOR_SWEEP_DURATION) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_attack_phase_active = true
	_run_attack_click_cycle()


func _run_attack_click_cycle() -> void:
	while is_inside_tree() and _attack_phase_active:
		await get_tree().create_timer(1.0).timeout
		if not is_inside_tree() or not _attack_phase_active:
			return
		if _mouse_for_attack.visible:
			_mouse_for_attack.play("click")
			await _mouse_for_attack.animation_finished
			if not is_inside_tree() or not _attack_phase_active:
				return
			_mouse_for_attack.play("idle")


# ── Drop cursor ───────────────────────────────────────────────────────────────

func _show_cursor() -> void:
	_cursor_active = true
	_cursor.position = CURSOR_START
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
	_move_tween.tween_property(_cursor, "position", CURSOR_END, CURSOR_SWEEP_DURATION) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_move_tween.tween_property(_cursor, "position", CURSOR_START, CURSOR_SWEEP_DURATION) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _run_click_cycle() -> void:
	while is_inside_tree() and _cursor_active:
		await get_tree().create_timer(1.0).timeout
		if not is_inside_tree() or not _cursor_active:
			return
		_cursor.play("click")
		await _cursor.animation_finished
		if not is_inside_tree() or not _cursor_active:
			return
		_cursor.play("idle")
