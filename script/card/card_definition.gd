extends Resource
## Data-only card resource (Slay-the-Spire–style "Card"): title ≈ name, cost ≈ mana,
## behavior carries ball/effect logic for this game.
class_name CardDefinition

const BallBehavior := preload("res://script/ball/behaviors/ball_behavior.gd")

@export var title: String = ""
@export var summary: String = ""
@export_multiline var description: String = ""
@export var cost: int = 1
@export var modifier: int = 1
@export var kind: int = BallBehavior.Kind.NORMAL
@export var behavior: BallBehavior
