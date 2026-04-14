extends RefCounted
class_name MapGenerator

const X_DIST := 30.0
const Y_DIST := 25.0
const PLACEMENT_RANDOMNESS := 5.0

const FLOORS := 10
const MAP_WIDTH := 7
const PATHS := 6
const MAX_OUTGOING := 3

const MONSTER_ROOM_WEIGHT := 10.0
const SHOP_ROOM_WEIGHT := 2.5
const CAMPFIRE_ROOM_WEIGHT := 4.0


class Room extends RefCounted:
	enum Type {
		NOT_ASSIGNED,
		START,
		MONSTER,
		TREASURE,
		SHOP,
		CAMPFIRE,
		BOSS,
	}

	var id := -1
	var row := -1
	var column := -1
	var position := Vector2.ZERO
	var next_rooms: Array = []
	var prev_rooms: Array = []
	var type := Type.NOT_ASSIGNED
	var selected := false

	func is_active() -> bool:
		return not next_rooms.is_empty() or not prev_rooms.is_empty() or type == Type.BOSS

	func to_dictionary() -> Dictionary:
		var next_ids: Array = []
		var prev_ids: Array = []
		for room_data in next_rooms:
			next_ids.append((room_data as Room).id)
		for room_data in prev_rooms:
			prev_ids.append(int(room_data) if room_data is int else (room_data as Room).id)
		return {
			"id": id,
			"row": row,
			"column": column,
			"position": position,
			"room_type": type,
			"selected": selected,
			"next_room_ids": next_ids,
			"prev_room_ids": prev_ids,
		}


class Run extends RefCounted:
	var seed := 0
	var floors: Array = []
	var rooms_by_id := {}
	var start_room_ids: Array = []
	var boss_room_id := -1

	func room(room_id: int) -> Room:
		return rooms_by_id.get(room_id) as Room

	func start_rooms() -> Array:
		var rooms: Array = []
		for room_id in start_room_ids:
			var data := room(int(room_id))
			if data != null:
				rooms.append(data)
		return rooms

	func all_rooms() -> Array:
		var rooms: Array = []
		for floor in floors:
			for room_data in floor:
				rooms.append(room_data)
		return rooms

	func to_dictionary() -> Dictionary:
		var rooms := {}
		var floor_ids: Array = []
		for floor in floors:
			var ids: Array = []
			for room_data in floor:
				var room := room_data as Room
				ids.append(room.id)
				rooms[room.id] = room.to_dictionary()
			floor_ids.append(ids)
		return {
			"seed": seed,
			"floors": floor_ids,
			"rooms": rooms,
			"start_room_ids": start_room_ids.duplicate(),
			"boss_room_id": boss_room_id,
		}


var _rng := RandomNumberGenerator.new()
var _next_room_id := 0
var _weight_total := MONSTER_ROOM_WEIGHT + SHOP_ROOM_WEIGHT + CAMPFIRE_ROOM_WEIGHT


func generate(seed: int = -1) -> Run:
	var run_seed := seed if seed >= 0 else int(Time.get_unix_time_from_system())
	_rng.seed = run_seed
	_next_room_id = 0
	var floors := _generate_grid()
	for start_column in _starting_columns():
		var current_column := int(start_column)
		for row in range(FLOORS - 1):
			current_column = _connect_room(floors, row, current_column)
	var boss_room := _append_boss_room(floors)
	_assign_room_types(floors, boss_room)
	return _pack_run(floors, boss_room, run_seed)


func generate_map(seed: int = -1) -> Array:
	return generate(seed).floors


func validate(run: Run) -> Array:
	var errors: Array = []
	if run == null or run.start_room_ids.is_empty():
		errors.append("Map has no start rooms")
		return errors
	if run.start_room_ids.size() > 3:
		errors.append("Map exposes more than 3 start rooms")
	for room_data in run.all_rooms():
		var room := room_data as Room
		if room.type != Room.Type.BOSS and room.next_rooms.size() > MAX_OUTGOING:
			errors.append("Room %d exceeds max outgoing" % room.id)
		for next_room_data in room.next_rooms:
			var next_room := next_room_data as Room
			if next_room.row != room.row + 1:
				errors.append("Invalid edge %d -> %d" % [room.id, next_room.id])
	if _has_crossing_paths(run):
		errors.append("Crossing paths detected")
	var reachable := {}
	var frontier: Array = run.start_rooms()
	while not frontier.is_empty():
		var room_data := frontier.pop_back() as Room
		if reachable.has(room_data.id):
			continue
		reachable[room_data.id] = true
		for next_room_data in room_data.next_rooms:
			frontier.append(next_room_data)
	if reachable.size() != run.all_rooms().size():
		errors.append("Unreachable rooms detected")
	var boss := run.room(run.boss_room_id)
	if boss == null or not reachable.has(boss.id):
		errors.append("Boss is unreachable")
	return errors


