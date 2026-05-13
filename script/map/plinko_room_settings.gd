extends Node
class_name PlinkoRoomSettings
## Tunables for PlinkoRoom — edit on the Settings child node in plinko_room.tscn (Inspector).

@export_group("Drops & scoring")
@export var max_drops: int = 3
@export var points_slot_base: int = 3
@export var points_slot_per_rank: int = 2
@export var miss_points: int = 2

@export_group("Prize counter")
@export var draw_cost: int = 8
## Fixed rank rolls: ranks 1–5 share this price; 6 and 7 are higher (see below).
@export var shop_roll_rank_1_to_5_cost: int = 12
@export var shop_roll_rank_6_cost: int = 16
@export var shop_roll_rank_7_cost: int = 18
@export var lucky_draw_rank_min: int = 2
@export var lucky_draw_rank_max: int = 7
## Shown above Lucky draw. Use two %d placeholders: rank min, rank max.
@export var lucky_draw_intro_format: String = "Lucky Draw: random rank %d–%d ability for the score cost below."
## Spend entire score; gold gained = floor(score * this). Button disabled if result would be 0.
@export var gold_per_plinko_point: float = 0.2
## Empty space (px) between shop rows and Cash out / Continue.
@export var prize_counter_bottom_spacer_px: int = 56
## Half-height of prize modal panel (offset_top / offset_bottom).
@export var prize_counter_panel_half_height: float = 320.0

@export_group("Symmetric slot tiers (rank 1–7 → ability pool; label shows score, not rank)")
@export var symmetric_edge_rank: int = 2
@export var symmetric_center_rank: int = 7

@export_group("Ball & aim")
@export var ball_radius: float = 9.0
@export var ball_drop_impulse: float = 10.0
@export var indicator_speed: float = 120.0
@export var indicator_half_range: float = 140.0
@export var ball_stuck_speed_threshold: float = 7.0
@export var ball_stuck_timeout_sec: float = 2.5
@export var ball_max_air_time_sec: float = 18.0

@export_group("UI strings (optional; leave empty to use code defaults)")
@export var drops_label_format: String = "Drops: %d / %d"
@export var score_label_format: String = "Score: %d"
@export var prize_counter_title: String = "Prize counter"
@export var exit_room_message: String = ""
