extends Node

var map_seed: int = 47291
var raid_serial: int = 0
var player_health: int = 82
var magazine_ammo: int = 30
var reserve_ammo: int = 90
var has_ak: bool = true
var scrap: int = 80
var weapon_level: int = 1
var medkits: int = 0
var canned_food: int = 0
var catnip: float = 0.0
var churu: int = 0
var fatigue: float = 0.0
var rescued_workers: int = 0
var resident_cat_ids: Array[String] = []
var assigned_worker_ids: Array[String] = []
var assigned_catnip_worker_ids: Array[String] = []
var resident_traits: Dictionary = {}
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
var shelter_tier: int = 1
var scratcher_bank_level: int = 1
var scratcher_multiplier: float = 1.0
var catnip_boost_end_time: int = 0
var shelter_last_progress_time: int = 0
var workbench_repair_active: bool = false
var workbench_repair_weapon_id: String = "ak47"
var shelter_offline_scrap_pending: int = 0
var shelter_offline_catnip_pending: float = 0.0
var shelter_offline_repair_pending: float = 0.0
var workbench_starter_parts_claimed: bool = false
var shelter_scrap_fraction: float = 0.0
var shelter_catnip_fraction: float = 0.0
var shelter_food_fraction: float = 0.0
var shelter_return_serial: int = 0
var merchant_last_roll_serial: int = -1
var merchant_status: String = "away"
var merchant_decline_count: int = 0
var weapon_enhancement_levels: Dictionary = {"ak47": 0}
var mod_enhancement_levels: Dictionary = {}
var artisan_pity: int = 0
var selected_raid_zone: String = "jongno_outskirts"
var persistence_enabled: bool = true
var persistence_path: String = SAVE_PATH

const SAVE_PATH := "user://shelter_progress_v2.json"
const MAX_WEAPON_ENHANCEMENT := 99
const ARTISAN_PITY_LIMIT := 10
const RAID_ZONES := {
	"jongno_outskirts": {
		"name": "종로 외곽",
		"description": "낮은 위협도의 폐상가 지대. 통조림과 기초 부품을 확보하기 좋습니다.",
		"required_tier": 1,
		"threat": 0.15,
		"enemy_multiplier": 1.0,
		"boss": false,
		"reward": "통조림 · 기초 부품",
	},
	"namdaemun_market": {
		"name": "남대문 폐시장",
		"description": "무장 약탈자가 상가 통로를 점거한 중위험 구역입니다.",
		"required_tier": 2,
		"threat": 0.35,
		"enemy_multiplier": 1.25,
		"boss": true,
		"reward": "츄르 · 총기 부품",
	},
	"euljiro_depths": {
		"name": "을지로 지하구역",
		"description": "좁은 골목과 지하 통로가 이어지는 고위험 구역입니다.",
		"required_tier": 3,
		"threat": 0.55,
		"enemy_multiplier": 1.55,
		"boss": true,
		"reward": "고급 부품 · 츄르",
	},
	"yongsan_blockade": {
		"name": "용산 봉쇄선",
		"description": "군용 화기와 정예 병력이 남아 있는 봉쇄 구역입니다.",
		"required_tier": 4,
		"threat": 0.78,
		"enemy_multiplier": 1.9,
		"boss": true,
		"reward": "특수 모듈 · 츄르",
	},
	"namsan_core": {
		"name": "남산 오염 핵심부",
		"description": "서울에서 가장 위험한 심야 전투 구역입니다.",
		"required_tier": 5,
		"threat": 1.0,
		"enemy_multiplier": 2.3,
		"boss": true,
		"reward": "최상급 부품 · 대량 츄르",
	},
}

