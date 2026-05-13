extends RefCounted
class_name BattleBallManager

const ElementCatalog := preload("res://script/entities/balls/elemental_balls/elemental_ball_catalog.gd")
const BallCatalog := preload("res://script/entities/balls/ball_catalog.gd")
const BallBase := preload("res://script/entities/balls/ball_base.gd")
const QUEUE_SIZE := 5
const MAX_QUEUE_RANK := 3
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
	_apply_playfield_bounds_to_ball(_ball_placeholder)


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
	effect2.freeze_frame(float(ball.rank) / 50.0)
	effect.shake(ball.rank / 10.0)
	ball.die()


func spawn_copy(source: BallBase, offset: Vector2 = Vector2.ZERO) -> BallBase:
	return _spawn_instance(source.duplicate() as BallBase, source.data, source.rank, source.position + offset, false)


func spawn_ball(ball_id: String, rank: int, global_position: Vector2, impulse: Vector2 = Vector2.ZERO) -> BallBase:
	var data := BallCatalog.data_for_id(ball_id)
	#var data.element_list.append(BallCatalog.data_for_el)
	if data == null:
		return null
	var scene := BallCatalog.scene_for_id(ball_id)
	var ball := scene.instantiate() as BallBase
	if ball == null:
		return null
	var spawned := _spawn_instance(ball, data, rank, _ball_placeholder.position, false)
	spawned.global_position = global_position
	spawned.apply_central_impulse(impulse)
	spawned.sleeping = false
	return spawned


func drop_center_global() -> Vector2:
	return _ball_parent.to_global(Vector2(_cursor_x_clamped(0.0), _drop_y))


func drop_ball(ball_id: String, rank: int = 1) -> BallBase:
	var data := BallCatalog.data_for_id(ball_id)
	if data == null:
		return null
	var radius: float = data.radius_for_rank(rank)
	var x: float = randf_range(_drop_left_x + radius, _drop_right_x - radius)
	return drop_ball_at_x(ball_id, rank, x)


func drop_ball_at_x(ball_id: String, rank: int = 1, x: float = INF) -> BallBase:
	var data := BallCatalog.data_for_id(ball_id)
	if data == null:
		return null
	var scene := BallCatalog.scene_for_id(ball_id)
	var ball := scene.instantiate() as BallBase
	if ball == null:
		return null
	var radius: float = data.radius_for_rank(rank)
	var drop_x := _cursor_x_clamped(radius) if is_inf(x) else _clamp_drop_x(x, radius)
	var spawned := _spawn_instance(ball, data, rank, Vector2(drop_x, _drop_y), false)
	spawned.sleeping = false
	return spawned


## Like drop_ball_at_x, but also copies the player's equipped element_list onto the
## ball so it displays with the correct class texture (same as the queued setup balls).
func drop_element_ball_at_x(rank: int, x: float = INF) -> BallBase:
	var ball_id := BallCatalog.NORMAL_BALL_ID
	var data := BallCatalog.data_for_id(ball_id)
	if data == null:
		return null
	var scene := BallCatalog.scene_for_id(ball_id)
	var ball := scene.instantiate() as BallBase
	if ball == null:
		return null
	# Mirror the element setup from spawn_setup_ball so visuals match queued balls.
	if PlayerState.elements.get(rank) != null:
		var type_str := String(PlayerState.elements[rank].get("type", ""))
		if not type_str.is_empty():
			ball.type.append(type_str)
	var new_data := []
	for element in PlayerState.elements:
		if element == 0:
			for i in PlayerState.elements[0]:
				new_data.append({
					"element": BallCatalog.data_for_element(String(i.get("type", "")).to_lower()),
					"effect":  i.get("function", ""),
					"rank":    i.get("rank", 1),
				})
		elif PlayerState.elements[element] != null:
			var el: Dictionary = PlayerState.elements[element]
			new_data.append({
				"element": BallCatalog.data_for_element(String(el.get("type", "")).to_lower()),
				"effect":  el.get("function", ""),
				"rank":    el.get("rank", 1),
			})
	ball.element_list = new_data
	var radius: float = data.radius_for_rank(rank)
	# When no X is given, pick a truly random local X across the full box width
	# (same as drop_ball does) rather than following the cursor.
	var drop_x: float
	if is_inf(x):
		drop_x = randf_range(_drop_left_x + radius, _drop_right_x - radius)
	else:
		drop_x = _clamp_drop_x(x, radius)
	var spawned := _spawn_instance(ball, data, rank, Vector2(drop_x, _drop_y), false)
	spawned.sleeping = false
	return spawned


func spawn_setup_ball() -> BallBase:
	var entry := _take_queue_entry()

	var base = entry["scene"].instantiate() as BallBase

	base.type = (entry.get("type", []) as Array).duplicate(true)
	base.element_list = (entry.get("element_list", []) as Array).duplicate(true)

	var entry_data = entry["data"]

	var setup_radius: float = entry_data.radius_for_rank(int(entry["rank"]))

	return _spawn_instance(
		base,
		entry["data"],
		entry["rank"],
		_setup_ball_position(setup_radius),
		true
	)


