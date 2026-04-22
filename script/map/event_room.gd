extends Node2D

const TAKE_GOLD := 66
const PLAY_COST := 99
const DROP_COST := 15

const PEG_ROWS := 12
const PEG_START_COUNT := 3
const PEG_SPACING_X := 48.0
const PEG_SPACING_Y := 38.0
const PEG_RADIUS := 5.0
const BALL_RADIUS := 7.0
const BALL_GROUP := "plinko_ball"

const BOARD_CENTER_X := 576.0
const BOARD_TOP_Y := 90.0

const SLOT_VALUES := [1000, 200, 30, 20, 10, 5, 2, 1, 2, 5, 10, 20, 30, 200, 1000]
const SLOT_COLORS := [
	Color(0.95, 0.15, 0.15), Color(0.95, 0.3, 0.1), Color(0.95, 0.5, 0.1),
	Color(0.9, 0.65, 0.1), Color(0.85, 0.75, 0.15), Color(0.7, 0.8, 0.2),
	Color(0.5, 0.8, 0.3), Color(0.3, 0.75, 0.3),
	Color(0.5, 0.8, 0.3), Color(0.7, 0.8, 0.2), Color(0.85, 0.75, 0.15),
	Color(0.9, 0.65, 0.1), Color(0.95, 0.5, 0.1), Color(0.95, 0.3, 0.1),
	Color(0.95, 0.15, 0.15),
]

const PEG_JITTER := 3.0
const BALL_DROP_IMPULSE_X := 40.0
const CENTER_PULL := 0.5

const SLOT_WIDTH_MULTS := [0.5, 0.65, 0.85, 1.0, 1.05, 1.1, 1.15, 1.2, 1.15, 1.1, 1.05, 1.0, 0.85, 0.65, 0.5]

const SPECIAL_GIFT_GOLD := 2000
const SPECIAL_GIFT_HEAL := true
const SPECIAL_GIFT_HALF_WIDTH := 8.0
const FONT := preload("res://assets/dogica/TTF/dogicapixelbold.ttf")

@onready var _conversation_ui := $ConversationUI as CanvasLayer
@onready var _plinko_world := $PlinkoWorld as Node2D
@onready var _plinko_ui := $PlinkoUI as CanvasLayer
@onready var _gold_info := $ConversationUI/Center/VBox/GoldInfo as Label
@onready var _play_button := $ConversationUI/Center/VBox/PlayButton as TextureButton
@onready var _play_label := $ConversationUI/Center/VBox/PlayButton/Label as Label
@onready var _earnings_label := $PlinkoUI/EarningsLabel as Label
@onready var _gold_label := $PlinkoUI/GoldLabel as Label
@onready var _win_label := $PlinkoUI/WinLabel as Label

var _net_earnings := 0
var _board_built := false
var _slot_y := 0.0
var _slot_left_x := 0.0
var _slot_count := 0
var _slot_xs: Array[float] = []
var _slot_ws: Array[float] = []
var _special_gift_center_x := 0.0
var _special_gift_collected := false
var _drop_min_x := 0.0
var _drop_max_x := 0.0
var _ball_texture: ImageTexture
var _gift_sprite: Sprite2D
var _kicking_out := false


func _ready() -> void:
	_gold_info.text = "Your Gold: %d" % PlayerState.player_gold
	_update_play_button()
	_ball_texture = _make_circle_texture(int(BALL_RADIUS), Color(1.0, 0.25, 0.3))


func _update_play_button() -> void:
	var can_play := PlayerState.player_gold >= PLAY_COST
	_play_button.disabled = not can_play
	_play_label.modulate = Color(1, 1, 1, 1) if can_play else Color(1, 1, 1, 0.4)


func _on_take_gold() -> void:
	PlayerState.add_gold(TAKE_GOLD)
	GameManager.complete_current_room()


func _on_play_plinko() -> void:
	if not PlayerState.spend_gold(PLAY_COST):
		return
	_conversation_ui.visible = false
	_plinko_world.visible = true
	_plinko_ui.visible = true
	if not _board_built:
		_build_board()
		_board_built = true
	_sync_ui()


func _on_leave() -> void:
	GameManager.complete_current_room()


func _physics_process(_delta: float) -> void:
	if not _plinko_world.visible:
		return
	for ball in get_tree().get_nodes_in_group(BALL_GROUP):
		if not (ball is RigidBody2D):
			continue
		var rb := ball as RigidBody2D
		if rb.position.y >= _slot_y:
			_resolve_ball(rb)
		else:
			var dist := rb.position.x - BOARD_CENTER_X
			rb.apply_central_force(Vector2(-dist * CENTER_PULL, 0))
	if _kicking_out:
		return
	if PlayerState.player_gold < DROP_COST and get_tree().get_nodes_in_group(BALL_GROUP).is_empty():
		_kick_out()


