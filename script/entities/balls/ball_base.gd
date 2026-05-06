extends RigidBody2D
class_name BallBase

const BattleContext := preload("res://script/battle/core/battle_context.gd")
const BallCatalog := preload("res://script/entities/balls/ball_catalog.gd")
const ElementCatalog := preload("res://script/entities/balls/elemental_balls/elemental_ball_catalog.gd")
const BallData := preload("res://script/entities/balls/ball_data.gd")
const GRAVITY_SCALE := 2.0
const OUTLINE_WIDTH := 2.0
const OUTLINE_POINTS := 64
const sound := preload("res://script/game_manager/sound_manager.gd")

signal dropped

@export var data: BallData

var battle_context: BattleContext
var aim_target: Node2D
var set_up := false
var rank := 1
var typing = null
var ui_preview := false
var touchingDir = ""
var last = 0
var dying = false
## Horizontal playfield extent in BallHolder space (set by BattleBallManager from Background/Box/Interior).
var _playfield_left_x: float = 0.0
var _playfield_right_x: float = -1.0
var type = []
var element_list = []
var _status_tag_label: Label
var previous_velocity: Vector2


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
	#set sprites
	refresh()


func set_runtime(ctx: BattleContext, target: Node2D) -> void:
	battle_context = ctx
	aim_target = target


func set_playfield_x_bounds(left_x: float, right_x: float) -> void:
	_playfield_left_x = left_x
	_playfield_right_x = right_x


func configure(ball_data: BallData, ball_rank: int, ctx: BattleContext, target: Node2D) -> void:
	data = ball_data
	rank = clampi(ball_rank, 1, 7)
	set_runtime(ctx, target)
	refresh()


func set_preview(ball_data: BallData, ball_rank: int) -> void:
	ui_preview = true
	data = ball_data
	rank = clampi(ball_rank, 1, 7)
	#come back to 
	for elements in element_list:
		if elements["element"].matching_function(self, elements["effect"]):
			$Sprite2D.texture = elements["element"].get_sprite_files(elements["effect"])["overlay"]
	set_collision_enabled(false)
	refresh()

func soften_alpha(img: Image):
	var w = img.get_width()
	var h = img.get_height()

	var temp = Image.create(w, h, false, Image.FORMAT_RGBA8)

	# number of blur passes (increase for stronger smoothing)
	var passes = 3

	for p in range(passes):
		for y in range(h):
			for x in range(w):
				var sum = 0.0
				var count = 0

				# 5x5 kernel (stronger than before)
				for oy in range(-2, 3):
					for ox in range(-2, 3):
						var nx = x + ox
						var ny = y + oy

						if nx >= 0 and nx < w and ny >= 0 and ny < h:
							var c = img.get_pixel(nx, ny)
							sum += c.a
							count += 1

				var avg = sum / max(count, 1)

				var c = img.get_pixel(x, y)
				c.a = avg
				temp.set_pixel(x, y, c)

		# copy back for next pass
		img.copy_from(temp)

func center(poly: PackedVector2Array, size: Vector2) -> PackedVector2Array:
	var half = size * 0.5
	var result = PackedVector2Array()

	for p in poly:
		result.append((p - half) * get_radius() * 0.05)

	return result

func get_texture_center_global(sprite: Sprite2D) -> Vector2:
	if sprite.texture == null:
		return sprite.global_position

	var tex_size = sprite.texture.get_size()
	var local_center = tex_size / 2

	if sprite.centered:
		local_center = Vector2.ZERO
	else:
		local_center -= sprite.offset

	return sprite.to_global(local_center)

func percent_to_7(n: float) -> float:
	var min_val = 1.0
	var max_val = 7.0
	n = clamp(n, min_val, max_val)
	
	var percent = (n - min_val) / (max_val - min_val) * 100.0
	return percent/100.0

func refresh() -> void:
	if data == null:
		return
	var capsule := $Sprite2D as Sprite2D
	var element_base := $base as Sprite2D
	var element_overlay := $overlay as Sprite2D
	element_base.visible = false
	element_overlay.visible = false
	capsule.visible = true
	for elements in element_list:
		if elements["element"].matching_function(self, elements["effect"]):
			var polygon = get_node_or_null("Polygon2D")
			if polygon:
				polygon.queue_free()
			var base = get_node_or_null("Sprite2D")
			var overlay = get_node_or_null("overlay")
			var collision = get_node_or_null("collision")
			if get_node_or_null("collision") == null:
				overlay = Sprite2D.new()
				overlay.name = "overlay"
				collision = CollisionPolygon2D.new()
				collision.name = "collision"
				self.add_child(overlay)
				self.add_child(collision)
				get_node("CollisionShape2D").queue_free()
			base.texture = elements["element"].get_sprite_files(elements["effect"])["base"][rank-1]
			overlay.texture = elements["element"].get_sprite_files(elements["effect"])["overlay"]
			overlay.modulate = Color(0.68, 0.85, 0.9)
			base.modulate = Color(percent_to_7(rank), percent_to_7(rank), percent_to_7(rank))
			#base.scale = Vector2(1.0 + get_radius()/100.0, 1.0 + get_radius()/100.0)
			overlay.scale = Vector2(get_radius()/25.0, get_radius()/25.0)
			overlay.position.y = 25.0
			typing = elements["element"].get_function_info(elements["effect"])["class"]
			var image = base.texture.get_image()
			image.convert(Image.FORMAT_RGBA8)
			soften_alpha(image)
			var bitmap = BitMap.new()
			bitmap.create_from_image_alpha(image)
			var polys = bitmap.opaque_to_polygons(
				Rect2(Vector2.ZERO, image.get_size()),
				0.5
			)

			var poly = center(polys[0], image.get_size())

			collision.polygon = poly
			collision.position = base.position + Vector2(0, 1.0)
			break
	_sync_rank()
	_update_collision()
	_sync_status_tag()
	queue_redraw()


