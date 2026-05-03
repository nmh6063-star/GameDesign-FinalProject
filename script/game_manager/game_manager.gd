extends Node

const MapController := preload("res://script/map/map_controller.gd")
const MapGenerator := preload("res://script/map/map_generator.gd")

const MAP_SELECTION_SCENE_PATH := "res://scenes/map/map_selection.tscn"
const BATTLE_SCENE_PATH := "res://scenes/main.tscn"
const CAMPFIRE_SCENE_PATH := "res://scenes/camp_fire.tscn"
const SHOP_SCENE_PATH := "res://scenes/shop.tscn"
const EVENT_SCENE_PATH := "res://scenes/plinko_room.tscn"
const MENU_SCENE_PATH := "res://scenes/menu_screen.tscn"
const PAUSE_MENU_SCENE := preload("res://scenes/pause_menu.tscn")

const _NON_GAME_SCENES := [
	"res://scenes/menu_screen.tscn",
	"res://scenes/tutorial.tscn",
	"res://scenes/tutorial_complete.tscn",
]

const _ROOM_SCENES := [
	BATTLE_SCENE_PATH,
	CAMPFIRE_SCENE_PATH,
	SHOP_SCENE_PATH,
	EVENT_SCENE_PATH,
]

signal run_started(run_data)
signal room_started(room_data)
signal room_completed(room_data)
signal run_reset
signal map_state_changed
signal augment_state_changed

var current_map_data := {}
var map_view_visible := false
var augment_view_visible := false

var _controller := MapController.new()
var _pause_menu: CanvasLayer
var _room_entry_health: int = -1
var _room_rng_seed: int = 0
var _current_room_scene: String = ""
var _pre_map_reward_pending := false


func _ready() -> void:
	_bind_controller()
	if not has_run():
		generate_new_run()


func controller() -> MapController:
	return _controller


func has_run() -> bool:
	return _controller.run_data() != null


func current_seed() -> int:
	return _controller.seed()


func active_room():
	return _controller.current_room()


func active_room_type() -> int:
	return _controller.current_room_type() if has_run() else MapGenerator.Room.Type.START


func generate_new_run(seed: int = -1) -> void:
	BattleLoadout.reset_for_run()
	PlayerState.reset_for_run()
	_pre_map_reward_pending = true
	map_view_visible = false
	_controller.start_new_run(seed)


func start_new_run(seed: int = -1) -> void:
	generate_new_run(seed)


func open_map_selection() -> void:
	_change_scene(MAP_SELECTION_SCENE_PATH)


func current_map_node():
	return _controller.current_room()


func node_by_id(node_id: int):
	return _controller.room_by_id(node_id)


func visited_has(node_id: int) -> bool:
	return _controller.visited_has(node_id)


func completed_has(node_id: int) -> bool:
	return _controller.completed_has(node_id)


func get_current_map_choices() -> Array:
	return _controller.available_choices()


func current_map_choice_target_id() -> int:
	return _controller.selected_path_target_id()


func has_map_choices() -> bool:
	return _controller.has_choices()


func is_map_complete() -> bool:
	return _controller.is_complete()


func shift_map_choice(step: int) -> void:
	_controller.move_selection(step)


func set_map_choice_index(index: int) -> void:
	_controller.select_choice_index(index)


func selected_map_choice_index() -> int:
	return _controller.selected_choice_index()


func current_node_id() -> int:
	return _controller.current_room_id()


func visited_map_node_ids() -> Array:
	return _controller.visited_room_ids()


func completed_map_node_ids() -> Array:
	return _controller.completed_room_ids()


func choose_map_node(choice_index: int = -1):
	if choice_index >= 0:
		_controller.select_choice_index(choice_index)
	var room = _controller.confirm_selection()
	if room == null:
		return null
	var scene_path := _scene_for_room(room)
	_save_room_entry_state(scene_path)
	_change_scene(scene_path)
	return room


func enter_selected_room():
	return choose_map_node()


func mark_current_room_complete() -> void:
	_controller.mark_current_room_complete()


func complete_current_room() -> void:
	var room = active_room()
	if room == null:
		return
	_controller.mark_current_room_complete()
	room_completed.emit(_room_payload(room))
	open_map_selection()


func restart_run(seed: int = -1) -> void:
	generate_new_run(seed if seed >= 0 else current_seed())
	run_reset.emit()
	open_map_selection()


func should_skip_battle_rewards() -> bool:
	return true


func get_stage_enemy_ids(row: int) -> Array:
	if row >= 7:
		return ["enemy_small_spider", "enemy_spider_queen", "enemy_small_spider"]
	if row >= 4:
		return ["enemy_fire", "enemy_fire", "enemy_ice"]
	return ["enemy1", "enemy2", ""]


