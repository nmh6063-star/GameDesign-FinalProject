extends Sprite2D

const INVISIBLE_X = -448
const VISIBLE_X = 448
const IDLE_X = 1338
const SLIDE_SPEED = 20

var revealing = false
var concealing = false

func _process(delta):
	var card_position = position
	if revealing and card_position.x > VISIBLE_X:
		card_position.x -= SLIDE_SPEED
		if card_position.x <= VISIBLE_X:
			card_position.x = VISIBLE_X
			revealing = false
		position = card_position
	if concealing and card_position.x > INVISIBLE_X:
		card_position.x -= SLIDE_SPEED
		if card_position.x <= INVISIBLE_X:
			card_position.x = IDLE_X
			visible = false
			concealing = false
		position = card_position

func reveal():
	if not visible and not concealing:
		visible = true
		revealing = true

func conceal():
	if visible and not revealing:
		concealing = true