func _unhandled_input(event: InputEvent) -> void:
	if not _plinko_world.visible:
		return
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	if PlayerState.player_gold < DROP_COST:
		return
	var mouse_pos := get_global_mouse_position()
	if mouse_pos.y > BOARD_TOP_Y - 10:
		return
	var drop_x := clampf(mouse_pos.x, _drop_min_x, _drop_max_x)
	_drop_ball(Vector2(drop_x, BOARD_TOP_Y - 25.0))


func _drop_ball(pos: Vector2) -> void:
	PlayerState.spend_gold(DROP_COST)
	_net_earnings -= DROP_COST
	_sync_ui()

	var ball := RigidBody2D.new()
	ball.position = pos
	ball.gravity_scale = 1.0
	ball.add_to_group(BALL_GROUP)
	ball.physics_material_override = PhysicsMaterial.new()
	ball.physics_material_override.bounce = 0.5
	ball.physics_material_override.friction = 0.2
	ball.continuous_cd = RigidBody2D.CCD_MODE_CAST_RAY

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = BALL_RADIUS
	shape.shape = circle
	ball.add_child(shape)

	var sprite := Sprite2D.new()
	sprite.texture = _ball_texture
	ball.add_child(sprite)

	_plinko_world.add_child(ball)
	ball.apply_central_impulse(Vector2(randf_range(-BALL_DROP_IMPULSE_X, BALL_DROP_IMPULSE_X), 0))


func _resolve_ball(ball: RigidBody2D) -> void:
	var bx := ball.position.x
	var board_left := _slot_xs[0] if not _slot_xs.is_empty() else 0.0
	var board_right := _slot_xs[_slot_count - 1] + _slot_ws[_slot_count - 1] if _slot_count > 0 else 0.0

	if bx < board_left or bx > board_right:
		_show_win("Lost!")
		ball.queue_free()
		_sync_ui()
		return

	if not _special_gift_collected and absf(bx - _special_gift_center_x) < SPECIAL_GIFT_HALF_WIDTH:
		_collect_special_gift()
		ball.queue_free()
		return

	var slot_index := _slot_index_for_x(bx)
	var value: int = int(SLOT_VALUES[slot_index]) if slot_index < SLOT_VALUES.size() else 1
	PlayerState.add_gold(value)
	_net_earnings += value
	_show_win("+%d" % value)
	ball.queue_free()
	_sync_ui()


func _slot_index_for_x(bx: float) -> int:
	for i in range(_slot_count):
		if bx < _slot_xs[i] + _slot_ws[i]:
			return i
	return _slot_count - 1


func _collect_special_gift() -> void:
	_special_gift_collected = true
	_show_win("???")
	if _gift_sprite != null:
		_gift_sprite.visible = false
	_sync_ui()


func _show_win(text: String) -> void:
	_win_label.text = text
	_win_label.modulate = Color(1, 0.9, 0.2, 1)
	var tween := create_tween()
	tween.tween_property(_win_label, "modulate:a", 0.0, 1.5)


func _kick_out() -> void:
	_kicking_out = true
	await get_tree().create_timer(1.0).timeout
	if not is_inside_tree():
		return
	GameManager.complete_current_room()


func _sync_ui() -> void:
	var sign_str := "+" if _net_earnings >= 0 else ""
	_earnings_label.text = "Earnings: %s%d" % [sign_str, _net_earnings]
	_earnings_label.modulate = Color(0.3, 1.0, 0.4) if _net_earnings >= 0 else Color(1.0, 0.35, 0.3)
	_gold_label.text = "Gold: %d" % PlayerState.player_gold


# ---------------------------------------------------------------------------
#  Procedural board construction (pegs must be generated — triangle pattern)
# ---------------------------------------------------------------------------

func _build_board() -> void:
	var bottom_count := PEG_START_COUNT + PEG_ROWS - 1
	var board_half_width := (bottom_count - 1) * PEG_SPACING_X / 2.0

	_slot_count = bottom_count + 1
	_slot_left_x = BOARD_CENTER_X - board_half_width - PEG_SPACING_X / 2.0
	_slot_y = BOARD_TOP_Y + PEG_ROWS * PEG_SPACING_Y + 10.0
	_special_gift_center_x = BOARD_CENTER_X

	var total_board_width := float(_slot_count) * PEG_SPACING_X
	var mult_sum := 0.0
	for m in SLOT_WIDTH_MULTS:
		mult_sum += float(m)
	_slot_xs.clear()
	_slot_ws.clear()
	var cx := _slot_left_x
	for i in range(_slot_count):
		var mult: float = float(SLOT_WIDTH_MULTS[i]) if i < SLOT_WIDTH_MULTS.size() else 1.0
		var w := mult / mult_sum * total_board_width
		_slot_xs.append(cx)
		_slot_ws.append(w)
		cx += w

	var drop_half := PEG_SPACING_X
	_drop_min_x = BOARD_CENTER_X - drop_half
	_drop_max_x = BOARD_CENTER_X + drop_half

	var peg_tex := _make_circle_texture(int(PEG_RADIUS), Color(0.85, 0.82, 0.9))
	for row in range(PEG_ROWS):
		var count := PEG_START_COUNT + row
		var row_width := (count - 1) * PEG_SPACING_X
		var start_x := BOARD_CENTER_X - row_width / 2.0
		var y := BOARD_TOP_Y + row * PEG_SPACING_Y
		for c in range(count):
			var jitter := Vector2(randf_range(-PEG_JITTER, PEG_JITTER), randf_range(-PEG_JITTER, PEG_JITTER))
			_add_peg(Vector2(start_x + c * PEG_SPACING_X, y) + jitter, peg_tex)

	_add_walls(board_half_width)
	_add_slot_dividers(board_half_width)
	_add_slot_visuals()
	_add_gift_visual()
	_add_drop_zone_visual()


