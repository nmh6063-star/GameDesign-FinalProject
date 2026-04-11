extends RefCounted
class_name MapGenerator

const MapTypes := preload("res://script/map/map_types.gd")


class GenerationConfig extends RefCounted:
	var seed := 0
	var total_layers := 8
	var middle_boss_layer := 4
	var regular_layer_width := 3
	var max_outgoing := 3
	var reroll_attempts := 64
	var room_quotas := {
		MapTypes.RoomType.BATTLE: 7,
		MapTypes.RoomType.ELITE: 2,
		MapTypes.RoomType.EVENT: 2,
		MapTypes.RoomType.SHOP: 1,
		MapTypes.RoomType.REST: 1,
		MapTypes.RoomType.TREASURE: 2,
	}
	var phase_weights := {
		"early": {
			MapTypes.RoomType.BATTLE: 2.7,
			MapTypes.RoomType.ELITE: 0.4,
			MapTypes.RoomType.EVENT: 2.2,
			MapTypes.RoomType.SHOP: 0.9,
			MapTypes.RoomType.REST: 0.4,
			MapTypes.RoomType.TREASURE: 2.4,
		},
		"middle": {
			MapTypes.RoomType.BATTLE: 2.4,
			MapTypes.RoomType.ELITE: 1.8,
			MapTypes.RoomType.EVENT: 1.5,
			MapTypes.RoomType.SHOP: 1.7,
			MapTypes.RoomType.REST: 1.6,
			MapTypes.RoomType.TREASURE: 0.9,
		},
		"late": {
			MapTypes.RoomType.BATTLE: 3.1,
			MapTypes.RoomType.ELITE: 2.1,
			MapTypes.RoomType.EVENT: 1.0,
			MapTypes.RoomType.SHOP: 0.3,
			MapTypes.RoomType.REST: 0.7,
			MapTypes.RoomType.TREASURE: 0.3,
		},
	}

	func final_layer() -> int:
		return total_layers - 1

	func is_special_layer(layer_index: int) -> bool:
		return layer_index == 0 or layer_index == middle_boss_layer or layer_index == final_layer()

	func layer_width(layer_index: int) -> int:
		if is_special_layer(layer_index):
			return 1
		return regular_layer_width

	func regular_layer_indices() -> Array:
		var layers: Array = []
		for layer_index in range(1, final_layer()):
			if layer_index == middle_boss_layer:
				continue
			layers.append(layer_index)
		return layers

	func clone() -> GenerationConfig:
		var copy := GenerationConfig.new()
		copy.seed = seed
		copy.total_layers = total_layers
		copy.middle_boss_layer = middle_boss_layer
		copy.regular_layer_width = regular_layer_width
		copy.max_outgoing = max_outgoing
		copy.reroll_attempts = reroll_attempts
		copy.room_quotas = room_quotas.duplicate(true)
		copy.phase_weights = phase_weights.duplicate(true)
		return copy


class RoomNode extends RefCounted:
	var id := -1
	var layer_index := -1
	var slot_index := -1
	var room_type := MapTypes.RoomType.BATTLE
	var outgoing: Array = []
	var incoming: Array = []

	func short_code() -> String:
		return MapTypes.mark(room_type)

	func display_name() -> String:
		return MapTypes.label(room_type)


class LayerData extends RefCounted:
	var index := -1
	var node_ids: Array = []


class RunData extends RefCounted:
	var seed := 0
	var config: GenerationConfig
	var layers: Array = []
	var nodes_by_id := {}
	var start_node_id := -1
	var middle_boss_node_id := -1
	var final_boss_node_id := -1

	func node(node_id: int) -> RoomNode:
		return nodes_by_id.get(node_id) as RoomNode

	func nodes_in_layer(layer_index: int) -> Array:
		if layer_index < 0 or layer_index >= layers.size():
			return []
		var rooms: Array = []
		var layer: LayerData = layers[layer_index] as LayerData
		for node_id in layer.node_ids:
			rooms.append(node(node_id))
		return rooms

	func all_nodes() -> Array:
		var rooms: Array = []
		for layer in layers:
			for node_id in (layer as LayerData).node_ids:
				rooms.append(node(node_id))
		return rooms