const WORKBENCH_UPGRADE_COSTS := {2: 180, 3: 420, 4: 900, 5: 1800}
const SCRATCHER_UPGRADE_COSTS := {2: 120, 3: 320, 4: 850, 5: 1600}
const SHELTER_CAPACITY_BY_TIER := {1: 5, 2: 10, 3: 20, 4: 35, 5: 50}
const KNEADING_SLOTS_BY_TIER := {1: 3, 2: 6, 3: 10, 4: 15, 5: 20}
const CATNIP_SLOTS_BY_TIER := {1: 1, 2: 2, 3: 3, 4: 4, 5: 5}
const SHELTER_UPGRADE_COSTS := {
	2: {"scrap": 1200, "churu": 1},
	3: {"scrap": 6000, "churu": 2},
	4: {"scrap": 30000, "churu": 4},
	5: {"scrap": 160000, "churu": 8},
}
const CATNIP_BOOST_COST := 25.0
const CATNIP_BOOST_DURATION_SECONDS := 600
const CATNIP_BOOST_MULTIPLIER := 10.0
const BASE_SCRAP_PER_WORKER_HOUR := 72.0
const BASE_CATNIP_PER_WORKER_HOUR := 3.0
const WORKER_HOURS_PER_CANNED_FOOD := 6.0
const RESIDENT_TRAIT_PRESETS := [
	{"name": "말랑 앞발", "kneading": 1.15, "catnip": 1.00},
	{"name": "초록 코", "kneading": 1.00, "catnip": 1.20},
	{"name": "야무진 발톱", "kneading": 1.08, "catnip": 1.08},
	{"name": "밤샘 체질", "kneading": 1.05, "catnip": 1.10},
	{"name": "평범한 주민", "kneading": 1.00, "catnip": 1.00},
]


func _ready() -> void:
	for argument in OS.get_cmdline_args():
		if str(argument).begins_with("res://tests/"):
			persistence_enabled = false
			break
	load_persistent_state()
	if raid_serial == 0:
		randomize_map()
	process_shelter_progress()


func randomize_map() -> void:
	raid_serial += 1
	var previous_seed := map_seed
	var time_mix := int(Time.get_unix_time_from_system()) ^ Time.get_ticks_msec()
	var candidate := absi(time_mix ^ (raid_serial * 104729) ^ (previous_seed * 31)) % 2_000_000_000
	if candidate == previous_seed:
		candidate = (candidate + 104729) % 2_000_000_000
	map_seed = candidate


func start_new_raid() -> void:
	process_shelter_progress()
	randomize_map()
	world_time_hours = 9.0
	save_persistent_state()


func register_shelter_return() -> void:
	shelter_return_serial += 1
	save_persistent_state()


func get_raid_zone(zone_id: String = "") -> Dictionary:
	var resolved_id := selected_raid_zone if zone_id.is_empty() else zone_id
	return (RAID_ZONES.get(resolved_id, RAID_ZONES["jongno_outskirts"]) as Dictionary).duplicate(true)


func get_raid_zone_ids() -> Array[String]:
	var result: Array[String] = []
	for zone_id in RAID_ZONES.keys():
		result.append(str(zone_id))
	result.sort_custom(func(a: String, b: String) -> bool:
		return int((RAID_ZONES[a] as Dictionary).get("required_tier", 1)) < int((RAID_ZONES[b] as Dictionary).get("required_tier", 1))
	)
	return result


func is_raid_zone_unlocked(zone_id: String) -> bool:
	if not RAID_ZONES.has(zone_id):
		return false
	return shelter_tier >= int((RAID_ZONES[zone_id] as Dictionary).get("required_tier", 1))


func select_raid_zone(zone_id: String) -> bool:
	if not is_raid_zone_unlocked(zone_id):
		return false
	selected_raid_zone = zone_id
	save_persistent_state()
	return true


func roll_merchant_visit(chance: float = 0.38) -> bool:
	if merchant_status == "inside" or merchant_status == "waiting":
		return true
	if shelter_return_serial <= 0 or merchant_last_roll_serial == shelter_return_serial:
		return false
	merchant_last_roll_serial = shelter_return_serial
	var random := RandomNumberGenerator.new()
	random.seed = int(map_seed) ^ (shelter_return_serial * 982451653) ^ 0x4D455243
	if random.randf() <= clampf(chance, 0.0, 1.0):
		merchant_status = "waiting"
		return true
	return false