func consume_pre_map_reward_pending() -> bool:
	var pending := _pre_map_reward_pending
	_pre_map_reward_pending = false
	return pending


func get_room_rng_seed() -> int:
	return _room_rng_seed


func restart_current_room() -> void:
	if _current_room_scene.is_empty():
		return
	if _room_entry_health >= 0:
		PlayerState.player_health = _room_entry_health
	get_tree().change_scene_to_file(_current_room_scene)


func exit_to_menu() -> void:
	_current_room_scene = ""
	get_tree().change_scene_to_file(MENU_SCENE_PATH)


func toggle_map_view() -> bool:
	map_view_visible = not map_view_visible
	map_state_changed.emit()
	return map_view_visible

func toggle_augment_view() -> bool:
	augment_view_visible = not augment_view_visible
	augment_state_changed.emit()
	return augment_view_visible


func _save_room_entry_state(scene_path: String) -> void:
	_room_entry_health = PlayerState.player_health
	_room_rng_seed = randi()
	_current_room_scene = scene_path


func _ensure_pause_menu() -> void:
	if _pause_menu != null and is_instance_valid(_pause_menu):
		return
	_pause_menu = PAUSE_MENU_SCENE.instantiate()
	_pause_menu.restart_requested.connect(_on_pause_restart)
	_pause_menu.title_requested.connect(_on_pause_title)
	_pause_menu.exit_requested.connect(_on_pause_exit)
	add_child(_pause_menu)


func _show_pause_menu(in_room: bool, in_game: bool = true, can_restart: bool = true) -> void:
	_ensure_pause_menu()
	_pause_menu.show_menu(in_room, in_game, can_restart)


func _on_pause_restart() -> void:
	restart_current_room()


func _on_pause_title() -> void:
	exit_to_menu()


func _on_pause_exit() -> void:
	get_tree().quit()


func _scene_for_room(room) -> String:
	if room == null:
		return BATTLE_SCENE_PATH
	match room.type:
		MapGenerator.Room.Type.CAMPFIRE:
			return CAMPFIRE_SCENE_PATH
		MapGenerator.Room.Type.SHOP:
			return SHOP_SCENE_PATH
		MapGenerator.Room.Type.EVENT:
			return EVENT_SCENE_PATH
		_:
			return BATTLE_SCENE_PATH


func _change_scene(scene_path: String) -> void:
	var tree := get_tree()
	var current := tree.current_scene
	if current != null and current.scene_file_path == scene_path:
		map_state_changed.emit()
		return
	tree.change_scene_to_file(scene_path)


func _bind_controller() -> void:
	var run_callback := Callable(self, "_on_controller_run_started")
	if not _controller.run_started.is_connected(run_callback):
		_controller.run_started.connect(run_callback)
	var state_callback := Callable(self, "_on_controller_state_changed")
	if not _controller.state_changed.is_connected(state_callback):
		_controller.state_changed.connect(state_callback)
	var room_callback := Callable(self, "_on_controller_room_entered")
	if not _controller.room_entered.is_connected(room_callback):
		_controller.room_entered.connect(room_callback)


func _on_controller_run_started(run_data) -> void:
	current_map_data = run_data.to_dictionary()
	run_started.emit(current_map_data)


func _on_controller_state_changed() -> void:
	_sync_map_snapshot()
	map_state_changed.emit()


func _on_controller_room_entered(room) -> void:
	room_started.emit(_room_payload(room))


func _sync_map_snapshot() -> void:
	if _controller.run_data() == null:
		current_map_data = {}
		return
	current_map_data = _controller.run_data().to_dictionary()


func _room_payload(room) -> Dictionary:
	return room.to_dictionary() if room != null and room.has_method("to_dictionary") else {}


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	var scene := get_tree().current_scene
	if scene == null:
		return
	if event.keycode == KEY_ESCAPE:
		var in_room := scene.scene_file_path in _ROOM_SCENES
		var in_game := scene.scene_file_path not in _NON_GAME_SCENES
		var can_restart := in_room and scene.scene_file_path != EVENT_SCENE_PATH
		_show_pause_menu(in_room, in_game, can_restart)
		return
	if scene.scene_file_path in _NON_GAME_SCENES:
		return
	if event.keycode == KEY_P and scene.scene_file_path == BATTLE_SCENE_PATH:
		var battle := scene.get_node_or_null("BallHolder/BattleController")
		if battle != null and battle.has_method("skip_to_post_battle_reward"):
			battle.skip_to_post_battle_reward()
		return
	if event.keycode == KEY_P and scene.scene_file_path in _ROOM_SCENES:
		complete_current_room()
		return
	if event.keycode == KEY_T:
		PlayerState.apply_test_current_abilities_set()