func _add_peg(pos: Vector2, tex: ImageTexture) -> void:
	var body := StaticBody2D.new()
	body.position = pos
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = PEG_RADIUS
	shape.shape = circle
	body.add_child(shape)
	var sprite := Sprite2D.new()
	sprite.texture = tex
	body.add_child(sprite)
	_plinko_world.add_child(body)


func _add_walls(half_w: float) -> void:
	var left_x := BOARD_CENTER_X - half_w - PEG_SPACING_X / 2.0
	var right_x := BOARD_CENTER_X + half_w + PEG_SPACING_X / 2.0
	var bot_y := _slot_y + 50.0
	_add_wall(Vector2(left_x - 2, bot_y), Vector2(right_x - left_x + 4, 6))


func _add_wall(pos: Vector2, sz: Vector2) -> void:
	var body := StaticBody2D.new()
	body.position = pos + sz / 2.0
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = sz
	shape.shape = rect
	body.add_child(shape)
	_plinko_world.add_child(body)


func _add_slot_dividers(_half_w: float) -> void:
	for i in range(1, _slot_count):
		var body := StaticBody2D.new()
		body.position = Vector2(_slot_xs[i], _slot_y + 22.0)
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(3, 44)
		shape.shape = rect
		body.add_child(shape)
		_plinko_world.add_child(body)


func _add_slot_visuals() -> void:
	for i in range(mini(_slot_count, SLOT_VALUES.size())):
		var sx: float = _slot_xs[i]
		var sw: float = _slot_ws[i]
		var bg := ColorRect.new()
		bg.position = Vector2(sx, _slot_y)
		bg.size = Vector2(sw, 44)
		bg.color = Color(SLOT_COLORS[i]).darkened(0.55)
		_plinko_world.add_child(bg)

		var label := Label.new()
		label.text = str(int(SLOT_VALUES[i]))
		label.position = Vector2(sx, _slot_y + 12)
		label.size = Vector2(sw, 20)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_override("font", FONT)
		label.add_theme_font_size_override("font_size", 9)
		label.add_theme_color_override("font_color", Color(SLOT_COLORS[i]))
		_plinko_world.add_child(label)


func _add_gift_visual() -> void:
	_gift_sprite = Sprite2D.new()
	_gift_sprite.texture = _make_circle_texture(14, Color(1.0, 0.8, 0.0))
	_gift_sprite.position = Vector2(_special_gift_center_x, _slot_y + 15.0)
	_plinko_world.add_child(_gift_sprite)

	var label := Label.new()
	label.text = "?"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.position = Vector2(-10, -10)
	label.size = Vector2(20, 20)
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(0.4, 0.2, 0.0))
	_gift_sprite.add_child(label)

	_animate_gift_bob()


func _animate_gift_bob() -> void:
	if _gift_sprite == null:
		return
	var base_y := _gift_sprite.position.y
	var tween := create_tween().set_loops()
	tween.tween_property(_gift_sprite, "position:y", base_y - 6.0, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_gift_sprite, "position:y", base_y + 6.0, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _add_drop_zone_visual() -> void:
	var zone := ColorRect.new()
	zone.position = Vector2(_drop_min_x, BOARD_TOP_Y - 30.0)
	zone.size = Vector2(_drop_max_x - _drop_min_x, 8)
	zone.color = Color(1, 1, 1, 0.12)
	_plinko_world.add_child(zone)


func _make_circle_texture(radius: int, color: Color) -> ImageTexture:
	var size := radius * 2 + 2
	var center := Vector2(size / 2.0, size / 2.0)
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	for y in range(size):
		for x in range(size):
			if Vector2(x + 0.5, y + 0.5).distance_to(center) <= float(radius):
				image.set_pixel(x, y, color)
	return ImageTexture.create_from_image(image)