func accept_merchant_visit() -> void:
	merchant_status = "inside"


func decline_merchant_visit() -> void:
	merchant_status = "away"
	merchant_decline_count += 1


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
	return resident_cat_ids.size()


func get_resident_capacity() -> int:
	return int(SHELTER_CAPACITY_BY_TIER.get(shelter_tier, 5))


func get_available_resident_slots() -> int:
	_ensure_resident_records()
	return maxi(0, get_resident_capacity() - resident_cat_ids.size())


func try_add_rescued_workers(amount: int) -> int:
	var accepted := mini(maxi(amount, 0), get_available_resident_slots())
	if accepted <= 0:
		return 0
	rescued_workers += accepted
	_ensure_resident_records()
	return accepted


func get_scratcher_worker_slots() -> int:
	return int(KNEADING_SLOTS_BY_TIER.get(shelter_tier, 3))


func get_catnip_worker_slots() -> int:
	return int(CATNIP_SLOTS_BY_TIER.get(shelter_tier, 1))


func get_active_scratcher_workers() -> int:
	_ensure_resident_records()
	_sanitize_assigned_workers()
	return mini(assigned_worker_ids.size(), get_scratcher_worker_slots())


func get_active_catnip_workers() -> int:
	_ensure_resident_records()
	_sanitize_assigned_workers()
	return mini(assigned_catnip_worker_ids.size(), get_catnip_worker_slots())


func get_resident_trait(worker_id: String) -> Dictionary:
	_ensure_resident_records()
	return (resident_traits.get(worker_id, RESIDENT_TRAIT_PRESETS[4]) as Dictionary).duplicate(true)


func get_resident_trait_label(worker_id: String) -> String:
	var trait_data := get_resident_trait(worker_id)
	return "%s · 꾹꾹이 +%d%% · 캣닢 +%d%%" % [
		str(trait_data.get("name", "평범한 주민")),
		roundi((float(trait_data.get("kneading", 1.0)) - 1.0) * 100.0),
		roundi((float(trait_data.get("catnip", 1.0)) - 1.0) * 100.0),
	]


func get_kneading_efficiency_total() -> float:
	var total := 0.0
	for worker_id in assigned_worker_ids:
		total += float(get_resident_trait(worker_id).get("kneading", 1.0))
	return total


func get_catnip_efficiency_total() -> float:
	var total := 0.0
	for worker_id in assigned_catnip_worker_ids:
		total += float(get_resident_trait(worker_id).get("catnip", 1.0))
	return total


func get_catnip_boost_remaining() -> int:
	return maxi(0, catnip_boost_end_time - int(Time.get_unix_time_from_system()))


func is_catnip_boost_active() -> bool:
	return get_catnip_boost_remaining() > 0


func get_production_multiplier() -> float:
	return CATNIP_BOOST_MULTIPLIER if is_catnip_boost_active() else 1.0


func activate_catnip_boost() -> bool:
	process_shelter_progress()
	if catnip < CATNIP_BOOST_COST:
		return false
	catnip -= CATNIP_BOOST_COST
	catnip_boost_end_time = int(Time.get_unix_time_from_system()) + CATNIP_BOOST_DURATION_SECONDS
	return true


func get_scrap_per_hour() -> float:
	return get_base_scrap_per_hour() * get_production_multiplier()


func get_base_scrap_per_hour() -> float:
	if get_active_scratcher_workers() > 0 and canned_food <= 0:
		return 0.0
	return get_kneading_efficiency_total() * BASE_SCRAP_PER_WORKER_HOUR * scratcher_multiplier


func get_scrap_per_second() -> float:
	return get_scrap_per_hour() / 3600.0


