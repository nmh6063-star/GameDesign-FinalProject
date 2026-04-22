extends BattleBallManager
class_name TutorialBallManager

# TUTORIAL ONLY — Extends BattleBallManager to support a fixed, repeating ball sequence.
# Used exclusively by TutorialBattleLoop in tutorial.tscn.
# Do not reference this class from any non-tutorial scene or script.

var _tutorial_sequence: Array = []
var _tutorial_index: int = 0


# Replaces the random queue with a fixed repeating sequence.
# seq is an Array of Dictionaries with keys "id" (String) and "level" (int).
func apply_fixed_sequence(seq: Array) -> void:
	_tutorial_sequence = seq.duplicate()
	_tutorial_index = 0
	_queue.clear()
	_fill_queue()


func _fill_queue() -> void:
	while _queue.size() < QUEUE_SIZE:
		if not _tutorial_sequence.is_empty():
			var raw: Dictionary = _tutorial_sequence[_tutorial_index % _tutorial_sequence.size()]
			_tutorial_index += 1
			var data := BallCatalog.data_for_id(raw["id"])
			var scene := BallCatalog.scene_for_id(raw["id"])
			if data != null and scene != null:
				_queue.append({"id": raw["id"], "scene": scene, "data": data, "level": raw.get("level", 1)})
				continue
		_queue.append(_roll_ball_entry())