func generate(seed: int = -1, base_config: GenerationConfig = null) -> RunData:
	var config := _normalized_config(seed, base_config)
	for attempt in range(config.reroll_attempts):
		var rng := RandomNumberGenerator.new()
		rng.seed = int(config.seed + (attempt * 977))
		var run := _build_empty_run(config)
		if not _assign_regular_room_types(run, config, rng):
			continue
		_generate_connections(run, config, rng)
		_repair_connections(run, config, rng)
		if validate(run, config).is_empty():
			return run
	var fallback := _build_empty_run(config)
	_assign_fallback_room_types(fallback, config)
	var fallback_rng := RandomNumberGenerator.new()
	fallback_rng.seed = config.seed
	_generate_connections(fallback, config, fallback_rng)
	_repair_connections(fallback, config, fallback_rng)
	return fallback


func validate(run: RunData, config: GenerationConfig = null) -> Array:
	var errors: Array = []
	if run == null:
		errors.append("Run data missing")
		return errors
	var effective := config if config != null else run.config
	if effective == null:
		errors.append("Generation config missing")
		return errors
	if _quota_total(effective.room_quotas) != _regular_slot_count(effective):
		errors.append("Regular room quotas do not match the regular slot count")
	var room_counts := _regular_room_counts(run)
	for room_type in MapTypes.REGULAR_TYPES:
		var expected := int(effective.room_quotas.get(room_type, 0))
		var actual := int(room_counts.get(room_type, 0))
		if actual != expected:
			errors.append("%s quota mismatch: %d / %d" % [MapTypes.label(room_type), actual, expected])
	for room in run.all_nodes():
		if room.layer_index == 0 and room.room_type != MapTypes.RoomType.START:
			errors.append("Layer 0 must always be Start")
		elif room.layer_index == effective.middle_boss_layer and room.room_type != MapTypes.RoomType.MIDDLE_BOSS:
			errors.append("Middle boss layer invalid")
		elif room.layer_index == effective.final_layer() and room.room_type != MapTypes.RoomType.FINAL_BOSS:
			errors.append("Final boss layer invalid")
		elif not effective.is_special_layer(room.layer_index) and not _is_room_type_legal_in_run(run, effective, room):
			errors.append("Illegal room %s at layer %d" % [MapTypes.label(room.room_type), room.layer_index])
		if room.layer_index == effective.final_layer():
			if not room.outgoing.is_empty():
				errors.append("Final room must not have outgoing edges")
		else:
			if room.outgoing.is_empty():
				errors.append("Room %d has no outgoing path" % room.id)
			if room.outgoing.size() > effective.max_outgoing:
				errors.append("Room %d exceeds max outgoing paths" % room.id)
		if room.layer_index == 0:
			if not room.incoming.is_empty():
				errors.append("Start room must not have incoming edges")
		elif room.incoming.is_empty():
			errors.append("Room %d has no incoming path" % room.id)
		for target_id in room.outgoing:
			var target := run.node(target_id)
			if target == null or target.layer_index != room.layer_index + 1:
				errors.append("Room %d has invalid outgoing target" % room.id)
	var reachable := _reachable_from_start(run)
	var can_reach_final := _reachable_to_final(run)
	for room in run.all_nodes():
		if not reachable.has(room.id):
			errors.append("Room %d is not reachable from Start" % room.id)
		if not can_reach_final.has(room.id):
			errors.append("Room %d cannot reach Final Boss" % room.id)
	return errors


func _normalized_config(seed: int, base_config: GenerationConfig) -> GenerationConfig:
	var config := base_config.clone() if base_config != null else GenerationConfig.new()
	config.total_layers = max(config.total_layers, 8)
	config.middle_boss_layer = clampi(config.middle_boss_layer, 2, config.total_layers - 2)
	if seed >= 0:
		config.seed = seed
	elif config.seed <= 0:
		config.seed = int(Time.get_unix_time_from_system())
	var quota_delta := _regular_slot_count(config) - _quota_total(config.room_quotas)
	config.room_quotas[MapTypes.RoomType.BATTLE] = max(0, int(config.room_quotas.get(MapTypes.RoomType.BATTLE, 0)) + quota_delta)
	return config