func get_catnip_per_hour() -> float:
	if get_active_catnip_workers() > 0 and canned_food <= 0:
		return 0.0
	return get_catnip_efficiency_total() * BASE_CATNIP_PER_WORKER_HOUR


func get_catnip_per_second() -> float:
	return get_catnip_per_hour() / 3600.0


func tick_shelter_live(delta: float) -> int:
	var safe_delta := maxf(delta, 0.0)
	var scrap_rate := get_scrap_per_second()
	var catnip_rate := get_catnip_per_second()
	var work_delta := _consume_worker_food_for_duration(safe_delta)
	var gain := scrap_rate * work_delta
	var catnip_gain := catnip_rate * work_delta
	shelter_scrap_fraction += gain
	shelter_catnip_fraction += catnip_gain
	if shelter_catnip_fraction >= 0.01:
		catnip += shelter_catnip_fraction
		shelter_catnip_fraction = 0.0
	var whole := int(floor(shelter_scrap_fraction))
	if whole <= 0:
		return 0
	shelter_scrap_fraction -= float(whole)
	scrap += whole
	return whole


func _ensure_resident_records() -> void:
	while resident_cat_ids.size() < rescued_workers:
		var next_index := resident_cat_ids.size() + 1
		var resident_id := "resident_%03d" % next_index
		resident_cat_ids.append(resident_id)
		resident_traits[resident_id] = RESIDENT_TRAIT_PRESETS[(next_index - 1) % RESIDENT_TRAIT_PRESETS.size()].duplicate(true)
	if resident_cat_ids.size() > rescued_workers:
		resident_cat_ids.resize(rescued_workers)
	for resident_id in resident_cat_ids:
		if not resident_traits.has(resident_id):
			var resident_index := maxi(0, int(resident_id.trim_prefix("resident_")) - 1)
			resident_traits[resident_id] = RESIDENT_TRAIT_PRESETS[resident_index % RESIDENT_TRAIT_PRESETS.size()].duplicate(true)
	_sanitize_assigned_workers()


func _sanitize_assigned_workers() -> void:
	var cleaned: Array[String] = []
	for worker_id in assigned_worker_ids:
		if cleaned.size() >= get_scratcher_worker_slots():
			break
		if resident_cat_ids.has(worker_id) and not cleaned.has(worker_id):
			cleaned.append(worker_id)
	assigned_worker_ids = cleaned
	var cleaned_catnip: Array[String] = []
	for worker_id in assigned_catnip_worker_ids:
		if cleaned_catnip.size() >= get_catnip_worker_slots():
			break
		if resident_cat_ids.has(worker_id) and not cleaned.has(worker_id) and not cleaned_catnip.has(worker_id):
			cleaned_catnip.append(worker_id)
	assigned_catnip_worker_ids = cleaned_catnip


func assign_worker_to_scratcher(worker_id: String) -> bool:
	_ensure_resident_records()
	if not resident_cat_ids.has(worker_id):
		return false
	if assigned_worker_ids.has(worker_id):
		return true
	if assigned_worker_ids.size() >= get_scratcher_worker_slots():
		return false
	assigned_catnip_worker_ids.erase(worker_id)
	assigned_worker_ids.append(worker_id)
	return true


func unassign_worker_from_scratcher(worker_id: String) -> void:
	assigned_worker_ids.erase(worker_id)


func toggle_worker_assignment(worker_id: String) -> bool:
	if assigned_worker_ids.has(worker_id):
		unassign_worker_from_scratcher(worker_id)
		return false
	return assign_worker_to_scratcher(worker_id)


func assign_worker_to_catnip(worker_id: String) -> bool:
	_ensure_resident_records()
	if not resident_cat_ids.has(worker_id):
		return false
	if assigned_catnip_worker_ids.has(worker_id):
		return true
	if assigned_catnip_worker_ids.size() >= get_catnip_worker_slots():
		return false
	assigned_worker_ids.erase(worker_id)
	assigned_catnip_worker_ids.append(worker_id)
	return true