func hold_swap(current_ball: BallBase) -> bool:
	if not is_instance_valid(current_ball) or current_ball.data == null or not current_ball.is_setup_ball():
		return false

	var replacement := _take_queue_entry() if _held_entry.is_empty() else _held_entry.duplicate()

	if replacement.is_empty():
		return false

	_held_entry = _entry_from_ball(current_ball)

	current_ball.type = (replacement.get("type", []) as Array).duplicate(true)
	current_ball.element_list = (replacement.get("element_list", []) as Array).duplicate(true)

	current_ball.configure(
		replacement["data"],
		replacement["rank"],
		_context,
		_target
	)

	_apply_playfield_bounds_to_ball(current_ball)

	var swap_radius: float = current_ball.data.radius_for_rank(current_ball.rank)

	current_ball.position = _setup_ball_position(swap_radius)
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


func _spawn_instance(ball: BallBase, data, rank: int, position: Vector2, is_set_up: bool) -> BallBase:
	_ball_parent.add_child(ball)
	ball.configure(data, rank, _context, _target)
	_apply_playfield_bounds_to_ball(ball)
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
			var rank := _roll_queue_rank()

			return {
				"id": entry["id"],
				"scene": entry["scene"],
				"data": entry["data"],
				"rank": rank,
				"element_list": _build_element_list(),
				"type": _build_ball_types(rank),
			}

	var entry: Dictionary = _spawn_pool[0]
	var rank := _roll_queue_rank()

	return {
		"id": entry["id"],
		"scene": entry["scene"],
		"data": entry["data"],
		"rank": rank,
		"element_list": _build_element_list(),
		"type": _build_ball_types(rank),
	}


## Queue rank distribution:
## rank 1: 50%
## rank 2: 35%
## rank 3: 15%
func _roll_queue_rank() -> int:
	var roll := _rng_percent()
	if roll <= 50:
		return 1
	if roll <= 85:
		return 2
	return 3


func _rng_percent() -> int:
	return randi_range(1, 100)


func _capture_drop_bounds() -> void:
	_drop_y = _ball_placeholder.position.y
	var interior := _root.get_node_or_null("Background/Box/Interior") as Polygon2D
	if interior == null:
		push_error("BattleBallManager: expected node Background/Box/Interior (Polygon2D)")
		_drop_left_x = _ball_placeholder.position.x - 100.0
		_drop_right_x = _ball_placeholder.position.x + 100.0
		return
	var points := interior.polygon
	_drop_left_x = INF
	_drop_right_x = -INF
	for point in points:
		var lp: Vector2 = _ball_parent.to_local(interior.to_global(point))
		_drop_left_x = minf(_drop_left_x, lp.x)
		_drop_right_x = maxf(_drop_right_x, lp.x)
	if not is_finite(_drop_left_x) or not is_finite(_drop_right_x) or _drop_right_x <= _drop_left_x:
		push_error("BattleBallManager: Interior polygon is empty or invalid")
		_drop_left_x = _ball_placeholder.position.x - 100.0
		_drop_right_x = _ball_placeholder.position.x + 100.0


func _apply_playfield_bounds_to_ball(ball: BallBase) -> void:
	ball.set_playfield_x_bounds(_drop_left_x, _drop_right_x)


## Call after editing the box / Interior polygon at runtime (editor changes are read on battle start).
func refresh_drop_bounds() -> void:
	_capture_drop_bounds()
	_apply_playfield_bounds_to_ball(_ball_placeholder)
	for node in _ball_parent.get_children():
		if node is BallBase and node != _ball_placeholder:
			_apply_playfield_bounds_to_ball(node as BallBase)


func _clamp_drop_x(x: float, radius: float) -> float:
	return clampf(x, _drop_left_x + radius, _drop_right_x - radius)


func _cursor_x_clamped(radius: float) -> float:
	var w := _drop_right_x - _drop_left_x
	if w <= 0.001:
		return _ball_placeholder.position.x
	var cursor_x: float = _ball_parent.to_local(_ball_parent.get_global_mouse_position()).x
	return _clamp_drop_x(cursor_x, radius)


func _setup_ball_position(radius: float) -> Vector2:
	var w := _drop_right_x - _drop_left_x
	if w <= 0.001:
		return _ball_placeholder.position
	return Vector2(_cursor_x_clamped(radius), _drop_y)


func _entry_from_ball(ball: BallBase) -> Dictionary:
	return {
		"id": ball.data.id,
		"scene": BallCatalog.scene_for_id(ball.data.id),
		"data": ball.data,
		"rank": ball.rank,
		"element_list": ball.element_list.duplicate(true),
		"type": ball.type.duplicate(true),
	}

func _build_element_list() -> Array:
	var new_data := []

	for element in PlayerState.elements:
		if element == 0:
			for i in PlayerState.elements[0]:
				new_data.append({
					"element": BallCatalog.data_for_element(String(i.get("type", "")).to_lower()),
					"effect": i.get("function", ""),
					"rank": i.get("rank", 1),
				})
		elif PlayerState.elements[element] != null:
			var el: Dictionary = PlayerState.elements[element]
			new_data.append({
				"element": BallCatalog.data_for_element(String(el.get("type", "")).to_lower()),
				"effect": el.get("function", ""),
				"rank": el.get("rank", 1),
			})

	return new_data

func _build_ball_types(rank: int) -> Array:
	var out := []

	if PlayerState.elements.get(rank) != null:
		var type_str := String(PlayerState.elements[rank].get("type", ""))
		if not type_str.is_empty():
			out.append(type_str)

	return out