func _build_empty_run(config: GenerationConfig) -> RunData:
	var run := RunData.new()
	run.seed = config.seed
	run.config = config
	var next_id := 0
	for layer_index in range(config.total_layers):
		var layer := LayerData.new()
		layer.index = layer_index
		var width := config.layer_width(layer_index)
		for slot_index in range(width):
			var room := RoomNode.new()
			room.id = next_id
			room.layer_index = layer_index
			room.slot_index = slot_index
			room.room_type = _fixed_room_type_for_layer(config, layer_index)
			run.nodes_by_id[room.id] = room
			layer.node_ids.append(room.id)
			if room.room_type == MapTypes.RoomType.START:
				run.start_node_id = room.id
			elif room.room_type == MapTypes.RoomType.MIDDLE_BOSS:
				run.middle_boss_node_id = room.id
			elif room.room_type == MapTypes.RoomType.FINAL_BOSS:
				run.final_boss_node_id = room.id
			next_id += 1
		run.layers.append(layer)
	return run


func _fixed_room_type_for_layer(config: GenerationConfig, layer_index: int) -> int:
	if layer_index == 0:
		return MapTypes.RoomType.START
	if layer_index == config.middle_boss_layer:
		return MapTypes.RoomType.MIDDLE_BOSS
	if layer_index == config.final_layer():
		return MapTypes.RoomType.FINAL_BOSS
	return MapTypes.RoomType.BATTLE


func _assign_regular_room_types(run: RunData, config: GenerationConfig, rng: RandomNumberGenerator) -> bool:
	var remaining := config.room_quotas.duplicate(true)
	for layer_index in config.regular_layer_indices():
		var layer_counts := {}
		var rooms := run.nodes_in_layer(layer_index)
		var slot_order: Array = []
		for index in range(rooms.size()):
			slot_order.append(index)
		_shuffle_array(slot_order, rng)
		for order_index in slot_order:
			var room: RoomNode = rooms[order_index] as RoomNode
			var candidates := _weighted_candidates(run, config, room, layer_counts, remaining)
			if candidates.is_empty():
				return false
			room.room_type = _pick_weighted_type(candidates, rng)
			remaining[room.room_type] = int(remaining.get(room.room_type, 0)) - 1
			layer_counts[room.room_type] = int(layer_counts.get(room.room_type, 0)) + 1
	return true


func _assign_fallback_room_types(run: RunData, config: GenerationConfig) -> void:
	var remaining := config.room_quotas.duplicate(true)
	for layer_index in config.regular_layer_indices():
		var layer_counts := {}
		for room in run.nodes_in_layer(layer_index):
			var room_node := room as RoomNode
			var replacement := _first_fallback_type(run, config, room_node, layer_counts, remaining)
			if replacement == -1:
				replacement = MapTypes.RoomType.BATTLE
			room_node.room_type = replacement
			remaining[replacement] = int(remaining.get(replacement, 0)) - 1
			layer_counts[replacement] = int(layer_counts.get(replacement, 0)) + 1


func _first_fallback_type(run: RunData, config: GenerationConfig, room: RoomNode, layer_counts: Dictionary, remaining: Dictionary) -> int:
	for room_type in _fallback_priority(room.layer_index, config):
		if int(remaining.get(room_type, 0)) <= 0:
			continue
		if _is_room_type_legal_for_slot(run, config, room.layer_index, room_type, layer_counts):
			return room_type
	return -1


func _fallback_priority(layer_index: int, config: GenerationConfig) -> Array:
	var phase := _phase_for_layer(layer_index, config)
	if layer_index == config.middle_boss_layer - 1:
		return [
			MapTypes.RoomType.ELITE,
			MapTypes.RoomType.BATTLE,
			MapTypes.RoomType.EVENT,
			MapTypes.RoomType.TREASURE,
			MapTypes.RoomType.SHOP,
			MapTypes.RoomType.REST,
		]
	if layer_index == config.middle_boss_layer + 1:
		return [
			MapTypes.RoomType.REST,
			MapTypes.RoomType.SHOP,
			MapTypes.RoomType.BATTLE,
			MapTypes.RoomType.EVENT,
			MapTypes.RoomType.TREASURE,
			MapTypes.RoomType.ELITE,
		]
	if phase == "early":
		return [
			MapTypes.RoomType.TREASURE,
			MapTypes.RoomType.EVENT,
			MapTypes.RoomType.BATTLE,
			MapTypes.RoomType.SHOP,
			MapTypes.RoomType.REST,
			MapTypes.RoomType.ELITE,
		]
	if phase == "late":
		return [
			MapTypes.RoomType.ELITE,
			MapTypes.RoomType.BATTLE,
			MapTypes.RoomType.EVENT,
			MapTypes.RoomType.REST,
			MapTypes.RoomType.SHOP,
			MapTypes.RoomType.TREASURE,
		]
	return [
		MapTypes.RoomType.BATTLE,
		MapTypes.RoomType.SHOP,
		MapTypes.RoomType.REST,
		MapTypes.RoomType.EVENT,
		MapTypes.RoomType.ELITE,
		MapTypes.RoomType.TREASURE,
	]


