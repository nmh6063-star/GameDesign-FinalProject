extends Node

enum Phase { PLAY, RESOLVE }

var phase: Phase = Phase.PLAY
var handSize := 5
var currentHand: Array = []
var cardInPlay = null
var player_health := 100
var player_max_health := 100

var player_energy_max := 1000
var player_energy := 1000

var map_drawn = false
var map_horizontal = 4
var map_vertical = 2
var current_tile = Vector2(-1, 0)

@onready var ballInPlay = get_node("/root/Node2D/Ball")

var savedMapData = []
