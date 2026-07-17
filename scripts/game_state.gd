extends Node

var map_seed: int = 47291
var player_health: int = 82
var magazine_ammo: int = 30
var reserve_ammo: int = 90
var has_ak: bool = true
var scrap: int = 80
var weapon_level: int = 1
var medkits: int = 0
var canned_food: int = 0
var fatigue: float = 0.0
var rescued_workers: int = 0
var resident_cat_ids: Array[String] = []
var assigned_worker_ids: Array[String] = []
var mod_component_inventory: Dictionary = {
	"rubber_gasket": 0,
	"scope_lens": 0,
	"magazine_spring": 0,
}
var weapon_inventory: Dictionary = {"ak47": 1}
var returning_from_shelter: bool = false
var world_time_hours: float = 9.0
var equipped_weapon_id: String = "ak47"
var weapon_durability: float = 100.0
var equipped_weapon_mods: Array[String] = []
var equipped_magazine_id: String = "ak_30rnd"
var equipped_ammo_id: String = "762_fmj"
var ammo_inventory: Dictionary = {
	"9mm_fmj": 60,
	"45_fmj": 28,
	"762_fmj": 90,
	"12g_buckshot": 12,
}
var secure_dog_slots: int = 1
var secure_dog_items: Array[Dictionary] = []
var shelter_workbench_level: int = 1
var scratcher_bank_level: int = 1
var scratcher_multiplier: float = 1.0
var shelter_last_progress_time: int = 0
var workbench_repair_active: bool = false
var workbench_repair_weapon_id: String = "ak47"
var shelter_offline_scrap_pending: int = 0
var shelter_offline_repair_pending: float = 0.0
var workbench_starter_parts_claimed: bool = false
var shelter_scrap_fraction: float = 0.0

const WORKBENCH_UPGRADE_COSTS := {2: 180, 3: 420, 4: 900, 5: 1800}
const SCRATCHER_UPGRADE_COSTS := {2: 120, 3: 320, 4: 850, 5: 1600}


func randomize_map() -> void:
	map_seed = int(Time.get_unix_time_from_system()) ^ Time.get_ticks_msec()
	map_seed = absi(map_seed) % 2_000_000_000


func start_new_raid() -> void:
	process_shelter_progress()
	world_time_hours = 9.0


func store_secure_item(item: Dictionary) -> bool:
	if secure_dog_items.size() >= secure_dog_slots:
		return false
	secure_dog_items.append(item.duplicate(true))
	return true


func upgrade_secure_dog() -> bool:
	if secure_dog_slots >= 6:
		return false
	secure_dog_slots += 1
	return true


func get_ammo_count(ammo_id: String) -> int:
	return int(ammo_inventory.get(ammo_id, 0))


func set_ammo_count(ammo_id: String, amount: int) -> void:
	ammo_inventory[ammo_id] = maxi(0, amount)
	if ammo_id == equipped_ammo_id:
		reserve_ammo = int(ammo_inventory[ammo_id])


func add_weapon(weapon_id: String, amount: int = 1) -> void:
	weapon_inventory[weapon_id] = maxi(0, int(weapon_inventory.get(weapon_id, 0)) + amount)


func add_mod_component(component_id: String, amount: int = 1) -> void:
	mod_component_inventory[component_id] = maxi(
		0,
		int(mod_component_inventory.get(component_id, 0)) + amount
	)


func claim_workbench_starter_parts() -> bool:
	if workbench_starter_parts_claimed:
		return false
	workbench_starter_parts_claimed = true
	add_weapon("m1911", 1)
	add_weapon("mp5", 1)
	add_mod_component("rubber_gasket", 2)
	add_mod_component("scope_lens", 2)
	add_mod_component("magazine_spring", 2)
	return true


func get_mod_component_count(component_id: String) -> int:
	return int(mod_component_inventory.get(component_id, 0))


func get_supported_worker_count() -> int:
	_ensure_resident_records()
	return mini(resident_cat_ids.size(), canned_food)


func get_scratcher_worker_slots() -> int:
	return mini(8, scratcher_bank_level + 1)


func get_active_scratcher_workers() -> int:
	_ensure_resident_records()
	_sanitize_assigned_workers()
	return mini(assigned_worker_ids.size(), mini(get_supported_worker_count(), get_scratcher_worker_slots()))


func get_scrap_per_hour() -> float:
	return float(get_active_scratcher_workers()) * 72.0 * scratcher_multiplier


func get_scrap_per_second() -> float:
	return get_scrap_per_hour() / 3600.0


func tick_shelter_live(delta: float) -> int:
	var gain := get_scrap_per_second() * maxf(delta, 0.0)
	if gain <= 0.0:
		return 0
	shelter_scrap_fraction += gain
	var whole := int(floor(shelter_scrap_fraction))
	if whole <= 0:
		return 0
	shelter_scrap_fraction -= float(whole)
	scrap += whole
	return whole


func _ensure_resident_records() -> void:
	while resident_cat_ids.size() < rescued_workers:
		var next_index := resident_cat_ids.size() + 1
		resident_cat_ids.append("resident_%03d" % next_index)
	if resident_cat_ids.size() > rescued_workers:
		resident_cat_ids.resize(rescued_workers)
	_sanitize_assigned_workers()


