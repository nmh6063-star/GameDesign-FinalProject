extends RefCounted
class_name PlayerHealthBarSync

## HP bar Background uses non-1 scale in .tscn; fill width must match *visual* width.


static func bar_visual_width(background: ColorRect) -> float:
	return background.size.x * absf(background.scale.x)


## Sets fill.size.x so drawn width matches `bar_visual_width * hp_frac`. Returns HP width in parent space (for shield).
static func apply_hp_fill(background: ColorRect, fill: ColorRect, hp_frac: float) -> float:
	var f := clampf(hp_frac, 0.0, 1.0)
	var hp_visual := bar_visual_width(background) * f
	fill.size.x = hp_visual / maxf(absf(fill.scale.x), 0.0001)
	return hp_visual
