extends Node2D
class_name CardManager

const CardDefinition := preload("res://script/card/card_definition.gd")
const GameBall := preload("res://script/ball/game_ball.gd")
const BallBehavior := preload("res://script/ball/behaviors/ball_behavior.gd")
const _LIB := preload("res://script/card/library/card_library.gd")
const _CARD := preload("res://scenes/card.tscn")

@export var hand_curve: Curve
@export var rotation_curve: Curve
@export var max_rotation_degrees := 5
@export var x_sep := 50
@export var y_min := 0
@export var y_max := -15

var hideSpeed := 10.0
@onready var targetPos := position
var deckSize := 700
var index := 0
var cardPlay := true
var deck = []


func _physics_process(delta: float) -> void:
	var target := targetPos + (Vector2.ZERO if cardPlay else Vector2(0, 350))
	position = position.lerp(target, delta * hideSpeed)
	if cardPlay:
		if deck.size() == 0:
			deck = _LIB._build()
		var index = randi() % deck.size()
		var details = deck[index].duplicate(true)
		var inst = _CARD.instantiate()
		inst.details = details
		print(details.title)
		deck.remove_at(index)
		confirm_play(inst)


#below here is all invalidated code. TODO, edit other scripts so can easily delete
func draw() -> void:
	var inst := _CARD.instantiate()
	add_child(inst)
	var def := _LIB.random_card()
	inst.get_node("Sprite2D/RichTextLabel").text = "%s\n%s" % [def.title, def.summary]
	var badge := inst.get_node_or_null("CostBadge/CostText") as Label
	if badge:
		badge.text = str(def.cost)
	inst.details = def
	index += 1
	Global.currentHand.append(def)
	_update_cards()


func confirm_play(card: Node2D) -> void:
	if not cardPlay or Global.currentHand.is_empty():
		return
	var idx := card.get_index()
	var def := card.details as CardDefinition
	#if def == null or idx < 0 or idx >= get_child_count():
	#	return
	if Global.player_energy < def.cost:
		card.disarm_snap()
		return
	card.clear_arm_state()
	Global.player_energy -= def.cost
	(get_node("/root/Node2D") as Node).update_energy_ui()
	(get_node("/root/Node2D") as Node).ensure_ball_in_play()
	Global.currentHand.remove_at(idx)
	var play := Global.ballInPlay as GameBall
	play.visible = true
	play.set_up = true
	play.behavior = BallBehavior.from_kind(def.kind)
	print(def.kind)
	print("oops")
	play.level = def.modifier if play.behavior.participates_in_level_merge() else 1
	card.reparent(get_tree().root)
	card.queue_free()
	_update_cards()
	play._update_collision()
	play.queue_redraw()
	cardPlay = false




func _update_cards() -> void:
	var n := Global.currentHand.size()
	if n < 1 or get_child_count() < 1:
		return
	var card_w: float = get_child(0).get_node("Area2D/CollisionShape2D").shape.extents.x * 2.0
	var sep: float = x_sep
	var total: float = card_w * n + x_sep * maxi(n - 1, 0)
	if n > 1 and total > deckSize:
		sep = (deckSize - card_w * n) / float(n - 1)
		total = deckSize
	var offset: float = (deckSize - total) * 0.5 if n > 0 else 0.0
	for i in n:
		var c := get_child(i)
		var t := 0.5 if n <= 1 else float(i) / float(n - 1)
		var ym := 0.0 if n <= 1 else hand_curve.sample(t)
		var rm := 0.0 if n <= 1 else rotation_curve.sample(t)
		c.targetPos = Vector2(offset + (card_w + sep) * i, y_min + y_max * ym)
		c.targetRot = max_rotation_degrees * rm
		c.index = i