func _weighted_candidates(run: RunData, config: GenerationConfig, room: RoomNode, layer_counts: Dictionary, remaining: Dictionary) -> Dictionary:
	var weights := {}
	for room_type in MapTypes.REGULAR_TYPES:
		if int(remaining.get(room_type, 0)) <= 0:
			continue
		if not _is_room_type_legal_for_slot(run, config, room.layer_index, room_type, layer_counts):
			continue
		var weight := _room_type_weight(room_type, room.layer_index, config)
		weight *= 1.0 + float(remaining[room_type]) * 0.12
		weights[room_type] = max(weight, 0.05)
	return weights


func _room_type_weight(room_type: int, layer_index: int, config: GenerationConfig) -> float:
	var phase := _phase_for_layer(layer_index, config)
	var phase_table: Dictionary = config.phase_weights.get(phase, {})
	var weight := float(phase_table.get(room_type, 1.0))
	if layer_index == config.middle_boss_layer - 1:
		if room_type == MapTypes.RoomType.ELITE:
			weight *= 1.3
		if room_type == MapTypes.RoomType.BATTLE:
			weight *= 1.2
	if layer_index == config.middle_boss_layer + 1:
		if room_type == MapTypes.RoomType.REST or room_type == MapTypes.RoomType.SHOP:
			weight *= 1.4
	if layer_index == config.final_layer() - 1:
		if room_type == MapTypes.RoomType.ELITE or room_type == MapTypes.RoomType.BATTLE:
			weight *= 1.35
	return weight


func _phase_for_layer(layer_index: int, config: GenerationConfig) -> String:
	if layer_index < config.middle_boss_layer - 1:
		return "early"
	if layer_index <= config.middle_boss_layer + 1:
		return "middle"
	return "late"


func _is_room_type_legal_for_slot(run: RunData, config: GenerationConfig, layer_index: int, room_type: int, layer_counts: Dictionary) -> bool:
	if not MapTypes.is_regular(room_type):
		return false
	if layer_index == 1 and room_type in [MapTypes.RoomType.ELITE, MapTypes.RoomType.SHOP, MapTypes.RoomType.REST]:
		return false
	if layer_index == config.middle_boss_layer - 1 or layer_index == config.final_layer() - 1:
		if room_type in [MapTypes.RoomType.SHOP, MapTypes.RoomType.REST, MapTypes.RoomType.TREASURE]:
			return false
	if room_type == MapTypes.RoomType.TREASURE and layer_index > config.middle_boss_layer + 1:
		return false
	if room_type in [MapTypes.RoomType.ELITE, MapTypes.RoomType.SHOP, MapTypes.RoomType.REST, MapTypes.RoomType.TREASURE]:
		if int(layer_counts.get(room_type, 0)) >= 1:
			return false
	if room_type == MapTypes.RoomType.EVENT and int(layer_counts.get(room_type, 0)) >= 1:
		return false
	if room_type == MapTypes.RoomType.SHOP and _layer_contains_type(run, layer_index - 1, MapTypes.RoomType.SHOP):
		return false
	if room_type == MapTypes.RoomType.REST and _layer_contains_type(run, layer_index - 1, MapTypes.RoomType.REST):
		return false
	return true


func _is_room_type_legal_in_run(run: RunData, config: GenerationConfig, room: RoomNode) -> bool:
	var layer_counts := _layer_room_counts(run, room.layer_index)
	if not _is_room_type_legal_for_slot(run, config, room.layer_index, room.room_type, {}):
		return false
	if room.room_type in [MapTypes.RoomType.ELITE, MapTypes.RoomType.SHOP, MapTypes.RoomType.REST, MapTypes.RoomType.TREASURE]:
		return int(layer_counts.get(room.room_type, 0)) <= 1
	if room.room_type == MapTypes.RoomType.EVENT:
		return int(layer_counts.get(room.room_type, 0)) <= 1
	return true


