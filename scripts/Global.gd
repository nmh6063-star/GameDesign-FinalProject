extends Node

signal action_points_changed(current: int, maximum: int)

var mergeTime = false
var handSize = 5
var currentHand = []
var cardInPlay = null
@onready var ballInPlay = get_node("/root/Node2D/Ball")

var maxActionPoints: int = 3
var actionPoints: int = maxActionPoints
var planningPhase: bool = true
