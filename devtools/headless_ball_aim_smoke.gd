extends SceneTree
## Run from project root:
##   godot --path . --headless -s res://devtools/headless_ball_aim_smoke.gd
## Verifies aim-phase collision mask reset (no wall physics while aiming).

const BallBase := preload("res://script/entities/balls/ball_base.gd")
const BallCatalog := preload("res://script/entities/balls/ball_catalog.gd")
const BattleContext := preload("res://script/battle/core/battle_context.gd")


func _init() -> void:
	var code := _run()
	quit(code)


func _run() -> int:
	var holder := Node2D.new()
	root.add_child(holder)
	var aim := Node2D.new()
	holder.add_child(aim)
	var ctx := BattleContext.new(null)
	var data := BallCatalog.data_for_id(BallCatalog.NORMAL_BALL_ID)
	if data == null:
		push_error("headless_ball_aim_smoke: no normal ball data")
		return 1
	var pkg := load("res://scenes/ball.tscn") as PackedScene
	var ball := pkg.instantiate() as BallBase
	if ball == null:
		push_error("headless_ball_aim_smoke: ball scene")
		return 1
	holder.add_child(ball)
	ball.visible = true
	var test_mask := 5
	ball.collision_mask = test_mask
	ball.set_collision_enabled(true)
	ball.configure(data, 1, ctx, aim)
	ball.set_playfield_x_bounds(-500.0, 500.0)
	ball.set_playfield_state(true)
	if ball.collision_mask != 0:
		push_error("headless_ball_aim_smoke: aim expected collision_mask 0, got %d" % ball.collision_mask)
		return 2
	if not ball.lock_rotation:
		push_error("headless_ball_aim_smoke: aim expected lock_rotation")
		return 3
	ball.set_playfield_state(false)
	if ball.collision_mask != test_mask:
		push_error("headless_ball_aim_smoke: play expected collision_mask %d, got %d" % [test_mask, ball.collision_mask])
		return 4
	if ball.lock_rotation:
		push_error("headless_ball_aim_smoke: play expected lock_rotation off")
		return 5
	print("headless_ball_aim_smoke: OK")
	return 0