func unassign_worker_from_catnip(worker_id: String) -> void:
	assigned_catnip_worker_ids.erase(worker_id)


func toggle_catnip_worker_assignment(worker_id: String) -> bool:
	if assigned_catnip_worker_ids.has(worker_id):
		unassign_worker_from_catnip(worker_id)
		return false
	return assign_worker_to_catnip(worker_id)


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
		return {"scrap": 0, "catnip": 0.0, "repair": 0.0, "elapsed": 0}
	var progress_start := shelter_last_progress_time
	var elapsed := maxi(0, now - shelter_last_progress_time)
	shelter_last_progress_time = now
	var base_scrap_rate := get_base_scrap_per_hour()
	var catnip_rate := get_catnip_per_hour()
	var work_seconds := _consume_worker_food_for_duration(float(elapsed))
	var base_scrap_gain := base_scrap_rate * work_seconds / 3600.0
	var boosted_seconds := mini(roundi(work_seconds), maxi(0, mini(now, catnip_boost_end_time) - progress_start))
	var boosted_extra := base_scrap_rate * float(boosted_seconds) / 3600.0 * (CATNIP_BOOST_MULTIPLIER - 1.0)
	shelter_scrap_fraction += base_scrap_gain + boosted_extra
	var scrap_gain := int(floor(shelter_scrap_fraction))
	shelter_scrap_fraction -= float(scrap_gain)
	var catnip_gain := catnip_rate * work_seconds / 3600.0
	catnip += catnip_gain
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
	shelter_offline_catnip_pending += catnip_gain
	shelter_offline_repair_pending += repair_gain
	return {"scrap": scrap_gain, "catnip": catnip_gain, "repair": repair_gain, "elapsed": elapsed}


func _consume_worker_food_for_duration(requested_seconds: float) -> float:
	var worker_count := get_active_scratcher_workers() + get_active_catnip_workers()
	if worker_count <= 0 or requested_seconds <= 0.0:
		return maxf(requested_seconds, 0.0)
	if canned_food <= 0:
		return 0.0
	var food_per_second := float(worker_count) / (WORKER_HOURS_PER_CANNED_FOOD * 3600.0)
	var available_food := float(canned_food) - shelter_food_fraction
	var work_seconds := minf(requested_seconds, available_food / food_per_second)
	shelter_food_fraction += work_seconds * food_per_second
	var consumed := mini(canned_food, int(floor(shelter_food_fraction)))
	if consumed > 0:
		canned_food -= consumed
		shelter_food_fraction -= float(consumed)
	return work_seconds


func consume_offline_progress_notice() -> Dictionary:
	var notice := {
		"scrap": shelter_offline_scrap_pending,
		"catnip": shelter_offline_catnip_pending,
		"repair": shelter_offline_repair_pending,
	}
	shelter_offline_scrap_pending = 0
	shelter_offline_catnip_pending = 0.0
	shelter_offline_repair_pending = 0.0
	return notice


func get_shelter_upgrade_cost() -> Dictionary:
	return (SHELTER_UPGRADE_COSTS.get(shelter_tier + 1, {}) as Dictionary).duplicate(true)


func try_upgrade_shelter_tier() -> bool:
	var next_tier := shelter_tier + 1
	if next_tier > 5:
		return false
	var cost := SHELTER_UPGRADE_COSTS.get(next_tier, {}) as Dictionary
	var scrap_cost := int(cost.get("scrap", 0))
	var churu_cost := int(cost.get("churu", 0))
	if scrap < scrap_cost or churu < churu_cost:
		return false
	scrap -= scrap_cost
	churu -= churu_cost
	shelter_tier = next_tier
	_sanitize_assigned_workers()
	save_persistent_state()
	return true


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


func get_weapon_enhancement_level(weapon_id: String) -> int:
	return clampi(int(weapon_enhancement_levels.get(weapon_id, 0)), 0, MAX_WEAPON_ENHANCEMENT)