func _generate_grid() -> Array:
	var floors: Array = []
	for row in range(FLOORS):
		var floor: Array = []
		for column in range(MAP_WIDTH):
			var room := Room.new()
			room.id = _take_room_id()
			room.row = row
			room.column = column
			room.position = Vector2(column * X_DIST, row * -Y_DIST)
			room.position += Vector2(_rng.randf_range(-PLACEMENT_RANDOMNESS, PLACEMENT_RANDOMNESS), _rng.randf_range(-PLACEMENT_RANDOMNESS, PLACEMENT_RANDOMNESS))
			room.type = Room.Type.NOT_ASSIGNED
			floor.append(room)
		floors.append(floor)
	return floors


func _starting_columns() -> Array:
	var columns: Array = []
	var anchors := [1, MAP_WIDTH / 2, MAP_WIDTH - 2]
	for anchor in anchors:
		var column := clampi(int(anchor) + _rng.randi_range(-1, 1), 0, MAP_WIDTH - 1)
		if column not in columns:
			columns.append(column)
	while columns.size() < PATHS:
		columns.append(columns[_rng.randi_range(0, columns.size() - 1)])
	return columns


func _connect_room(floors: Array, row: int, column: int) -> int:
	var current := floors[row][column] as Room
	if not current.next_rooms.is_empty() and current.next_rooms.size() >= MAX_OUTGOING and _rng.randf() < 0.55:
		return (current.next_rooms[_rng.randi_range(0, current.next_rooms.size() - 1)] as Room).column
	var options: Array = []
	for next_column in [column - 1, column, column + 1]:
		if next_column < 0 or next_column >= MAP_WIDTH:
			continue
		var next_room := floors[row + 1][next_column] as Room
		if _would_cross_existing_path(floors, row, column, next_room):
			continue
		if current.next_rooms.size() >= MAX_OUTGOING and next_room not in current.next_rooms:
			continue
		var weight := 1.0
		if next_room not in current.next_rooms:
			weight += 0.8
		if row < 3 and abs(next_column - column) == 1:
			weight += 0.9
		if row >= FLOORS - 4 and next_column == MAP_WIDTH / 2:
			weight += 0.7
		options.append({"room": next_room, "weight": weight})
	if options.is_empty():
		return column
	var next_room := _pick_weighted_room(options)
	if next_room not in current.next_rooms:
		current.next_rooms.append(next_room)
		next_room.prev_rooms.append(current)
	return next_room.column


func _would_cross_existing_path(floors: Array, row: int, column: int, next_room: Room) -> bool:
	var target_column := next_room.column
	for offset in [-1, 1]:
		var neighbor_column: int = column + offset
		if neighbor_column < 0 or neighbor_column >= MAP_WIDTH:
			continue
		var neighbor := floors[row][neighbor_column] as Room
		for connected_room_data in neighbor.next_rooms:
			var connected_room := connected_room_data as Room
			if offset > 0 and target_column > column and connected_room.column < target_column:
				return true
			if offset < 0 and target_column < column and connected_room.column > target_column:
				return true
	return false


func _append_boss_room(floors: Array) -> Room:
	var boss_room := Room.new()
	boss_room.id = _take_room_id()
	boss_room.row = FLOORS
	boss_room.column = MAP_WIDTH / 2
	boss_room.position = Vector2((MAP_WIDTH / 2) * X_DIST, -FLOORS * Y_DIST)
	boss_room.type = Room.Type.BOSS
	for room_data in floors[FLOORS - 1]:
		var room := room_data as Room
		if not room.prev_rooms.is_empty():
			room.next_rooms = [boss_room]
			boss_room.prev_rooms.append(room)
	return boss_room


func _assign_room_types(floors: Array, boss_room: Room) -> void:
	for room_data in floors[0]:
		var room := room_data as Room
		if room.is_active():
			room.type = Room.Type.MONSTER
	if FLOORS > 8:
		for room_data in floors[8]:
			var room := room_data as Room
			if room.is_active():
				room.type = Room.Type.TREASURE
	for room_data in floors[FLOORS - 1]:
		var room := room_data as Room
		if room.is_active():
			room.type = Room.Type.CAMPFIRE
	boss_room.type = Room.Type.BOSS
	for row in range(1, FLOORS - 1):
		if row == 8:
			continue
		for room_data in floors[row]:
			var room := room_data as Room
			if room.is_active() and room.type == Room.Type.NOT_ASSIGNED:
				room.type = _random_room_type(room)