func _generate_connections(run: RunData, config: GenerationConfig, rng: RandomNumberGenerator) -> void:
	_clear_connections(run)
	for layer_index in range(config.final_layer()):
		var current_layer := run.nodes_in_layer(layer_index)
		var next_layer := run.nodes_in_layer(layer_index + 1)
		if current_layer.size() == 1:
			var single: RoomNode = current_layer[0] as RoomNode
			for target in next_layer:
				_connect(single, target as RoomNode)
			continue
		if next_layer.size() == 1:
			var boss_target: RoomNode = next_layer[0] as RoomNode
			for source in current_layer:
				_connect(source as RoomNode, boss_target)
			continue
		for source in current_layer:
			var room: RoomNode = source as RoomNode
			var candidates := _candidate_targets_for_room(room, next_layer)
			var primary: RoomNode = candidates[rng.randi_range(0, candidates.size() - 1)] as RoomNode
			_connect(room, primary)
			var extras := candidates.duplicate()
			extras.erase(primary)
			_shuffle_array(extras, rng)
			if not extras.is_empty() and rng.randf() < 0.45:
				_connect(room, extras[0] as RoomNode)
			if room.slot_index == 1 and room.outgoing.size() < config.max_outgoing and extras.size() > 1 and rng.randf() < 0.25:
				_connect(room, extras[1] as RoomNode)


func _repair_connections(run: RunData, config: GenerationConfig, _rng: RandomNumberGenerator) -> void:
	for layer_index in range(config.final_layer()):
		var current_layer := run.nodes_in_layer(layer_index)
		var next_layer := run.nodes_in_layer(layer_index + 1)
		for source in current_layer:
			var room: RoomNode = source as RoomNode
			if room.outgoing.is_empty():
				_connect(room, _closest_room(next_layer, room.slot_index))
			while room.outgoing.size() > config.max_outgoing:
				var target := run.node(room.outgoing.back())
				_disconnect(room, target)
		for target in next_layer:
			var next_room: RoomNode = target as RoomNode
			if next_room.incoming.is_empty():
				_connect(_closest_room(current_layer, next_room.slot_index), next_room)
	var reachable := _reachable_from_start(run)
	for layer_index in range(1, config.total_layers):
		if layer_index == 0:
			continue
		for room in run.nodes_in_layer(layer_index):
			var node: RoomNode = room as RoomNode
			if reachable.has(node.id):
				continue
			var previous_layer := run.nodes_in_layer(layer_index - 1)
			var source := _closest_reachable_room(previous_layer, node.slot_index, reachable)
			_connect(source, node)
			reachable = _reachable_from_start(run)
	var can_reach_final := _reachable_to_final(run)
	for layer_index in range(config.final_layer() - 1, -1, -1):
		for room in run.nodes_in_layer(layer_index):
			var node: RoomNode = room as RoomNode
			if can_reach_final.has(node.id) or layer_index == config.final_layer():
				continue
			var next_layer := run.nodes_in_layer(layer_index + 1)
			var target := _closest_reverse_reachable_room(next_layer, node.slot_index, can_reach_final)
			_connect(node, target)
			can_reach_final = _reachable_to_final(run)


func _candidate_targets_for_room(room: RoomNode, next_layer: Array) -> Array:
	var candidates: Array = []
	for target in next_layer:
		var next_room: RoomNode = target as RoomNode
		if abs(next_room.slot_index - room.slot_index) <= 1:
			candidates.append(next_room)
	if candidates.is_empty():
		candidates = next_layer.duplicate()
	return candidates


func _connect(source: RoomNode, target: RoomNode) -> void:
	if source == null or target == null:
		return
	if target.id not in source.outgoing:
		source.outgoing.append(target.id)
	if source.id not in target.incoming:
		target.incoming.append(source.id)


func _disconnect(source: RoomNode, target: RoomNode) -> void:
	if source == null or target == null:
		return
	source.outgoing.erase(target.id)
	target.incoming.erase(source.id)


func _clear_connections(run: RunData) -> void:
	for room in run.all_nodes():
		(room as RoomNode).outgoing.clear()
		(room as RoomNode).incoming.clear()


