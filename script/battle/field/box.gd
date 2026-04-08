extends RefCounted
class_name BattleBox

const GameBall := preload("res://script/ball/game_ball.gd")
const BallData := preload("res://script/ball/ball_data.gd")

var _root: Node2D
var _template_ball: GameBall
var _state
var _target: Node2D
var _on_ball_dropped: Callable
var _spawn_pool: Array[BallData] = []


func _init(root: Node2D, template_ball: GameBall, state, target: Node2D, on_ball_dropped: Callable, content_dir: String) -> void:
	_root = root
	_template_ball = template_ball
	_state = state
	_target = target
	_on_ball_dropped = on_ball_dropped
	_spawn_pool = _load_ball_pool(content_dir)
	assert(not _spawn_pool.is_empty(), "No ball content found in %s" % content_dir)
	_template_ball.set_runtime(_state, _target)
	_template_ball.set_collision_enabled(false)


func active() -> Array:
	var out: Array = []
	for node in _root.get_tree().get_nodes_in_group("ball"):
		if not node is GameBall:
			continue
		var ball := node as GameBall
		if ball == _template_ball or ball.set_up or not ball.visible or ball.is_queued_for_deletion():
			continue
		out.append(ball)
	return out


func consume(ball: GameBall) -> void:
	ball.visible = false
	ball.set_up = false
	ball.remove_from_group("ball")
	ball.queue_free()


func spawn_copy(source: GameBall, offset: Vector2 = Vector2.ZERO) -> GameBall:
	return _spawn(source.data, source.level, source.position + offset, false)


func spawn_setup_ball() -> GameBall:
	var data := _roll_ball_data()
	return _spawn(data, data.random_spawn_level(), _template_ball.position, true)


func wake() -> void:
	for node in _root.get_tree().get_nodes_in_group("ball"):
		if node is RigidBody2D and not (node as Node).is_queued_for_deletion():
			(node as RigidBody2D).sleeping = false


func _spawn(data: BallData, level: int, position: Vector2, is_set_up: bool) -> GameBall:
	var ball := _template_ball.duplicate() as GameBall
	_root.add_child(ball)
	ball.position = position
	ball.visible = true
	ball.configure(data, level, _state, _target)
	ball.set_collision_enabled(true)
	ball.set_playfield_state(is_set_up)
	if is_set_up:
		ball.dropped.connect(_on_ball_dropped)
	return ball


func _load_ball_pool(content_dir: String) -> Array[BallData]:
	var pool: Array[BallData] = []
	for file_name in DirAccess.get_files_at(content_dir):
		if not file_name.ends_with(".tres"):
			continue
		var data := load("%s/%s" % [content_dir, file_name]) as BallData
		if data.spawn_weight > 0:
			pool.append(data)
	return pool


func _roll_ball_data() -> BallData:
	var total_weight := 0
	for data in _spawn_pool:
		total_weight += data.spawn_weight
	var roll := randi_range(1, total_weight)
	for data in _spawn_pool:
		roll -= data.spawn_weight
		if roll <= 0:
			return data
	return _spawn_pool[0]