func get_weapon_enhancement_cost(weapon_id: String) -> int:
	var level := get_weapon_enhancement_level(weapon_id)
	if level >= MAX_WEAPON_ENHANCEMENT:
		return 0
	var weapon_factor := 1.0
	match weapon_id:
		"mp5": weapon_factor = 1.2
		"ak47": weapon_factor = 1.55
		"double_barrel": weapon_factor = 1.4
	return maxi(25, roundi(55.0 * weapon_factor * pow(1.082, float(level))))


func try_enhance_weapon(weapon_id: String) -> bool:
	if get_weapon_count(weapon_id) <= 0:
		return false
	var level := get_weapon_enhancement_level(weapon_id)
	if level >= MAX_WEAPON_ENHANCEMENT:
		return false
	var cost := get_weapon_enhancement_cost(weapon_id)
	if scrap < cost:
		return false
	scrap -= cost
	weapon_enhancement_levels[weapon_id] = level + 1
	if weapon_id == equipped_weapon_id:
		weapon_level = level + 2
	save_persistent_state()
	return true


func get_mod_enhancement_level(mod_id: String) -> int:
	return clampi(int(mod_enhancement_levels.get(mod_id, 0)), 0, MAX_WEAPON_ENHANCEMENT)


func get_mod_enhancement_cost(mod_id: String) -> int:
	var level := get_mod_enhancement_level(mod_id)
	if level >= MAX_WEAPON_ENHANCEMENT:
		return 0
	return maxi(20, roundi(38.0 * pow(1.078, float(level))))


func try_enhance_mod(mod_id: String) -> bool:
	if not equipped_weapon_mods.has(mod_id):
		return false
	var level := get_mod_enhancement_level(mod_id)
	if level >= MAX_WEAPON_ENHANCEMENT:
		return false
	var cost := get_mod_enhancement_cost(mod_id)
	if scrap < cost:
		return false
	scrap -= cost
	mod_enhancement_levels[mod_id] = level + 1
	save_persistent_state()
	return true


func get_artisan_roll_cost() -> Dictionary:
	return {
		"scrap": 180 + maxi(0, shelter_tier - 1) * 85,
		"canned_food": 2 + int(floor(float(shelter_tier - 1) / 2.0)),
	}


func roll_artisan_weapon() -> Dictionary:
	var cost := get_artisan_roll_cost()
	if scrap < int(cost["scrap"]) or canned_food < int(cost["canned_food"]):
		return {}
	scrap -= int(cost["scrap"])
	canned_food -= int(cost["canned_food"])
	artisan_pity += 1
	var pool: Array[String] = ["m1911", "mp5"]
	if shelter_tier >= 2:
		pool.append("ak47")
	if shelter_tier >= 3:
		pool.append("double_barrel")
	var guaranteed := artisan_pity >= ARTISAN_PITY_LIMIT
	var result_id := pool[pool.size() - 1] if guaranteed else pool[randi() % pool.size()]
	if guaranteed:
		artisan_pity = 0
	add_weapon(result_id, 1)
	if not weapon_enhancement_levels.has(result_id):
		weapon_enhancement_levels[result_id] = 0
	var result := {
		"weapon_id": result_id,
		"guaranteed": guaranteed,
		"pity": artisan_pity,
	}
	save_persistent_state()
	return result


