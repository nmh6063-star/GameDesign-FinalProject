extends RefCounted

const CardDefinition := preload("res://script/card/card_definition.gd")
const BallBehavior := preload("res://script/ball/behaviors/ball_behavior.gd")

const _NORMAL_LINES := "Level merges with same level when touching."

static func random_card() -> CardDefinition:
	var pool := _build()
	return pool[randi() % pool.size()].duplicate(true)


static func _build() -> Array[CardDefinition]:
	var a: Array[CardDefinition] = []
	for lv in range(1, 5):
		a.append(_normal(lv))
	a.append(_dup())
	a.append(_mult())
	a.append(_heal())
	return a


static func _normal(modifier: int) -> CardDefinition:
	var c := CardDefinition.new()
	c.title = "Normal Ball"
	c.summary = "Lv %d · merges with same number" % modifier
	c.description = _NORMAL_LINES
	c.cost = 1
	c.modifier = modifier
	c.kind = BallBehavior.Kind.NORMAL
	c.behavior = BallBehavior.from_kind(BallBehavior.Kind.NORMAL)
	return c


static func _dup() -> CardDefinition:
	var c := CardDefinition.new()
	c.title = "Duplication Ball"
	c.summary = "D · duplicate touching balls"
	c.description = "If D touches 2+ other balls, duplicate each once; D is removed."
	c.cost = 2
	c.modifier = 1
	c.kind = BallBehavior.Kind.DUPLICATION
	c.behavior = BallBehavior.from_kind(BallBehavior.Kind.DUPLICATION)
	return c


static func _mult() -> CardDefinition:
	var c := CardDefinition.new()
	c.title = "Multiplication Ball"
	c.summary = "M · double connected values"
	c.description = "M doubles levels of touching numbered balls, then M is removed."
	c.cost = 2
	c.modifier = 1
	c.kind = BallBehavior.Kind.MULTIPLICATION
	c.behavior = BallBehavior.from_kind(BallBehavior.Kind.MULTIPLICATION)
	return c


static func _heal() -> CardDefinition:
	var c := CardDefinition.new()
	c.title = "Heal Ball"
	c.summary = "H · drain cluster for HP"
	c.description = "H removes touching numbered balls and heals for 2×sum(levels); H is removed."
	c.cost = 2
	c.modifier = 1
	c.kind = BallBehavior.Kind.HEAL
	c.behavior = BallBehavior.from_kind(BallBehavior.Kind.HEAL)
	return c
