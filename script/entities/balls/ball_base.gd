extends RigidBody2D
class_name BallBase

const BattleContext := preload("res://script/battle/core/battle_context.gd")
const BallCatalog := preload("res://script/entities/balls/ball_catalog.gd")
const ElementCatalog := preload("res://script/entities/balls/elemental_balls/elemental_ball_catalog.gd")
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
var rank := 1
var ui_preview := false
var touchingDir = ""
var last = 0
var dying = false
var type = []
var element_list = []


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
	var temp = level
	if rank != 8:
		rank = 1
		while temp > 1:
			temp /= 2
			rank += 1
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
	var temp = level
	if rank != 8:
		rank = 1
		while temp > 1:
			temp /= 2
			rank += 1
	_update_collision()
	queue_redraw()


func set_collision_enabled(enabled: bool) -> void:
	($CollisionShape2D as CollisionShape2D).disabled = not enabled


func set_playfield_state(is_set_up: bool) -> void:
	set_up = is_set_up
	gravity_scale = 0.0 if set_up else GRAVITY_SCALE
	if set_up:
		sleeping = false

func die():
	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = 1.0
	timer.one_shot = true
	timer.timeout.connect(_on_timer_timeout)
	self.freeze = true
	$CollisionShape2D.disabled = true
	dying = true
	timer.start()

func _on_timer_timeout():
	self.queue_free()


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


func merge_with(ctx: BattleContext, other: BallBase, level: float) -> void:
	pass


func try_apply_board_behavior(ctx: BattleContext) -> bool:
	for effect in _effects():
		if effect.can_trigger(ctx, self):
			effect.apply(ctx, self)
			return true
	for elements in element_list:
		if elements["element"].get_target_function(self, elements["effect"], "can_trigger"):
			elements["element"].apply(ctx, self, elements["effect"])
		#print(elements.can_trigger(ctx, self))
		#if elements["element"].can_trigger(ctx, self, elements[1]):
		#	#elements.apply(ctx, self)
		#	print("pass")
	return false


func tick_board_behavior(ctx: BattleContext) -> void:
	for effect in _effects():
		effect.tick(ctx, self)


func shot_base_damage():
	#if data..size() > 0:
	#	print("detected element")
	return level if data != null and (data.id == BallCatalog.NORMAL_BALL_ID || data.id == "ball_heavy") else null


func shot_damage_multiplier() -> float:
	var multiplier := 1.0
	for effect in _effects():
		multiplier *= effect.shot_multiplier(self)
	return multiplier


func on_shot(ctx: BattleContext) -> void:
	for effect in _effects():
		effect.on_shot(ctx, self)
	print(element_list)
	for elements in element_list:
		if elements["element"].get_target_function(self, elements["effect"], "on_shot"):
			elements["element"].on_shot(ctx, self, elements["effect"])
	if is_queued_for_deletion():
		return
	ctx.consume_ball(self)


func on_destroy(ctx: BattleContext) -> void:
	for effect in _effects():
		effect.on_destroy(ctx, self)


func merge_into_me(ctx: BattleContext, merger: BallBase) -> void:
	level += 1
	for elements in element_list:
		if elements["element"].get_target_function(self, elements["effect"], "on_merge"):
			elements["element"].on_merge(ctx, self, elements["effect"])
	refresh()


func multiply_level(multiplier: int = 2) -> void:
	level *= multiplier
	refresh()

func rank_state():
	print("test")
	


func _physics_process(_delta: float) -> void:
	if type.size() > 0:
		var base_color = Vector3.ZERO
		for i in type:
			base_color.x += ElementCatalog.get_color(i).r
			base_color.y += ElementCatalog.get_color(i).g
			base_color.z += ElementCatalog.get_color(i).b
		self_modulate = Color(base_color.x, base_color.y, base_color.z)
	if dying:
		self_modulate.a -= 5.0 * _delta
		self_modulate.a = max(self_modulate.a, 0)
		scale += Vector2(2.5 * _delta, 2.5 * _delta)
		for child in get_children():
			if "self_modulate" in child:
				child.self_modulate.a -= 5.0 * _delta
				child.self_modulate.a = max(child.self_modulate.a, 0)
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
	if battle_context.slow_mo_active:
		linear_velocity = Vector2.ZERO
		return
	var delta_x := aim_target.position.x - position.x
	var direction := 0.0 if absf(delta_x) < 15.0 else signf(delta_x)
	linear_velocity = Vector2(clampf(absf(delta_x) * 25.0, 0.0, 2500.0) * direction, 0.0)
	if (touchingDir == 'right' and linear_velocity.x > 0) or (touchingDir == 'left' and linear_velocity.x < 0):
		linear_velocity.x = 0
	if (touchingDir == 'right' and linear_velocity.x < 0) or (touchingDir == 'left' and linear_velocity.x > 0):
		touchingDir = ''
	if Input.is_action_just_pressed("drop"):
		sleeping = false
		gravity_scale = GRAVITY_SCALE
		set_up = false
		dropped.emit()
		
				
func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if(state.get_contact_count() > 0):
		if(set_up):
			if global_position.x > 400:
				touchingDir = 'right'
			else:
				touchingDir = 'left'

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
