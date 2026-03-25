extends Node

const MERGE_TOLERANCE := 4.0
const DROP_OFFSET := 80.0

@onready var card_manager = get_node("/root/Node2D/CardManager")

func _physics_process(_delta: float) -> void:
	var balls := get_tree().get_nodes_in_group("ball")
	var valid: Array = []
	for node in balls:
		if not is_instance_valid(node):
			continue
		var body := node as RigidBody2D
		if body == null or not body.has_method("get_radius") or not body.has_method("merge_into_me"):
			continue
		if body.set_up:
			continue
		valid.append(body)

	# merge logic
	if Global.mergeTime:
		for i in valid.size():
			var a := valid[i] as RigidBody2D
			if not is_instance_valid(a):
				continue
			for j in range(i + 1, valid.size()):
				var b := valid[j] as RigidBody2D
				if not is_instance_valid(b):
					continue
				if a.level != b.level:
					continue
				var dist := a.global_position.distance_to(b.global_position)
				var sum_r: float = a.get_radius() + b.get_radius() + MERGE_TOLERANCE
				if dist <= sum_r:
					a.merge_into_me()
					b.queue_free()
					return

	# balls that fell out below the cup
	var box_out := get_parent().get_node_or_null("BoxOut")
	var template_ball := get_parent().get_node_or_null("Ball")
	if box_out and template_ball:
		var limit_y: float = box_out.global_position.y + DROP_OFFSET
		for node in balls:
			var body := node as RigidBody2D
			if body == null or body == template_ball:
				continue
			if body.global_position.y > limit_y:
				var dmg := 1
				if "level" in body:
					dmg = body.level
				var enemy := get_tree().get_first_node_in_group("enemy")
				if enemy and enemy.has_method("apply_attack"):
					enemy.apply_attack(dmg)
				body.queue_free()
	
	#keep cards supplied
	if Global.currentHand.size() < Global.handSize and card_manager.cardPlay:
		card_manager.draw()

func _card_play_toggle():
	card_manager.cardPlay = Global.actionPoints > 0 and Global.planningPhase
