extends RefCounted
class_name ElementalBallCatalog

static var elemental_database = [
	{
		"name": "Poison Apple",
		"type": "Dark",
		"function": "health_for_damage",
		"description": "Deal a bit extra damage but also take a bit of damage. Shoot this rank ball to trigger",
		"rank": 1
	},
	{
		"name": "Dark Brew",
		"type": "Dark",
		"function": "deploy_enchantment",
		"description": "NOT FINISHED",
		"rank": 2
	},
	{
		"name": "Slow Down",
		"type": "Dark",
		"function": "slow_time",
		"description": "NOT FINISHED",
		"rank": 3
	},
	{
		"name": "Care Drop",
		"type": "Dark",
		"function": "care_drop",
		"description": "Drop in a cluster of balls from the top of the board. Triggers on merge.",
		"rank": 4
	},
	{
		"name": "Biggering",
		"type": "Dark",
		"function": "enbiggen",
		"description": "Increase damage of balls at the cost of higher size scaling (NOT FINISHED)",
		"rank": 5
	},
	{
		"name": "An Eye For An Arm",
		"type": "Dark",
		"function": "eye_for_an_arm",
		"description": "Deal moderate damage to yourself and high damage to an enemy. Triggers on merge.",
		"rank": 6
	},
	{
		"name": "Clone",
		"type": "Dark",
		"function": "create_copy",
		"description": "Create a clone of the rank 7 ball, taking up a lot of space but giving you lots of damage to work with.",
		"rank": 7
	},
	{
		"name": "Buy In",
		"type": "Gambler",
		"function": "buy_in",
		"description": "Buy into the game! Gain health on merge or lose health on merge. Triggers on shot",
		"rank": 1
	},
	{
		"name": "Roll For Initiative",
		"type": "Gambler",
		"function": "roll_for_initiative",
		"description": "Roll the dice! Who's it gonna be? Either you're gonna deal double damage or your enemies are gonna ravage upon you!",
		"rank": 7
	}
]

static func get_color(type):
	match type:
		"Dark":
			return Color()
		"Gambler":
			return Color(1.0, 0.0, 0.0)
		_:
			return Color(1.0, 1.0, 1.0)

static func get_passive(type):
	match type:
		"Dark":
			return {
				"name": "Darkness Consumes",
				"type": "Dark",
				"function": "darkness_consume",
				"description": "Passive",
				"rank": 0
			}
		"Gambler":
			return {
				"name": "Gambling Fallacy",
				"type": "Gambler",
				"function": "gambling_fallacy",
				"description": "Passive",
				"rank": 0
			}
		_:
			return null
