extends Node2D
## Main battle scene controller: turn flow hooks, ball spawning, and UI wiring.
## Scene layout matches tutorial-style separation — EnemyHandler / PlayerHandler / Player / UI.

const GameBall := preload("res://script/ball/game_ball.gd")

@onready var template_ball: Node = $Ball
@onready var turn_banner := $UI/TurnBanner
@onready var player_fill := $UI/PlayerHealthBar/Fill
@onready var player_hp_top := $UI/TopBar/PlayerHPText
@onready var energy_label := get_node_or_null("UI/EnergyLabel")
@onready var energy_badge_text := get_node_or_null("UI/CostBadge/CostText")
@onready var result_label := $UI/ResultLabel
@onready var game_manager := $GameManager
@onready var enemy_node := $EnemyHandler/Enemy
@onready var player_damage_anchor := $UI/PlayerHealthBar
@onready var damage_anchor_player := get_node_or_null("DamageAnchorPlayer")
@onready var damage_anchor_enemy := get_node_or_null("DamageAnchorEnemy")

var spawn_position: Vector2


func _ready() -> void:
	randomize()
	spawn_position = (template_ball as Node2D).position
	template_ball.connect("dropped", _on_ball_dropped)
	((template_ball as Node).get_node("CollisionShape2D") as CollisionShape2D).disabled = true
	game_manager.attack_calculated.connect(_on_attack_calculated)
	enemy_node.player_attacked.connect(_on_player_attacked)
	game_manager.player_healed.connect(_on_player_healed)
	game_manager.turn_ended.connect(_on_turn_ended)
	game_manager.energy_changed.connect(_on_energy_changed)
	if game_manager.has_signal("enemy_turn_started"):
		game_manager.enemy_turn_started.connect(_on_enemy_turn_started)
	if game_manager.has_signal("player_turn_started"):
		game_manager.player_turn_started.connect(_on_player_turn_started)
	if enemy_node and enemy_node.has_signal("damaged"):
		enemy_node.damaged.connect(_on_enemy_damaged)
	game_manager.game_over.connect(_on_game_over)
	game_manager.game_clear.connect(_on_game_clear)
	_update_player_bar()
	update_energy_ui()
	result_label.visible = false
	ensure_ball_in_play()
	_show_turn_banner("PLAYER TURN")


func _on_draw_pressed() -> void:
	$PlayerHandler/CardManager.draw()
	var box_out := get_node_or_null("BoxOut")
	if box_out != null and box_out.has_method("rotate_cup"):
		box_out.rotate_cup()


func _on_finish_turn_pressed() -> void:
	game_manager.finish_turn()


func _on_ball_dropped() -> void:
	if Global.phase != Global.Phase.PLAY:
		return
	await get_tree().create_timer(1.0).timeout
	$PlayerHandler/CardManager.cardPlay = true
	_spawn_ball()


func wire_playfield_ball(b: GameBall) -> void:
	if not b.dropped.is_connected(_on_ball_dropped):
		b.dropped.connect(_on_ball_dropped)


func _on_player_healed(_amount: int) -> void:
	_update_player_bar()


func _spawn_ball() -> void:
	var b := template_ball.duplicate() as GameBall
	Global.ballInPlay = b
	(b as Node2D).position = spawn_position
	b.reset_for_spawn()
	b.set_up = false
	b.visible = false
	b.gravity_scale = 0.0
	((b as Node).get_node("CollisionShape2D") as CollisionShape2D).disabled = false
	wire_playfield_ball(b)
	add_child(b)


func ensure_ball_in_play() -> void:
	if Global.phase != Global.Phase.PLAY:
		return
	if is_instance_valid(Global.ballInPlay) and Global.ballInPlay != template_ball:
		return
	_spawn_ball()


func _on_turn_ended() -> void:
	$PlayerHandler/CardManager.cardPlay = true
	ensure_ball_in_play()
	_show_turn_banner("PLAYER TURN")


func _on_enemy_turn_started() -> void:
	_show_turn_banner("ENEMY TURN")


func _on_player_turn_started() -> void:
	_show_turn_banner("PLAYER TURN")


func _on_attack_calculated(amount: int) -> void:
	pass


func _on_player_attacked(_amount: int) -> void:
	$Player._flash()
	_update_player_bar()
	if damage_anchor_player:
		_spawn_damage_floater_on_node(_amount, damage_anchor_player, Color(1, 0.3, 0.3))
	else:
		_spawn_damage_floater_on_node(_amount, player_damage_anchor, Color(1, 0.3, 0.3))


func _on_enemy_damaged(amount: int) -> void:
	$EnemyHandler/Enemy._flash()
	if damage_anchor_enemy:
		_spawn_damage_floater_on_node(amount, damage_anchor_enemy, Color(0.92, 0.58, 0.06))
	else:
		_spawn_damage_floater_on_node(amount, enemy_node, Color(0.92, 0.58, 0.06))


func _on_energy_changed(_current: int, _max: int) -> void:
	update_energy_ui()


func _spawn_damage_floater_on_node(amount: int, target: Node, color: Color) -> void:
	if amount <= 0 or target == null:
		return
	var floater := preload("res://scenes/damage_floater.tscn").instantiate()
	$UI.add_child(floater)
	var pos := Vector2.ZERO
	if target is Node2D:
		pos = (target as Node2D).global_position
	elif target is Control:
		pos = (target as Control).global_position
	(floater as Label).global_position = pos
	if floater.has_method("play"):
		floater.play(amount, color)


func _show_turn_banner(text: String) -> void:
	if turn_banner == null:
		return
	var label := turn_banner.get_node_or_null("Label") as Label
	if label:
		label.text = text
	turn_banner.visible = true
	turn_banner.modulate.a = 0.0
	turn_banner.scale = Vector2(1.0, 1.0)
	var tween := create_tween()
	tween.tween_property(turn_banner, "modulate:a", 0.7, 0.15)
	tween.tween_property(turn_banner, "modulate:a", 0.0, 0.6).set_delay(0.6)
	tween.tween_callback(func(): turn_banner.visible = false)


func _update_player_bar() -> void:
	player_fill.size.x = 100.0 * float(Global.player_health) / float(Global.player_max_health)
	var hp_text := $UI/PlayerHealthBar/HPText
	if hp_text:
		hp_text.text = "%d/%d" % [Global.player_health, Global.player_max_health]
	if player_hp_top:
		player_hp_top.text = "%d/%d" % [Global.player_health, Global.player_max_health]


func update_energy_ui() -> void:
	if energy_label:
		energy_label.visible = true
		energy_label.text = "Energy"
	if energy_badge_text:
		energy_badge_text.text = "%d/%d" % [Global.player_energy, Global.player_energy_max]


func _on_game_over() -> void:
	_show_result("Game Over")


func _on_game_clear() -> void:
	_show_result("Game Clear")


func _show_result(text: String) -> void:
	result_label.text = text
	result_label.visible = true
	$UI/ActionBar/FinishTurnButton.disabled = true
	$UI/ActionBar/DrawButton.disabled = true
	$PlayerHandler/CardManager.cardPlay = false
