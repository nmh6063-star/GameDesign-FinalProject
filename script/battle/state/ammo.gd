extends RefCounted
## Merge progress → bullets; caps at max. No merge meter growth while bullets are full.

const MAX_BULLETS := 5
const MERGES_PER_BULLET := 5

var merge_progress: int = 0
var bullets: int = 0


func register_merge() -> void:
	if bullets >= MAX_BULLETS:
		return
	merge_progress += 1
	if merge_progress >= MERGES_PER_BULLET:
		merge_progress = 0
		bullets = mini(bullets + 1, MAX_BULLETS)


func can_shoot() -> bool:
	return bullets > 0


func try_consume_shot() -> bool:
	if bullets <= 0:
		return false
	bullets -= 1
	return true
