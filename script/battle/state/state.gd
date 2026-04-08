extends RefCounted
class_name BattleState

const ShootAmmo := preload("res://script/battle/state/ammo.gd")

enum Phase { PLAY, RESOLVE }

var phase := Phase.PLAY
var resolving_board := true
var player_energy_max := 1000
var player_energy := 1000
var current_ball = null
var shoot_ammo = ShootAmmo.new()


func reset_for_battle() -> void:
	phase = Phase.PLAY
	resolving_board = true
	player_energy = player_energy_max
	current_ball = null
	shoot_ammo = ShootAmmo.new()


func start_turn() -> void:
	phase = Phase.PLAY
	resolving_board = true
	current_ball = null
	player_energy = min(player_energy + 5, player_energy_max)


func begin_resolution() -> void:
	phase = Phase.RESOLVE
	resolving_board = true


func lock_resolution() -> void:
	resolving_board = false


func register_merge() -> void:
	shoot_ammo.register_merge()