func _sanitize_assigned_workers() -> void:
	var cleaned: Array[String] = []
	var supported_limit := mini(resident_cat_ids.size(), mini(canned_food, get_scratcher_worker_slots()))
	for worker_id in assigned_worker_ids:
		if cleaned.size() >= supported_limit:
			break
		if resident_cat_ids.has(worker_id) and not cleaned.has(worker_id):
			cleaned.append(worker_id)
	assigned_worker_ids = cleaned


func assign_worker_to_scratcher(worker_id: String) -> bool:
	_ensure_resident_records()
	if not resident_cat_ids.has(worker_id):
		return false
	if assigned_worker_ids.has(worker_id):
		return true
	if assigned_worker_ids.size() >= get_supported_worker_count():
		return false
	if assigned_worker_ids.size() >= get_scratcher_worker_slots():
		return false
	assigned_worker_ids.append(worker_id)
	return true


func unassign_worker_from_scratcher(worker_id: String) -> void:
	assigned_worker_ids.erase(worker_id)


func toggle_worker_assignment(worker_id: String) -> bool:
	if assigned_worker_ids.has(worker_id):
		unassign_worker_from_scratcher(worker_id)
		return false
	return assign_worker_to_scratcher(worker_id)


func get_workbench_repair_per_hour() -> float:
	var base_rate := 18.0
	if shelter_workbench_level >= 3:
		base_rate *= 1.2
	if shelter_workbench_level >= 5:
		base_rate *= 1.18
	return base_rate


func process_shelter_progress() -> Dictionary:
	_ensure_resident_records()
	var now := int(Time.get_unix_time_from_system())
	if shelter_last_progress_time <= 0:
		shelter_last_progress_time = now
		return {"scrap": 0, "repair": 0.0, "elapsed": 0}
	var elapsed := maxi(0, now - shelter_last_progress_time)
	shelter_last_progress_time = now
	var scrap_gain := int(floor(get_scrap_per_hour() * float(elapsed) / 3600.0))
	var repair_gain := 0.0
	if workbench_repair_active and weapon_durability < 100.0:
		repair_gain = get_workbench_repair_per_hour() * float(elapsed) / 3600.0
		var before := weapon_durability
		weapon_durability = minf(100.0, weapon_durability + repair_gain)
		repair_gain = weapon_durability - before
		if weapon_durability >= 100.0:
			workbench_repair_active = false
	if scrap_gain > 0:
		scrap += scrap_gain
	shelter_offline_scrap_pending += scrap_gain
	shelter_offline_repair_pending += repair_gain
	return {"scrap": scrap_gain, "repair": repair_gain, "elapsed": elapsed}


func consume_offline_progress_notice() -> Dictionary:
	var notice := {
		"scrap": shelter_offline_scrap_pending,
		"repair": shelter_offline_repair_pending,
	}
	shelter_offline_scrap_pending = 0
	shelter_offline_repair_pending = 0.0
	return notice


func get_workbench_slot_limit() -> int:
	if shelter_workbench_level >= 5:
		return 6
	if shelter_workbench_level >= 3:
		return 5
	return 4


func can_mod_weapon(weapon_id: String) -> bool:
	if shelter_workbench_level >= 3:
		return true
	return ["m1911", "mp5"].has(weapon_id)


func try_upgrade_workbench() -> bool:
	var next_level := shelter_workbench_level + 1
	if next_level > 5:
		return false
	var cost := int(WORKBENCH_UPGRADE_COSTS.get(next_level, 0))
	if scrap < cost:
		return false
	scrap -= cost
	shelter_workbench_level = next_level
	return true


func try_upgrade_scratcher_bank() -> bool:
	var next_level := scratcher_bank_level + 1
	if next_level > 5:
		return false
	var cost := int(SCRATCHER_UPGRADE_COSTS.get(next_level, 0))
	if scrap < cost:
		return false
	scrap -= cost
	scratcher_bank_level = next_level
	scratcher_multiplier = pow(2.2, float(scratcher_bank_level - 1))
	return true


func get_weapon_count(weapon_id: String) -> int:
	return int(weapon_inventory.get(weapon_id, 0))


func reset_run() -> void:
	player_health = 82
	magazine_ammo = 30
	reserve_ammo = 90
	has_ak = true
	scrap = 80
	weapon_level = 1
	medkits = 0
	canned_food = 0
	fatigue = 0.0
	rescued_workers = 0
	resident_cat_ids.clear()
	assigned_worker_ids.clear()
	mod_component_inventory = {
		"rubber_gasket": 0,
		"scope_lens": 0,
		"magazine_spring": 0,
	}
	weapon_inventory = {"ak47": 1}
	returning_from_shelter = false
	world_time_hours = 9.0
	equipped_weapon_id = "ak47"
	weapon_durability = 100.0
	equipped_weapon_mods.clear()
	equipped_magazine_id = "ak_30rnd"
	equipped_ammo_id = "762_fmj"
	ammo_inventory = {
		"9mm_fmj": 60,
		"45_fmj": 28,
		"762_fmj": 90,
		"12g_buckshot": 12,
	}
	secure_dog_slots = 1
	secure_dog_items.clear()
	shelter_workbench_level = 1
	scratcher_bank_level = 1
	scratcher_multiplier = 1.0
	shelter_last_progress_time = 0
	workbench_repair_active = false
	workbench_repair_weapon_id = "ak47"
	shelter_offline_scrap_pending = 0
	shelter_offline_repair_pending = 0.0
	workbench_starter_parts_claimed = false
	shelter_scrap_fraction = 0.0
	workbench_starter_parts_claimed = false
