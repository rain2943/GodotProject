extends SceneTree

const BUILDING_SCENE := preload("res://scenes/building_interior.tscn")
const ENTRANCE_SCENE := preload("res://scenes/modules/building_entrance_portal.tscn")
var BuildingRunState: Node

class TestGameState:
	extends Node
	var map_seed := 47291
	var player_health := 82
	var magazine_ammo := 30
	var reserve_ammo := 90
	var scrap := 80
	var mod_component_inventory := {
		"rubber_gasket": 0,
		"scope_lens": 0,
		"magazine_spring": 0,
	}


func _initialize() -> void:
	var game_state := root.get_node_or_null("GameState")
	if game_state == null:
		game_state = TestGameState.new()
		game_state.name = "GameState"
		root.add_child(game_state)
	BuildingRunState = root.get_node_or_null("BuildingRunState")
	if BuildingRunState == null:
		BuildingRunState = preload("res://scripts/building_run_state.gd").new()
		BuildingRunState.name = "BuildingRunState"
		root.add_child(BuildingRunState)
	BuildingRunState.begin_run(
		"smoke_test_tower",
		829173,
		"res://scenes/main.tscn",
		Vector3(3, 0.78, 4),
		5
	)
	var interior := BUILDING_SCENE.instantiate()
	root.add_child(interior)
	await process_frame
	await process_frame
	_assert(interior.get_node_or_null("Floor01Modules") != null, "1층 모듈 루트가 생성되어야 합니다.")
	_assert(get_nodes_in_group("building_room_module").size() == 8, "한 층은 방 모듈 8개로 구성되어야 합니다.")
	_assert(get_nodes_in_group("building_loot_module").size() >= 4, "전리품 모듈이 생성되어야 합니다.")
	_assert(get_nodes_in_group("building_transition_module").size() >= 3, "출구·엘리베이터·계단이 생성되어야 합니다.")
	var entrance := ENTRANCE_SCENE.instantiate()
	root.add_child(entrance)
	await process_frame
	_assert(entrance.is_in_group("building_entrance_portal"), "필드 건물에 부착할 입구 포탈 모듈이 필요합니다.")
	var first_seed: int = int(BuildingRunState.call("get_floor_seed", 2))
	_assert(first_seed == BuildingRunState.get_floor_seed(2), "층별 시드는 재진입해도 같아야 합니다.")
	BuildingRunState.mark_loot_collected(2, "test_loot")
	_assert(BuildingRunState.is_loot_collected(2, "test_loot"), "수집한 전리품 상태가 층별로 보존되어야 합니다.")
	interior.call("_load_floor", 2, "from_below")
	await process_frame
	await process_frame
	_assert(interior.get_node_or_null("Floor02Modules") != null, "엘리베이터/계단 전환 시 2층 모듈이 생성되어야 합니다.")
	_assert(int(BuildingRunState.current_floor) == 2, "현재 층 상태가 전환 결과를 따라야 합니다.")
	print("BUILDING_INTERIOR_SMOKE_OK rooms=8 floor_seed=", first_seed)
	interior.free()
	entrance.free()
	quit(0)


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	quit(1)
