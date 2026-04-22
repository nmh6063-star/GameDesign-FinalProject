extends RefCounted
class_name BattleBallManager

const ElementCatalog := preload("res://script/entities/balls/elemental_balls/elemental_ball_catalog.gd")
const BallCatalog := preload("res://script/entities/balls/ball_catalog.gd")
const BallBase := preload("res://script/entities/balls/ball_base.gd")
const QUEUE_SIZE := 5
const Effects := preload("res://script/battle/core/general_effects.gd")

var _root: Node2D
var _ball_parent: Node
var _ball_placeholder: BallBase
var _context: BattleContext
var _target: Node2D
var _on_ball_dropped: Callable
var _spawn_pool: Array = []
var _queue: Array = []
var _held_entry: Dictionary = {}
var _drop_left_x: float
var _drop_right_x: float
var _drop_y: float


func _init(
	root: Node2D,
	ball_placeholder: BallBase,
	ctx: BattleContext,
	target: Node2D,
	on_ball_dropped: Callable,
	ball_ids: Array[String] = []
) -> void:
	_root = root
	_ball_parent = ball_placeholder.get_parent()
	_ball_placeholder = ball_placeholder
	_context = ctx
	_target = target
	_on_ball_dropped = on_ball_dropped
	_spawn_pool = _load_ball_pool(ball_ids)
	assert(not _spawn_pool.is_empty(), "No ball scenes found")
	_fill_queue()
	_ball_placeholder.set_runtime(_context, _target)
	_ball_placeholder.set_collision_enabled(false)
	_capture_drop_bounds()


func active() -> Array:
	var out: Array = []
	for node in _root.get_tree().get_nodes_in_group("ball"):
		if not node is BallBase:
			continue
		var ball := node as BallBase
		if ball == _ball_placeholder or not ball.is_active_in_board():
			continue
		out.append(ball)
	return out


func consume(ball: BallBase) -> void:
	ball.set_playfield_state(false)
	ball.remove_from_group("ball")
	var effect = Effects.new()
	_root.add_child(effect)
	var effect2 = Effects.new()
	_root.add_child(effect2)
	if str(ball.data.id) == "ball_bomb":
		effect2.freeze_frame(0.1)
		effect.shake(10.0)
	else:
		effect2.freeze_frame(float(ball.level) / 1000.0)
		effect.shake(ball.level / 10.0)
	ball.die()


func spawn_copy(source: BallBase, offset: Vector2 = Vector2.ZERO) -> BallBase:
	return _spawn_instance(source.duplicate() as BallBase, source.data, source.level, source.position + offset, false)


func spawn_ball(ball_id: String, level: int, global_position: Vector2, impulse: Vector2 = Vector2.ZERO) -> BallBase:
	var data := BallCatalog.data_for_id(ball_id)
	#var data.element_list.append(BallCatalog.data_for_el)
	if data == null:
		return null
	var scene := BallCatalog.scene_for_id(ball_id)
	var ball := scene.instantiate() as BallBase
	if ball == null:
		return null
	var spawned := _spawn_instance(ball, data, level, _ball_placeholder.position, false)
	spawned.global_position = global_position
	spawned.apply_central_impulse(impulse)
	spawned.sleeping = false
	return spawned


func drop_ball(ball_id: String, level: int = 1) -> BallBase:
	var data := BallCatalog.data_for_id(ball_id)
	if data == null:
		return null
	var radius: float = data.radius_for_level(level)
	var x: float = randf_range(_drop_left_x + radius, _drop_right_x - radius)
	return drop_ball_at_x(ball_id, level, x)


func drop_ball_at_x(ball_id: String, level: int = 1, x: float = INF) -> BallBase:
	var data := BallCatalog.data_for_id(ball_id)
	if data == null:
		return null
	var scene := BallCatalog.scene_for_id(ball_id)
	var ball := scene.instantiate() as BallBase
	if ball == null:
		return null
	var radius: float = data.radius_for_level(level)
	var drop_x := _clamp_drop_x(_ball_placeholder.position.x if is_inf(x) else x, radius)
	var spawned := _spawn_instance(ball, data, level, Vector2(drop_x, _drop_y), false)
	spawned.sleeping = false
	return spawned


