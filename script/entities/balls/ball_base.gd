extends RigidBody2D
class_name BallBase

const BattleContext := preload("res://script/battle/core/battle_context.gd")
const BallCatalog := preload("res://script/entities/balls/ball_catalog.gd")
const BallData := preload("res://script/entities/balls/ball_data.gd")
const GRAVITY_SCALE := 2.0
const OUTLINE_WIDTH := 2.0
const OUTLINE_POINTS := 64

signal dropped

@export var data: BallData

var battle_context: BattleContext
var aim_target: Node2D
var set_up := false
var level := 1
var ui_preview := false


func _ready() -> void:
	if ui_preview:
		gravity_scale = 0.0
		contact_monitor = false
		set_collision_enabled(false)
		set_physics_process(false)
	else:
		add_to_group("ball")
		gravity_scale = 0.0
		contact_monitor = true
		max_contacts_reported = 10
	refresh()


func set_runtime(ctx: BattleContext, target: Node2D) -> void:
	battle_context = ctx
	aim_target = target


func configure(ball_data: BallData, ball_level: int, ctx: BattleContext, target: Node2D) -> void:
	data = ball_data
	level = ball_level
	set_runtime(ctx, target)
	refresh()


func set_preview(ball_data: BallData, ball_level: int) -> void:
	ui_preview = true
	data = ball_data
	level = ball_level
	set_collision_enabled(false)
	refresh()


func refresh() -> void:
	if data == null:
		return
	_update_collision()
	queue_redraw()


func set_collision_enabled(enabled: bool) -> void:
	($CollisionShape2D as CollisionShape2D).disabled = not enabled


func set_playfield_state(is_set_up: bool) -> void:
	set_up = is_set_up
	gravity_scale = 0.0 if set_up else GRAVITY_SCALE
	if set_up:
		sleeping = false


func participates_in_level_merge() -> bool:
	return data != null and data.participates_in_level_merge()


func is_elemental() -> bool:
	return data != null and data.is_elemental()


func has_tag(tag: String) -> bool:
	return data != null and data.has_tag(tag)


func get_radius() -> float:
	return 20.0 if data == null else data.radius_for_level(level)


func is_setup_ball() -> bool:
	return set_up


func is_active_in_board() -> bool:
	return visible and not is_queued_for_deletion() and not set_up


func is_active_for_effects() -> bool:
	return visible and not is_queued_for_deletion()


func can_be_hit_by_shot() -> bool:
	return is_active_in_board()


func check_merge(ctx: BattleContext, other: BallBase) -> bool:
	return false


func merge_with(ctx: BattleContext, other: BallBase) -> void:
	pass


func try_apply_board_behavior(ctx: BattleContext) -> bool:
	for effect in _effects():
		if effect.can_trigger(ctx, self):
			effect.apply(ctx, self)
			return true
	return false


func tick_board_behavior(ctx: BattleContext) -> void:
	for effect in _effects():
		effect.tick(ctx, self)


func shot_base_damage() -> int:
	return level if data != null and data.id == BallCatalog.NORMAL_BALL_ID else 0


func shot_damage_multiplier() -> float:
	var multiplier := 1.0
	for effect in _effects():
		multiplier *= effect.shot_multiplier(self)
	return multiplier


func on_shot(ctx: BattleContext) -> void:
	for effect in _effects():
		effect.on_shot(ctx, self)
	if is_queued_for_deletion():
		return
	ctx.consume_ball(self)


func on_destroy(ctx: BattleContext) -> void:
	for effect in _effects():
		effect.on_destroy(ctx, self)


func merge_into_me() -> void:
	level *= 2
	refresh()


func multiply_level(multiplier: int = 2) -> void:
	level *= multiplier
	refresh()


func _physics_process(_delta: float) -> void:
	physics_material_override.absorbent = linear_velocity.y <= 1.0
	if not visible:
		gravity_scale = 0.0
		return
	if battle_context == null or aim_target == null:
		return
	if battle_context.phase != BattleContext.Phase.PLAY:
		set_up = false
		gravity_scale = GRAVITY_SCALE
		return
	if not set_up:
		gravity_scale = GRAVITY_SCALE
		return
	sleeping = false
	gravity_scale = 0.0
	var delta_x := aim_target.position.x - position.x
	var direction := 0.0 if absf(delta_x) < 15.0 else signf(delta_x)
	linear_velocity = Vector2(clampf(absf(delta_x) * 25.0, 0.0, 2500.0) * direction, 0.0)
	if Input.is_action_just_pressed("drop"):
		sleeping = false
		gravity_scale = GRAVITY_SCALE
		set_up = false
		dropped.emit()


func _draw() -> void:
	if data == null:
		return
	var radius := get_radius()
	var color := data.display_color(level)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, OUTLINE_POINTS, data.display_outline_color(level), OUTLINE_WIDTH, true)
	var sprite := $Sprite2D as Sprite2D
	var scale := (radius * 2.0) / float(sprite.texture.get_width())
	sprite.scale = Vector2.ONE * scale
	sprite.modulate = color
	($RichTextLabel as RichTextLabel).text = "[b]%s[/b]" % data.display_label(level)


func _update_collision() -> void:
	var col := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if col == null or not col.shape is CircleShape2D:
		return
	var circle := (col.shape as CircleShape2D).duplicate()
	circle.radius = get_radius()
	col.shape = circle


func _merge_rule() -> MergeRuleBase:
	return data.merge_rule if data != null else null


func _effects() -> Array:
	return data.effects if data != null else []
