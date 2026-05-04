extends Control
## Player HP bar + merge meter (mana pips live on `CursorManaPipes`).

@onready var _meter_fill: ColorRect = $Row/Meter/Fill
@onready var _meter_bg: ColorRect = $Row/Meter/Background


func _ready() -> void:
	_meter_bg.color = Color(0.05, 0.05, 0.08, 1.0)
	_meter_fill.color = Color(0.33, 0.66, 1.0, 1.0)


func sync_mana_meter(merge_progress: int, merges_per_mana_pipe: int) -> void:
	var meter_inner_width := maxf(_meter_bg.size.x - 4.0, 0.0)
	_meter_fill.size.x = maxf(
		0.0,
		meter_inner_width * float(merge_progress) / float(max(merges_per_mana_pipe, 1))
	)
