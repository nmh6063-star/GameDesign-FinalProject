extends Node2D

@export var hand_curve: Curve
@export var rotation_curve: Curve

@export var max_rotation_degrees := 5
@export var x_sep := 50
@export var y_min := 0
@export var y_max := -15
var hideSpeed = 10.0
@onready var targetPos = self.position
var deckSize = 700
var index = 0
var cardPlay = true

func _physics_process(delta: float) -> void:
	if cardPlay:
		self.position = self.position.lerp(targetPos, delta * hideSpeed)
	else:
		self.position = self.position.lerp(targetPos + Vector2(0, 250), delta * hideSpeed)

const card = preload("res://scenes/card.tscn")

func draw():
	var new_card = card.instantiate()
	add_child(new_card)
	var card_detail = {"name": "test", "ability": "temp", "modifier": randi_range(1, 4)}
	new_card.get_node("Sprite2D/RichTextLabel").text = card_detail["name"] + "\n Ability: " + card_detail["ability"] + "\n" + str(card_detail.modifier)
	new_card.details = card_detail
	index += 1
	Global.currentHand.append(card_detail)
	_update_cards()

func discard(index):
	if Global.currentHand.size() < 1:
		return
	
	Global.currentHand.remove_at(index)
	var child := get_child(index)
	Global.ballInPlay.visible = true
	Global.ballInPlay.set_up = true
	Global.ballInPlay.level = child.details.modifier
	child.reparent(get_tree().root)
	child.queue_free()
	_update_cards()
	Global.ballInPlay._update_collision()
	Global.ballInPlay.queue_redraw()
	cardPlay = false
	
	

func _update_cards():
	var cards = Global.currentHand.size()
	var final_x_sep := x_sep
	var cardX = get_children()[0].get_node("Area2D/CollisionShape2D").shape.extents.x * 2.0
	var all_cards_size = cardX * cards + x_sep * (cards-1)
	if all_cards_size > deckSize:
		final_x_sep = (deckSize - cardX * cards) / (cards - 1)
		all_cards_size = deckSize
	
	var offset = (deckSize - all_cards_size) / 2
	for i in cards:
		var card := get_child(i)
		var y_multi := hand_curve.sample(1.0 / (cards-1) * i)
		var rot_multi := rotation_curve.sample(1.0 / (cards-1) * i)
		
		if cards == 1:
			y_multi = 0.0
			rot_multi = 0.0
		var final_x: float = offset + cardX * i + final_x_sep * i
		var final_y: float = y_min + y_max * y_multi
		card.targetPos = Vector2(final_x, final_y)
		card.targetRot = max_rotation_degrees * rot_multi
		card.index = i