func _closest_room(rooms: Array, slot_index: int) -> RoomNode:
	var best: RoomNode = rooms[0] as RoomNode
	var best_distance: int = abs(best.slot_index - slot_index)
	for room in rooms:
		var candidate: RoomNode = room as RoomNode
		var distance: int = abs(candidate.slot_index - slot_index)
		if distance < best_distance:
			best = candidate
			best_distance = distance
	return best


func _closest_reachable_room(rooms: Array, slot_index: int, reachable: Dictionary) -> RoomNode:
	for room in rooms:
		var candidate: RoomNode = room as RoomNode
		if reachable.has(candidate.id):
			return _closest_room(_rooms_matching(rooms, reachable, true), slot_index)
	return rooms[0] as RoomNode


func _closest_reverse_reachable_room(rooms: Array, slot_index: int, reachable: Dictionary) -> RoomNode:
	for room in rooms:
		var candidate: RoomNode = room as RoomNode
		if reachable.has(candidate.id):
			return _closest_room(_rooms_matching(rooms, reachable, true), slot_index)
	return rooms[0] as RoomNode


func _rooms_matching(rooms: Array, flags: Dictionary, expected: bool) -> Array:
	var filtered: Array = []
	for room in rooms:
		var candidate: RoomNode = room as RoomNode
		if flags.has(candidate.id) == expected:
			filtered.append(candidate)
	if filtered.is_empty():
		return rooms
	return filtered


func _reachable_from_start(run: RunData) -> Dictionary:
	var reachable := {}
	var frontier: Array = [run.start_node_id]
	while not frontier.is_empty():
		var node_id: int = frontier.pop_front()
		if reachable.has(node_id):
			continue
		reachable[node_id] = true
		var room := run.node(node_id)
		if room == null:
			continue
		for target_id in room.outgoing:
			if not reachable.has(target_id):
				frontier.append(target_id)
	return reachable


func _reachable_to_final(run: RunData) -> Dictionary:
	var reachable := {}
	var frontier: Array = [run.final_boss_node_id]
	while not frontier.is_empty():
		var node_id: int = frontier.pop_front()
		if reachable.has(node_id):
			continue
		reachable[node_id] = true
		var room := run.node(node_id)
		if room == null:
			continue
		for source_id in room.incoming:
			if not reachable.has(source_id):
				frontier.append(source_id)
	return reachable


func _regular_room_counts(run: RunData) -> Dictionary:
	var counts := {}
	for room_type in MapTypes.REGULAR_TYPES:
		counts[room_type] = 0
	for room in run.all_nodes():
		var room_node: RoomNode = room as RoomNode
		if MapTypes.is_regular(room_node.room_type):
			counts[room_node.room_type] = int(counts.get(room_node.room_type, 0)) + 1
	return counts


func _layer_room_counts(run: RunData, layer_index: int) -> Dictionary:
	var counts := {}
	for room in run.nodes_in_layer(layer_index):
		var room_node: RoomNode = room as RoomNode
		counts[room_node.room_type] = int(counts.get(room_node.room_type, 0)) + 1
	return counts


func _layer_contains_type(run: RunData, layer_index: int, room_type: int) -> bool:
	if layer_index < 0 or layer_index >= run.layers.size():
		return false
	for room in run.nodes_in_layer(layer_index):
		if (room as RoomNode).room_type == room_type:
			return true
	return false


func _pick_weighted_type(weights: Dictionary, rng: RandomNumberGenerator) -> int:
	var total := 0.0
	for weight in weights.values():
		total += float(weight)
	var roll := rng.randf() * total
	for room_type in weights.keys():
		roll -= float(weights[room_type])
		if roll <= 0.0:
			return int(room_type)
	return int(weights.keys().back())


func _regular_slot_count(config: GenerationConfig) -> int:
	return config.regular_layer_indices().size() * config.regular_layer_width


func _quota_total(quotas: Dictionary) -> int:
	var total := 0
	for amount in quotas.values():
		total += int(amount)
	return total


func _shuffle_array(values: Array, rng: RandomNumberGenerator) -> void:
	for index in range(values.size() - 1, 0, -1):
		var swap_index := rng.randi_range(0, index)
		var temp = values[index]
		values[index] = values[swap_index]
		values[swap_index] = temp