func _random_room_type(room: Room) -> int:
	while true:
		var roll := _rng.randf() * _weight_total
		var room_type := Room.Type.MONSTER
		if roll >= MONSTER_ROOM_WEIGHT + CAMPFIRE_ROOM_WEIGHT:
			room_type = Room.Type.SHOP
		elif roll >= MONSTER_ROOM_WEIGHT:
			room_type = Room.Type.CAMPFIRE
		if room_type == Room.Type.CAMPFIRE and (room.row < 3 or room.row == 12 or _has_parent_of_type(room, Room.Type.CAMPFIRE)):
			continue
		if room_type == Room.Type.SHOP and _has_parent_of_type(room, Room.Type.SHOP):
			continue
		return room_type
	return Room.Type.MONSTER


func _has_parent_of_type(room: Room, room_type: int) -> bool:
	for parent_data in room.prev_rooms:
		if (parent_data as Room).type == room_type:
			return true
	return false


func _pack_run(floors: Array, boss_room: Room, seed: int) -> Run:
	var run := Run.new()
	run.seed = seed
	var keep := _kept_room_ids(floors, boss_room)
	for floor_data in floors:
		var active_floor: Array = []
		for room_data in floor_data:
			var room := room_data as Room
			if keep.has(room.id):
				var kept_next: Array = []
				for next_room_data in room.next_rooms:
					var next_room := next_room_data as Room
					if keep.has(next_room.id):
						kept_next.append(next_room)
				room.next_rooms = kept_next
				var parent_ids: Array = []
				for parent_data in room.prev_rooms:
					var parent := parent_data as Room
					if keep.has(parent.id):
						parent_ids.append(parent.id)
				room.prev_rooms = parent_ids
				active_floor.append(room)
				run.rooms_by_id[room.id] = room
				if room.row == 0:
					run.start_room_ids.append(room.id)
		if not active_floor.is_empty():
			active_floor.sort_custom(func(left, right): return (left as Room).column < (right as Room).column)
			run.floors.append(active_floor)
	var boss_parent_ids: Array = []
	for parent_data in boss_room.prev_rooms:
		var parent := parent_data as Room
		if keep.has(parent.id):
			boss_parent_ids.append(parent.id)
	boss_room.prev_rooms = boss_parent_ids
	run.rooms_by_id[boss_room.id] = boss_room
	run.boss_room_id = boss_room.id
	run.floors.append([boss_room])
	run.start_room_ids.sort()
	return run


func _kept_room_ids(floors: Array, boss_room: Room) -> Dictionary:
	var from_start := {}
	var start_frontier: Array = []
	for room_data in floors[0]:
		var room := room_data as Room
		if not room.next_rooms.is_empty():
			start_frontier.append(room)
	while not start_frontier.is_empty():
		var room := start_frontier.pop_back() as Room
		if from_start.has(room.id):
			continue
		from_start[room.id] = true
		for next_room_data in room.next_rooms:
			start_frontier.append(next_room_data)
	var to_boss := {}
	var boss_frontier: Array = [boss_room]
	while not boss_frontier.is_empty():
		var room := boss_frontier.pop_back() as Room
		if to_boss.has(room.id):
			continue
		to_boss[room.id] = true
		for parent_data in room.prev_rooms:
			boss_frontier.append(parent_data)
	var keep := {boss_room.id: true}
	for room_id in from_start.keys():
		if to_boss.has(int(room_id)):
			keep[int(room_id)] = true
	return keep


func _has_crossing_paths(run: Run) -> bool:
	for floor in run.floors:
		for room_data in floor:
			var room := room_data as Room
			for next_room_data in room.next_rooms:
				var next_room := next_room_data as Room
				for other_room_data in floor:
					var other_room := other_room_data as Room
					for other_next_room_data in other_room.next_rooms:
						var other_next_room := other_next_room_data as Room
						if room == other_room or next_room == other_next_room:
							continue
						if (room.column < other_room.column and next_room.column > other_next_room.column) or (room.column > other_room.column and next_room.column < other_next_room.column):
							return true
	return false


func _pick_weighted_room(options: Array) -> Room:
	var total := 0.0
	for option in options:
		total += float((option as Dictionary).get("weight", 0.0))
	var roll := _rng.randf() * total
	for option in options:
		var data := option as Dictionary
		roll -= float(data.get("weight", 0.0))
		if roll <= 0.0:
			return data.get("room") as Room
	return (options.back() as Dictionary).get("room") as Room


func _take_room_id() -> int:
	var room_id := _next_room_id
	_next_room_id += 1
	return room_id