func save_persistent_state() -> bool:
	if not persistence_enabled:
		return false
	var data := {
		"version": 2,
		"map_seed": map_seed,
		"raid_serial": raid_serial,
		"player_health": player_health,
		"magazine_ammo": magazine_ammo,
		"scrap": scrap,
		"medkits": medkits,
		"canned_food": canned_food,
		"catnip": catnip,
		"churu": churu,
		"fatigue": fatigue,
		"rescued_workers": rescued_workers,
		"resident_cat_ids": resident_cat_ids,
		"assigned_worker_ids": assigned_worker_ids,
		"assigned_catnip_worker_ids": assigned_catnip_worker_ids,
		"resident_traits": resident_traits,
		"mod_component_inventory": mod_component_inventory,
		"weapon_inventory": weapon_inventory,
		"weapon_enhancement_levels": weapon_enhancement_levels,
		"mod_enhancement_levels": mod_enhancement_levels,
		"equipped_weapon_id": equipped_weapon_id,
		"weapon_durability": weapon_durability,
		"equipped_weapon_mods": equipped_weapon_mods,
		"equipped_magazine_id": equipped_magazine_id,
		"equipped_ammo_id": equipped_ammo_id,
		"ammo_inventory": ammo_inventory,
		"shelter_workbench_level": shelter_workbench_level,
		"shelter_tier": shelter_tier,
		"scratcher_bank_level": scratcher_bank_level,
		"scratcher_multiplier": scratcher_multiplier,
		"catnip_boost_end_time": catnip_boost_end_time,
		"shelter_last_progress_time": shelter_last_progress_time,
		"workbench_repair_active": workbench_repair_active,
		"workbench_repair_weapon_id": workbench_repair_weapon_id,
		"workbench_starter_parts_claimed": workbench_starter_parts_claimed,
		"shelter_scrap_fraction": shelter_scrap_fraction,
		"shelter_catnip_fraction": shelter_catnip_fraction,
		"shelter_food_fraction": shelter_food_fraction,
		"shelter_return_serial": shelter_return_serial,
		"merchant_last_roll_serial": merchant_last_roll_serial,
		"merchant_status": merchant_status,
		"merchant_decline_count": merchant_decline_count,
		"artisan_pity": artisan_pity,
		"selected_raid_zone": selected_raid_zone,
	}
	var file := FileAccess.open(persistence_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(data))
	return true


