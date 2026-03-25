extends Node

enum Phase { PLAY, RESOLVE }

var phase: Phase = Phase.PLAY
var handSize := 5
var currentHand := []
var cardInPlay = null
var player_health := 100
var player_max_health := 100

@onready var ballInPlay = get_node("/root/Node2D/Ball")

