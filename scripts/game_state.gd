extends Node

var map_seed: int = 47291
var player_health: int = 82
var magazine_ammo: int = 30
var reserve_ammo: int = 90
var has_ak: bool = false
var scrap: int = 80
var weapon_level: int = 1
var medkits: int = 0
var returning_from_shelter: bool = false
var world_time_hours: float = 9.0


func randomize_map() -> void:
	map_seed = int(Time.get_unix_time_from_system()) ^ Time.get_ticks_msec()
	map_seed = absi(map_seed) % 2_000_000_000


func start_new_raid() -> void:
	world_time_hours = 9.0


func reset_run() -> void:
	player_health = 82
	magazine_ammo = 30
	reserve_ammo = 90
	has_ak = false
	scrap = 80
	weapon_level = 1
	medkits = 0
	returning_from_shelter = false
	world_time_hours = 9.0