func spawn_setup_ball() -> BallBase:
	var entry := _take_queue_entry()
	var base = entry["scene"].instantiate() as BallBase
	if PlayerState.elements[entry["level"]]:
		base.type = PlayerState.elements[entry["level"]]["type"]
	var new_data = []
	for element in PlayerState.elements:
		if element == 0:
			for i in PlayerState.elements[0]:
				var obj = {
					"element": BallCatalog.data_for_element(i["type"].to_lower()),
					"effect": i["function"],
					"rank": i["rank"]
				}
				new_data.append(obj)
		elif PlayerState.elements[element]:
			var obj = {
				"element": BallCatalog.data_for_element(PlayerState.elements[element]["type"].to_lower()),
				"effect": PlayerState.elements[element]["function"],
				"rank": PlayerState.elements[element]["rank"]
			}
			new_data.append(obj)
	base.element_list = new_data
	return _spawn_instance(base, entry["data"], entry["level"], _ball_placeholder.position, true)


func hold_swap(current_ball: BallBase) -> bool:
	if not is_instance_valid(current_ball) or current_ball.data == null or not current_ball.is_setup_ball():
		return false
	var replacement := _take_queue_entry() if _held_entry.is_empty() else _held_entry.duplicate()
	if replacement.is_empty():
		return false
	_held_entry = _entry_from_ball(current_ball)
	current_ball.configure(replacement["data"], replacement["level"], _context, _target)
	current_ball.position = _ball_placeholder.position
	current_ball.linear_velocity = Vector2.ZERO
	current_ball.angular_velocity = 0.0
	current_ball.rotation = 0.0
	current_ball.sleeping = false
	current_ball.set_playfield_state(true)
	return true


func next_entry() -> Dictionary:
	_fill_queue()
	return {} if _queue.is_empty() else (_queue[0] as Dictionary).duplicate()


func queue_preview() -> Array:
	_fill_queue()
	var items: Array = []
	for i in range(1, QUEUE_SIZE):
		if i >= _queue.size():
			break
		items.append((_queue[i] as Dictionary).duplicate())
	return items


func held_entry() -> Dictionary:
	return _held_entry.duplicate()


func preview() -> Array:
	var items: Array = []
	var next := next_entry()
	if not next.is_empty():
		items.append(next)
	for entry in queue_preview():
		items.append(entry)
	return items


func _spawn_instance(ball: BallBase, data, level: int, position: Vector2, is_set_up: bool) -> BallBase:
	ball.configure(data, level, _context, _target)
	_ball_parent.add_child(ball)
	ball.position = position
	ball.visible = true
	ball.set_collision_enabled(true)
	ball.set_playfield_state(is_set_up)
	if is_set_up:
		ball.dropped.connect(_on_ball_dropped)
	return ball


func _load_ball_pool(ball_ids: Array[String]) -> Array:
	var pool: Array = []
	var ids: Array[String] = ball_ids.duplicate()
	if ids.is_empty():
		ids = BallCatalog.ids()
	for ball_id in ids:
		var data := BallCatalog.data_for_id(ball_id)
		if data == null or data.spawn_weight <= 0:
			continue
		pool.append({"id": ball_id, "scene": BallCatalog.scene_for_id(ball_id), "data": data})
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
			return {
				"id": entry["id"],
				"scene": entry["scene"],
				"data": entry["data"],
				"level": entry["data"].random_spawn_level(),
			}
	var entry: Dictionary = _spawn_pool[0]
	return {
		"id": entry["id"],
		"scene": entry["scene"],
		"data": entry["data"],
		"level": entry["data"].random_spawn_level(),
	}


func _capture_drop_bounds() -> void:
	_drop_y = _ball_placeholder.position.y
	var interior := _root.get_node("Background/Box/Interior") as Polygon2D
	var points := interior.polygon
	_drop_left_x = INF
	_drop_right_x = -INF
	for point in points:
		var x: float = interior.to_global(point).x
		_drop_left_x = minf(_drop_left_x, x)
		_drop_right_x = maxf(_drop_right_x, x)
	_drop_left_x -= _root.global_position.x
	_drop_right_x -= _root.global_position.x


func _clamp_drop_x(x: float, radius: float) -> float:
	return clampf(x, _drop_left_x + radius, _drop_right_x - radius)


func _entry_from_ball(ball: BallBase) -> Dictionary:
	return {
		"id": ball.data.id,
		"scene": BallCatalog.scene_for_id(ball.data.id),
		"data": ball.data,
		"level": ball.level,
	}