func _sync_rank() -> void:
	rank = clampi(rank, 1, 7)


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
	if $collision:
		$collision.disabled = true
	else:
		$CollisionShape2D.disabled = true
	dying = true
	timer.start()

func _on_timer_timeout():
	self.queue_free()


func participates_in_rank_merge() -> bool:
	return data != null and data.participates_in_rank_merge()


func is_elemental() -> bool:
	return data != null and data.is_elemental()


func has_tag(tag: String) -> bool:
	return data != null and data.has_tag(tag)


func get_radius() -> float:
	var plus = 0
	if typing && !ui_preview:
		plus = 25.0
	return 20.0 if data == null else data.radius_for_rank(rank) + plus #temp solution


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


func merge_with(ctx: BattleContext, other: BallBase, rank_strength: float) -> void:
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
	return null


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
	rank = clampi(rank + 1, 1, 7)
	for elements in element_list:
		if elements["element"].get_target_function(self, elements["effect"], "on_merge"):
			elements["element"].on_merge(ctx, self, elements["effect"])
	sound.play_sound_from_string("merge")
	refresh()


func multiply_rank(multiplier: int = 2) -> void:
	if multiplier <= 1:
		return
	rank = clampi(rank + (multiplier - 1), 1, 7)
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
		#self_modulate = Color(base_color.x, base_color.y, base_color.z)
	if dying:
		self_modulate.a -= 2.5 * _delta
		self_modulate.a = max(self_modulate.a, 0)
		scale += Vector2(5.0 * _delta, 5.0 * _delta)
		for child in get_children():
			if "self_modulate" in child:
				child.self_modulate.a -= 2.5 * _delta
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
	if state.get_contact_count() > 0 and set_up:
		var w := _playfield_right_x - _playfield_left_x
		if w > 0.001:
			var mid_x := (_playfield_left_x + _playfield_right_x) * 0.5
			touchingDir = "right" if position.x > mid_x else "left"
	var current_velocity = state.linear_velocity
	if state.get_contact_count() > 0:
		for i in range(state.get_contact_count()):
			var normal = state.get_contact_local_normal(i)

			var dot_before = previous_velocity.dot(normal)
			var dot_after = current_velocity.dot(normal)

			var impact_speed = -dot_before  # positive if moving into the surface

			if dot_before < 0 and dot_after > 0 and impact_speed > 200.0:
				sound.play_sound_from_string("bounce", abs(impact_speed)/1000.0)

	previous_velocity = current_velocity

func _draw() -> void:
	if data == null:
		return
	var radius := get_radius()
	var color := data.display_color(rank)
	#draw_arc(Vector2.ZERO, radius, 0.0, TAU, OUTLINE_POINTS, data.display_outline_color(rank), OUTLINE_WIDTH, true)
	var sprite := $Sprite2D as Sprite2D
	var scale := (radius * 2.0) / float(sprite.texture.get_width())
	sprite.scale = Vector2.ONE * scale
	#sprite.modulate = color
	($RichTextLabel as RichTextLabel).text = "[b]%s[/b]" % data.display_label(rank)


func _update_collision() -> void:
	var col := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if col == null or not col.shape is CircleShape2D:
		return
	var circle := (col.shape as CircleShape2D).duplicate()
	circle.radius = get_radius()
	col.shape = circle


func _sync_status_tag() -> void:
	if battle_context == null:
		if _status_tag_label != null:
			_status_tag_label.visible = false
		return
	if _status_tag_label == null:
		_status_tag_label = get_node_or_null("StatusTag") as Label
		if _status_tag_label == null:
			_status_tag_label = Label.new()
			_status_tag_label.name = "StatusTag"
			add_child(_status_tag_label)
			_status_tag_label.position = Vector2(-30, -42)
			_status_tag_label.size = Vector2(80, 14)
			_status_tag_label.add_theme_font_size_override("font_size", 8)
	var st := battle_context.ball_status_for(self)
	var tags: Array[String] = []
	if bool(st.get("trigger_twice", false)):
		tags.append("x2")
	var atk := float(st.get("attack_mult", 1.0))
	if atk > 1.0:
		tags.append("ATKx%.1f" % atk)
	_status_tag_label.text = " ".join(tags)
	_status_tag_label.visible = not tags.is_empty()


func _merge_rule() -> MergeRuleBase:
	return data.merge_rule if data != null else null


func _effects() -> Array:
	return data.effects if data != null else []
