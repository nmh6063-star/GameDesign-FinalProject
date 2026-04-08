extends RefCounted
class_name BattleBox

const GameBall := preload("res://script/ball/game_ball.gd")
const QUEUE_SIZE := 5

var _root: Node2D
var _ball_parent: Node
var _ball_placeholder: GameBall
var _state
var _target: Node2D
var _on_ball_dropped: Callable
var _spawn_pool: Array = []
var _queue: Array = []

func _init(root: Node2D, ball_placeholder: GameBall, state, target: Node2D, on_ball_dropped: Callable, scene_dir: String) -> void:
	_root = root
	_ball_parent = ball_placeholder.get_parent()
	_ball_placeholder = ball_placeholder
	_state = state
	_target = target
	_on_ball_dropped = on_ball_dropped
	_spawn_pool = _load_ball_pool(scene_dir)
	assert(not _spawn_pool.is_empty(), "No ball scenes found in %s" % scene_dir)
	_fill_queue()
	_ball_placeholder.set_runtime(_state, _target)
	_ball_placeholder.set_collision_enabled(false)


func active() -> Array:
	var out: Array = []
	for node in _root.get_tree().get_nodes_in_group("ball"):
		if not node is GameBall:
			continue
		var ball := node as GameBall
		if ball == _ball_placeholder or ball.set_up or not ball.visible or ball.is_queued_for_deletion():
			continue
		out.append(ball)
	return out


func consume(ball: GameBall) -> void:
	ball.visible = false
	ball.set_up = false
	ball.remove_from_group("ball")
	ball.queue_free()


func spawn_copy(source: GameBall, offset: Vector2 = Vector2.ZERO) -> GameBall:
	return _spawn_instance(source.duplicate() as GameBall, source.data, source.level, source.position + offset, false)


func spawn_setup_ball() -> GameBall:
	var entry := _take_queue_entry()
	return _spawn_instance(entry["scene"].instantiate() as GameBall, entry["data"], entry["level"], _ball_placeholder.position, true)


func preview() -> Array:
	var items: Array = []
	for entry in _queue:
		if items.size() == QUEUE_SIZE:
			break
		items.append(entry)
	return items


func wake() -> void:
	for node in _root.get_tree().get_nodes_in_group("ball"):
		if node is RigidBody2D and not (node as Node).is_queued_for_deletion():
			(node as RigidBody2D).sleeping = false


func _spawn_instance(ball: GameBall, data, level: int, position: Vector2, is_set_up: bool) -> GameBall:
	_ball_parent.add_child(ball)
	ball.position = position
	ball.visible = true
	ball.configure(data, level, _state, _target)
	ball.set_collision_enabled(true)
	ball.set_playfield_state(is_set_up)
	if is_set_up:
		ball.dropped.connect(_on_ball_dropped)
	return ball


func _load_ball_pool(scene_dir: String) -> Array:
	var pool: Array = []
	for file_name in DirAccess.get_files_at(scene_dir):
		if not file_name.ends_with(".tscn"):
			continue
		var scene := load("%s/%s" % [scene_dir, file_name]) as PackedScene
		if scene == null:
			continue
		var ball := scene.instantiate() as GameBall
		if ball != null and ball.data != null and ball.data.spawn_weight > 0:
			pool.append({"scene": scene, "data": ball.data})
		if ball != null:
			ball.free()
	return pool


func _take_queue_entry() -> Dictionary:
	_fill_queue()
	var entry: Dictionary = _queue.pop_front()
	_fill_queue()
	return entry


func _fill_queue() -> void:
	while _queue.size() < QUEUE_SIZE:
		_queue.append(_roll_ball_entry())


func _roll_ball_entry() -> Dictionary:
	var total_weight := 0
	for entry in _spawn_pool:
		total_weight += entry["data"].spawn_weight
	var roll := randi_range(1, total_weight)
	for entry in _spawn_pool:
		roll -= entry["data"].spawn_weight
		if roll <= 0:
			return {"scene": entry["scene"], "data": entry["data"], "level": entry["data"].random_spawn_level()}
	var entry: Dictionary = _spawn_pool[0]
	return {"scene": entry["scene"], "data": entry["data"], "level": entry["data"].random_spawn_level()}