func load_persistent_state() -> bool:
	if not persistence_enabled:
		return false
	if not FileAccess.file_exists(persistence_path):
		return false
	var file := FileAccess.open(persistence_path, FileAccess.READ)
	if file == null:
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		return false
	var data := parsed as Dictionary
	map_seed = int(data.get("map_seed", map_seed))
	raid_serial = int(data.get("raid_serial", raid_serial))
	player_health = int(data.get("player_health", player_health))
	magazine_ammo = int(data.get("magazine_ammo", magazine_ammo))
	scrap = int(data.get("scrap", scrap))
	medkits = int(data.get("medkits", medkits))
	canned_food = int(data.get("canned_food", canned_food))
	catnip = float(data.get("catnip", catnip))
	churu = int(data.get("churu", churu))
	fatigue = float(data.get("fatigue", fatigue))
	rescued_workers = int(data.get("rescued_workers", rescued_workers))
	resident_cat_ids = _to_string_array(data.get("resident_cat_ids", []))
	assigned_worker_ids = _to_string_array(data.get("assigned_worker_ids", []))
	assigned_catnip_worker_ids = _to_string_array(data.get("assigned_catnip_worker_ids", []))
	resident_traits = (data.get("resident_traits", {}) as Dictionary).duplicate(true)
	mod_component_inventory = (data.get("mod_component_inventory", mod_component_inventory) as Dictionary).duplicate(true)
	weapon_inventory = (data.get("weapon_inventory", weapon_inventory) as Dictionary).duplicate(true)
	weapon_enhancement_levels = (data.get("weapon_enhancement_levels", weapon_enhancement_levels) as Dictionary).duplicate(true)
	mod_enhancement_levels = (data.get("mod_enhancement_levels", mod_enhancement_levels) as Dictionary).duplicate(true)
	equipped_weapon_id = str(data.get("equipped_weapon_id", equipped_weapon_id))
	weapon_durability = float(data.get("weapon_durability", weapon_durability))
	equipped_weapon_mods = _to_string_array(data.get("equipped_weapon_mods", []))
	equipped_magazine_id = str(data.get("equipped_magazine_id", equipped_magazine_id))
	equipped_ammo_id = str(data.get("equipped_ammo_id", equipped_ammo_id))
	ammo_inventory = (data.get("ammo_inventory", ammo_inventory) as Dictionary).duplicate(true)
	shelter_workbench_level = clampi(int(data.get("shelter_workbench_level", shelter_workbench_level)), 1, 5)
	shelter_tier = clampi(int(data.get("shelter_tier", shelter_tier)), 1, 5)
	scratcher_bank_level = clampi(int(data.get("scratcher_bank_level", scratcher_bank_level)), 1, 5)
	scratcher_multiplier = float(data.get("scratcher_multiplier", scratcher_multiplier))
	catnip_boost_end_time = int(data.get("catnip_boost_end_time", catnip_boost_end_time))
	shelter_last_progress_time = int(data.get("shelter_last_progress_time", shelter_last_progress_time))
	workbench_repair_active = bool(data.get("workbench_repair_active", workbench_repair_active))
	workbench_repair_weapon_id = str(data.get("workbench_repair_weapon_id", workbench_repair_weapon_id))
	workbench_starter_parts_claimed = bool(data.get("workbench_starter_parts_claimed", workbench_starter_parts_claimed))
	shelter_scrap_fraction = float(data.get("shelter_scrap_fraction", shelter_scrap_fraction))
	shelter_catnip_fraction = float(data.get("shelter_catnip_fraction", shelter_catnip_fraction))
	shelter_food_fraction = float(data.get("shelter_food_fraction", shelter_food_fraction))
	shelter_return_serial = int(data.get("shelter_return_serial", shelter_return_serial))
	merchant_last_roll_serial = int(data.get("merchant_last_roll_serial", merchant_last_roll_serial))
	merchant_status = str(data.get("merchant_status", merchant_status))
	merchant_decline_count = int(data.get("merchant_decline_count", merchant_decline_count))
	artisan_pity = clampi(int(data.get("artisan_pity", artisan_pity)), 0, ARTISAN_PITY_LIMIT - 1)
	selected_raid_zone = str(data.get("selected_raid_zone", selected_raid_zone))
	if not RAID_ZONES.has(selected_raid_zone) or not is_raid_zone_unlocked(selected_raid_zone):
		selected_raid_zone = "jongno_outskirts"
	_ensure_resident_records()
	reserve_ammo = get_ammo_count(equipped_ammo_id)
	return true


func _to_string_array(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if value is Array:
		for item in value:
			result.append(str(item))
	return result


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_PREDELETE:
		save_persistent_state()


func reset_run() -> void:
	player_health = 82
	raid_serial = 0
	magazine_ammo = 30
	reserve_ammo = 90
	has_ak = true
	scrap = 80
	weapon_level = 1
	medkits = 0
	canned_food = 0
	catnip = 0.0
	churu = 0
	fatigue = 0.0
	rescued_workers = 0
	resident_cat_ids.clear()
	assigned_worker_ids.clear()
	assigned_catnip_worker_ids.clear()
	resident_traits.clear()
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
	shelter_tier = 1
	scratcher_bank_level = 1
	scratcher_multiplier = 1.0
	catnip_boost_end_time = 0
	shelter_last_progress_time = 0
	workbench_repair_active = false
	workbench_repair_weapon_id = "ak47"
	shelter_offline_scrap_pending = 0
	shelter_offline_catnip_pending = 0.0
	shelter_offline_repair_pending = 0.0
	workbench_starter_parts_claimed = false
	shelter_scrap_fraction = 0.0
	shelter_catnip_fraction = 0.0
	shelter_food_fraction = 0.0
	workbench_starter_parts_claimed = false
	shelter_return_serial = 0
	merchant_last_roll_serial = -1
	merchant_status = "away"
	merchant_decline_count = 0
	weapon_enhancement_levels = {"ak47": 0}
	mod_enhancement_levels.clear()
	artisan_pity = 0
	selected_raid_zone = "jongno_outskirts"
