extends Control

@onready var _combo_count: Label = $VBox/ComboCount
@onready var _multiplier: Label = $VBox/Multiplier
@onready var _bar_fill: ColorRect = $VBox/ComboBar/Fill

var _bar_max_width: float
var _last_combo := 0


func _ready() -> void:
	_bar_max_width = _bar_fill.size.x


func sync_state(combo: int, multiplier: float, timer_ratio: float) -> void:
	visible = combo > 0
	if not visible:
		_last_combo = 0
		return
	_combo_count.text = "%d" % combo
	_multiplier.text = "x%.1f" % multiplier
	_bar_fill.size.x = _bar_max_width * timer_ratio
	if combo > _last_combo:
		_pop_animation()
	_last_combo = combo


func _pop_animation() -> void:
	var tween := create_tween()
	var value := float($VBox/ComboCount.text)
	# Cap the scale so the label never overflows its panel at high combo counts.
	var peak   := 1.15 + value / 5.0
	var settle := 1.0  + value / 10.0
	tween.tween_property($VBox/ComboCount, "scale", Vector2(peak,   peak),   0.06).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property($VBox/ComboCount, "scale", Vector2(settle, settle), 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
