extends SceneTree

const GAMEPLAY_LEVEL_PATHS: Array[String] = [
	"res://scene/level/Level01.tscn",
	"res://scene/level/Level02.tscn",
	"res://scene/level/Level03.tscn",
	"res://scene/level/Level04.tscn",
	"res://scene/level/Level05.tscn",
]
const PROP_SCENE := preload("res://scene/props/interactive_item.tscn")
const SYMMETRY_CHECKER_SCRIPT := preload("res://script/symmetry_checker.gd")

var passed: int = 0
var failed: int = 0


func _initialize() -> void:
	await run_tests()
	print("Room2System Test Summary: %d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)


func run_tests() -> void:
	await process_frame

	var tests: Array[String] = [
		"test_progression_counts",
		"test_min_pass_scores",
		"test_symmetry_checker_all_levels",
		"test_grounded_and_stacked_invariants",
		"test_jittered_grid_fallback",
		"test_cleanup_and_rerandomization",
		"test_all_gameplay_level_scenes_and_physics",
		"test_drag_and_drop_mechanics",
		"test_player_climb_and_stepping_stone",
		"test_measure_tool_and_drag_coexistence",
	]

	for test_name in tests:
		var result: Variant = await call(test_name)
		if result != true:
			failed += 1
			push_error("FAIL %s: did not finish cleanly (returned %s)" % [test_name, str(result)])


func assert_eq(actual: Variant, expected: Variant, label: String) -> void:
	if actual == expected:
		passed += 1
	else:
		failed += 1
		push_error("FAIL %s: expected %s, got %s" % [label, str(expected), str(actual)])


func assert_true(cond: bool, label: String) -> void:
	if cond:
		passed += 1
	else:
		failed += 1
		push_error("FAIL %s: condition was false" % label)


func test_progression_counts() -> bool:
	var expected := {1: 1, 2: 2, 3: 4, 4: 7, 5: 11}
	for lvl: int in expected:
		assert_eq(LevelProgression.get_total_objects(lvl), expected[lvl], "TC-01 total_objects L%d" % lvl)
	return true


func test_min_pass_scores() -> bool:
	var expected := {1: 1, 2: 1, 4: 3, 7: 5, 11: 8}
	for total: int in expected:
		assert_eq(LevelProgression.get_min_pass_score(total), expected[total], "TC-09..13 min_pass_score(%d)" % total)
	return true


func _build_eval_rig(total_count: int, correct_count: int) -> Dictionary:
	var container := Node2D.new()
	root.add_child(container)

	var checker := Node.new()
	checker.name = "SymmetryChecker"
	checker.set_script(SYMMETRY_CHECKER_SCRIPT)
	container.add_child(checker)

	for i in range(total_count):
		var id := "item_%02d" % i
		var x_pos: float = -20.0 - float(i) * 14.0
		var y_pos: float = -12.0

		var r1 := PROP_SCENE.instantiate() as InteractiveItem
		r1.item_id = id
		r1.override_home_room = 1
		r1.hold_until_dragged = true
		r1.position = Vector2(x_pos, y_pos)
		container.add_child(r1)

		var r2 := PROP_SCENE.instantiate() as InteractiveItem
		r2.item_id = id
		r2.override_home_room = 2
		r2.hold_until_dragged = true
		if i < correct_count:
			r2.position = Vector2(-x_pos, y_pos)
		else:
			r2.position = Vector2(-x_pos + 30.0, y_pos)
		container.add_child(r2)

	return {"container": container, "checker": checker}


func test_symmetry_checker_all_levels() -> bool:
	var cases: Array[Array] = [
		[1, 0, "game_over", false],
		[1, 1, "success", true],
		[2, 0, "game_over", false],
		[2, 1, "success", true],
		[2, 2, "success", true],
		[4, 2, "game_over", false],
		[4, 3, "success", true],
		[4, 4, "success", true],
		[7, 4, "game_over", false],
		[7, 5, "success", true],
		[7, 7, "success", true],
		[11, 7, "game_over", false],
		[11, 8, "success", true],
		[11, 11, "success", true],
	]

	for c in cases:
		var total_count: int = c[0]
		var correct_count: int = c[1]
		var expected_status: String = c[2]
		var expected_passed: bool = c[3]

		var rig: Dictionary = _build_eval_rig(total_count, correct_count)
		var container: Node2D = rig["container"]
		var checker: Node = rig["checker"]
		var eval: Dictionary = checker.call("hitung_evaluasi")

		assert_eq(eval.get("status", ""), expected_status, "Eval status %d/%d" % [correct_count, total_count])
		assert_eq(eval.get("passed", null), expected_passed, "Eval passed %d/%d" % [correct_count, total_count])
		container.queue_free()

	await process_frame
	return true


func _validate_grounded_spatial_invariants(spawner: Room2Spawner, level: int, iteration: int) -> bool:
	var expected_count: int = LevelProgression.get_total_objects(level)
	var records: Array[Dictionary] = spawner.last_spawn_records
	assert_eq(records.size(), expected_count, "Spatial count L%d iter %d" % [level, iteration])

	var exclusion_radius: float = spawner.player_exclusion_radius
	if exclusion_radius <= 0.0:
		exclusion_radius = maxf(24.0, (maxf(spawner.object_size.x, spawner.object_size.y) + spawner.min_gap) * 1.25)

	var any_stacked: bool = false
	for idx in range(records.size()):
		var rec: Dictionary = records[idx]
		var pos: Vector2 = rec["pos"]
		var left: float = float(rec["left"])
		var right: float = float(rec["right"])
		var top: float = float(rec["top"])
		var bottom: float = float(rec["bottom"])
		var support_idx: int = int(rec["support_index"])

		# Safe Spawn Area (walls, ceiling, floor)
		assert_true(left >= spawner.room_rect.position.x + spawner.wall_padding - 0.01, "Left wall padding L%d iter %d idx %d" % [level, iteration, idx])
		assert_true(right <= spawner.room_rect.end.x - spawner.wall_padding + 0.01, "Right wall padding L%d iter %d idx %d" % [level, iteration, idx])
		assert_true(top >= spawner.room_rect.position.y + spawner.wall_padding - 0.01, "Ceiling wall padding L%d iter %d idx %d" % [level, iteration, idx])
		assert_true(bottom <= spawner.room_rect.end.y + 0.5, "Floor boundary L%d iter %d idx %d" % [level, iteration, idx])

		# Player spawn exclusion zone
		var dist_player: float = pos.distance_to(spawner.player_spawn_position)
		assert_true(dist_player >= exclusion_radius - 0.01, "Player exclusion L%d iter %d idx %d (dist=%.2f)" % [level, iteration, idx, dist_player])

		# Zero floating: must rest flush on floor OR flush on a valid support object
		if support_idx < 0:
			assert_true(absf(bottom - spawner.room_rect.end.y) <= 0.5, "Grounded on floor L%d iter %d idx %d (bottom=%.2f)" % [level, iteration, idx, bottom])
		else:
			any_stacked = true
			assert_true(support_idx < records.size() and support_idx != idx, "Valid support index L%d iter %d idx %d" % [level, iteration, idx])
			var sup: Dictionary = records[support_idx]
			assert_true(bool(sup["can_support_stack"]), "Support allows stacking L%d iter %d idx %d" % [level, iteration, idx])
			assert_true(absf(bottom - float(sup["surface_y"])) <= 0.5, "Flush on support surface L%d iter %d idx %d" % [level, iteration, idx])

		# Zero overlap against all non-supporting items
		for other_idx in range(idx + 1, records.size()):
			if int(records[other_idx]["support_index"]) == idx or support_idx == other_idx:
				continue
			var other: Dictionary = records[other_idx]
			var v_overlap: bool = (top < float(other["bottom"]) - 0.5) and (bottom > float(other["top"]) + 0.5)
			var h_overlap: bool = (left < float(other["right"]) + spawner.min_gap - 0.01) and (right > float(other["left"]) - spawner.min_gap + 0.01)
			assert_true(not (v_overlap and h_overlap), "No overlap L%d iter %d (%d vs %d)" % [level, iteration, idx, other_idx])

	return any_stacked


func test_grounded_and_stacked_invariants() -> bool:
	var host := Node2D.new()
	root.add_child(host)

	var spawner := Room2Spawner.new()
	spawner.auto_spawn_on_ready = false
	spawner.object_scene = PROP_SCENE
	host.add_child(spawner)

	var stacked_observed_high_levels: bool = false
	for lvl in range(1, 6):
		for iter in range(25):
			spawner.spawn_level_objects(lvl, spawner.player_spawn_position)
			var has_stack: bool = _validate_grounded_spatial_invariants(spawner, lvl, iter)
			if lvl >= 4 and has_stack:
				stacked_observed_high_levels = true

	assert_true(stacked_observed_high_levels, "Natural stacking observed in Levels 4-5")

	host.queue_free()
	await process_frame
	return true


func test_jittered_grid_fallback() -> bool:
	var host := Node2D.new()
	root.add_child(host)

	# Case 1: Force fallback in standard Room 2 bounds with max_attempts = 1
	var spawner := Room2Spawner.new()
	spawner.auto_spawn_on_ready = false
	spawner.object_scene = PROP_SCENE
	spawner.max_attempts = 1
	host.add_child(spawner)

	for iter in range(10):
		spawner.spawn_level_objects(5, spawner.player_spawn_position)
		assert_true(spawner.last_spawn_used_fallback, "Fallback triggered iter %d" % iter)
		_validate_grounded_spatial_invariants(spawner, 5, iter)

	# Case 2: Wide room dimensions with max_attempts = 1
	var large_spawner := Room2Spawner.new()
	large_spawner.auto_spawn_on_ready = false
	large_spawner.object_scene = PROP_SCENE
	large_spawner.room_rect = Rect2(0.0, -500.0, 800.0, 500.0)
	large_spawner.wall_padding = 24.0
	large_spawner.min_gap = 20.0
	large_spawner.max_attempts = 1
	large_spawner.player_spawn_position = Vector2(100.0, -16.0)
	host.add_child(large_spawner)

	large_spawner.spawn_level_objects(5, large_spawner.player_spawn_position)
	assert_true(large_spawner.last_spawn_used_fallback, "Large room fallback triggered")
	_validate_grounded_spatial_invariants(large_spawner, 5, 0)

	host.queue_free()
	await process_frame
	return true


func test_cleanup_and_rerandomization() -> bool:
	var host := Node2D.new()
	root.add_child(host)

	var spawner := Room2Spawner.new()
	spawner.auto_spawn_on_ready = false
	spawner.object_scene = PROP_SCENE
	host.add_child(spawner)

	var layouts: Array[Array] = []
	for i in range(10):
		spawner.spawn_level_objects(3, spawner.player_spawn_position)
		assert_eq(spawner.get_child_count(), 4, "TC-06/TC-08 exact child count after rapid respawn %d" % i)
		layouts.append(spawner.last_spawn_positions.duplicate())

	var any_different: bool = false
	for i in range(1, layouts.size()):
		if layouts[i] != layouts[0]:
			any_different = true
			break
	assert_true(any_different, "TC-05/TC-07 layout changes across respawns")

	host.queue_free()
	await process_frame
	return true


func test_all_gameplay_level_scenes_and_physics() -> bool:
	var gm := root.get_node_or_null("GameManager")
	var orig_level: int = int(gm.get("current_level")) if gm else 1
	var orig_unlocked: int = int(gm.get("unlocked_level")) if gm else 1
	var orig_replaying: bool = bool(gm.get("is_replaying")) if gm else false

	for idx in range(GAMEPLAY_LEVEL_PATHS.size()):
		var lvl: int = idx + 1
		var scene_path: String = GAMEPLAY_LEVEL_PATHS[idx]
		if gm:
			gm.set("current_level", lvl)
			gm.set("is_replaying", true)

		var packed := load(scene_path) as PackedScene
		assert_true(packed != null, "%s loads cleanly" % scene_path)
		if not packed:
			return false

		var change_err: Error = change_scene_to_packed(packed)
		assert_eq(change_err, OK, "change_scene_to_packed(%s) succeeds" % scene_path)
		await process_frame
		await process_frame

		var level := current_scene as Node2D
		assert_true(level != null, "current_scene is %s" % scene_path)
		if not level:
			return false

		var player := level.get_node_or_null("Player") as CharacterBody2D
		assert_true(player != null, "Player exists in L%d" % lvl)
		if player:
			assert_eq(player.collision_mask, 3, "Player detects floor + climbable Layer 2 props (collision_mask == 3) L%d" % lvl)
			assert_eq(player.get("jump_velocity"), -185.0, "Player jump_velocity tuned to -185.0 L%d" % lvl)

		# Verify locked Camera2D parameters (TC-16)
		var camera := level.get_node_or_null("Player/Camera2D") as Camera2D
		assert_true(camera != null, "Player/Camera2D exists in L%d" % lvl)
		if camera:
			assert_eq(camera.zoom, Vector2(6.5, 6.5), "Camera zoom unchanged L%d" % lvl)
			assert_eq(camera.limit_left, -204, "Camera limit_left unchanged L%d" % lvl)
			assert_eq(camera.limit_top, -96, "Camera limit_top unchanged L%d" % lvl)
			assert_eq(camera.limit_right, -4, "Camera limit_right unchanged L%d" % lvl)
			assert_eq(camera.limit_bottom, 3, "Camera limit_bottom unchanged L%d" % lvl)
			assert_eq(camera.position_smoothing_enabled, true, "Camera smoothing unchanged L%d" % lvl)

		# Verify locked RoomBoundaries dimensions (TC-17)
		var expected_bounds := {
			"FloorCollision": [Vector2(0, 10), Vector2(400, 20)],
			"LeftWall": [Vector2(-210, -48), Vector2(20, 96)],
			"RightWall": [Vector2(210, -48), Vector2(20, 96)],
			"CenterWall": [Vector2(0, -48), Vector2(10, 96)],
			"Ceiling": [Vector2(0, -106), Vector2(400, 20)],
		}
		for b_name: String in expected_bounds:
			var col := level.get_node_or_null("RoomBoundaries/" + b_name) as CollisionShape2D
			assert_true(col != null, "RoomBoundaries/%s exists L%d" % [b_name, lvl])
			if col and col.shape is RectangleShape2D:
				var rect := col.shape as RectangleShape2D
				assert_eq(col.position, expected_bounds[b_name][0], "%s position unchanged L%d" % [b_name, lvl])
				assert_eq(rect.size, expected_bounds[b_name][1], "%s size unchanged L%d" % [b_name, lvl])

		# Verify locked Smartphone UI presence (TC-15)
		var smartphone := level.get_node_or_null("Smartphone")
		assert_true(smartphone != null, "Smartphone UI exists L%d" % lvl)
		if smartphone:
			assert_true(smartphone.get_node_or_null("HUDPhoneButton") != null, "HUDPhoneButton exists L%d" % lvl)
			assert_true(smartphone.get_node_or_null("TimerLabel") != null, "TimerLabel exists L%d" % lvl)
			assert_true(smartphone.get_node_or_null("PhoneContainer/PhoneFrame/MainMenu") != null, "MainMenu exists L%d" % lvl)
			assert_true(smartphone.get_node_or_null("PhoneContainer/PhoneFrame/ResultScreen") != null, "ResultScreen exists L%d" % lvl)

		var spawner := level.get_node_or_null("Room2Spawner") as Room2Spawner
		var checker := level.get_node_or_null("SymmetryChecker")
		assert_true(spawner != null, "Room2Spawner present in L%d" % lvl)
		assert_true(checker != null, "SymmetryChecker present in L%d" % lvl)

		if spawner and checker:
			_validate_grounded_spatial_invariants(spawner, lvl, 0)

			# Record all item positions before stepping 10 physics frames (verify ZERO falling/floating!)
			var all_items_before: Array[Node] = level.find_children("*", "InteractiveItem", true, false)
			var pre_physics_pos: Dictionary[int, Vector2] = {}
			for n in all_items_before:
				var it := n as InteractiveItem
				if it and it.visible and not it.is_queued_for_deletion():
					pre_physics_pos[it.get_instance_id()] = it.global_position
					assert_eq(it.collision_layer, 2 if it.can_player_stand else 0, "Collision layer matches can_player_stand L%d %s" % [lvl, it.item_id])

			for _pf in range(10):
				await physics_frame

			for n in all_items_before:
				var it := n as InteractiveItem
				if it and pre_physics_pos.has(it.get_instance_id()):
					var drift: float = it.global_position.distance_to(pre_physics_pos[it.get_instance_id()])
					assert_true(drift < 1.0, "Physics stability L%d %s (drift=%.3f)" % [lvl, it.item_id, drift])

			# Mirror Room 2 items to Room 1 references and confirm 100% pass
			var r1_map: Dictionary[String, InteractiveItem] = {}
			var r2_list: Array[InteractiveItem] = []
			for n in all_items_before:
				var it := n as InteractiveItem
				if not it or not it.visible or it.is_queued_for_deletion():
					continue
				if it.home_room == 1:
					r1_map[it.item_id.strip_edges()] = it
				else:
					r2_list.append(it)

			assert_eq(r1_map.size(), LevelProgression.get_total_objects(lvl), "L%d Room 1 item count" % lvl)
			assert_eq(r2_list.size(), LevelProgression.get_total_objects(lvl), "L%d Room 2 item count" % lvl)

			for r2 in r2_list:
				var id: String = r2.item_id.strip_edges()
				assert_true(r1_map.has(id), "L%d Room 1 reference exists for %s" % [lvl, id])
				if r1_map.has(id):
					var r1: InteractiveItem = r1_map[id]
					r2.sync_to_physics = false
					r2.global_position = Vector2(-r1.global_position.x, r1.global_position.y)
					r2.sync_to_physics = true

			var eval_perfect: Dictionary = checker.call("hitung_evaluasi")
			assert_eq(eval_perfect.get("passed", false), true, "L%d 100%% mirror passes" % lvl)
			assert_eq(eval_perfect.get("score", -1), LevelProgression.get_total_objects(lvl), "L%d 100%% score matches total" % lvl)

			if lvl == 3 and r2_list.size() == 4:
				r2_list[3].sync_to_physics = false
				r2_list[3].global_position.x += 25.0
				r2_list[3].sync_to_physics = true
				var eval_3_of_4: Dictionary = checker.call("hitung_evaluasi")
				assert_eq(eval_3_of_4.get("passed", false), true, "TC-11 L3 3/4 passes")
				assert_eq(eval_3_of_4.get("score", -1), 3, "TC-11 L3 score 3/4")

				r2_list[2].sync_to_physics = false
				r2_list[2].global_position.x += 25.0
				r2_list[2].sync_to_physics = true
				var eval_2_of_4: Dictionary = checker.call("hitung_evaluasi")
				assert_eq(eval_2_of_4.get("passed", true), false, "TC-11 L3 2/4 fails")
				assert_eq(eval_2_of_4.get("status", ""), "game_over", "TC-11 L3 2/4 game_over")

	# Verify Retry from Game Over & Main Menu -> Level 1 reload lifecycle on Level03.tscn
	if gm:
		gm.set("current_level", 3)
		gm.set("is_replaying", true)
	var l3_packed := load("res://scene/level/Level03.tscn") as PackedScene
	change_scene_to_packed(l3_packed)
	await process_frame
	await process_frame

	var l3_scene := current_scene as Node2D
	var l3_spawner := l3_scene.get_node_or_null("Room2Spawner") as Room2Spawner if l3_scene else null
	var l3_phone := l3_scene.get_node_or_null("Smartphone") if l3_scene else null
	if l3_spawner and l3_phone:
		var before_retry: Array[Vector2] = l3_spawner.last_spawn_positions.duplicate()
		l3_phone.set("status_evaluasi", "game_over")
		l3_phone.call("_on_btn_close_result_pressed")
		await process_frame
		await process_frame

		var retried_scene := current_scene as Node2D
		var retried_spawner := retried_scene.get_node_or_null("Room2Spawner") as Room2Spawner if retried_scene else null
		var retried_phone := retried_scene.get_node_or_null("Smartphone") if retried_scene else null
		assert_true(retried_spawner != null, "TC-05 Retry Room2Spawner exists")
		if retried_spawner:
			assert_eq(retried_spawner.last_spawn_positions.size(), 4, "TC-06 Retry L3 object count == 4")
			assert_true(retried_spawner.last_spawn_positions != before_retry, "TC-05 Retry regenerated layout")
			_validate_grounded_spatial_invariants(retried_spawner, 3, 99)
		if retried_phone:
			assert_eq(bool(retried_phone.get("is_game_started")), true, "TC-05 Retry starts gameplay immediately")

			retried_phone.call("kembali_ke_judul")
			retried_phone.call("_on_btn_level_1_pressed")
			await process_frame
			await process_frame

			var menu_scene := current_scene as Node2D
			assert_true(menu_scene != null and menu_scene.scene_file_path == "res://scene/level/Level01.tscn", "TC-07 Main Menu -> Level 1 loaded scene/level/Level01.tscn")
			var menu_spawner := menu_scene.get_node_or_null("Room2Spawner") as Room2Spawner if menu_scene else null
			assert_true(menu_spawner != null, "TC-07 Room2Spawner exists in Level01")
			if menu_spawner:
				assert_eq(menu_spawner.last_spawn_positions.size(), 1, "TC-07 Main Menu -> Level 1 object count == 1")

			var menu_phone := menu_scene.get_node_or_null("Smartphone") if menu_scene else null
			assert_true(menu_phone != null, "Smartphone exists in Level01")
			if menu_phone:
				var save_existed: bool = FileAccess.file_exists("user://save_data.json")
				var orig_save_bytes: PackedByteArray = FileAccess.get_file_as_bytes("user://save_data.json") if save_existed else PackedByteArray()

				if gm:
					gm.set("current_level", 1)
					gm.set("unlocked_level", 1)
				menu_phone.set("status_evaluasi", "success")
				menu_phone.set("_level_unlocked_for_result", false)
				menu_phone.set("_is_transitioning_level", false)
				menu_phone.call("_on_btn_close_result_pressed")
				await process_frame
				await process_frame

				var l2_scene := current_scene as Node2D
				assert_true(l2_scene != null and l2_scene.scene_file_path == "res://scene/level/Level02.tscn", "Auto advance from Level 1 loads Level02.tscn")
				var l2_spawner := l2_scene.get_node_or_null("Room2Spawner") as Room2Spawner if l2_scene else null
				assert_true(l2_spawner != null, "Level02 has Room2Spawner after auto advance")
				if l2_spawner:
					assert_eq(l2_spawner.last_spawn_positions.size(), 2, "Level02 auto advance spawns 2 objects")

				var l2_phone := l2_scene.get_node_or_null("Smartphone") if l2_scene else null
				assert_true(l2_phone != null, "Level02 has Smartphone")
				if l2_phone:
					l2_phone.call("show_screen", "level_select")
					var lvl_buttons: Variant = l2_phone.get("level_buttons")
					assert_true(lvl_buttons is Dictionary and (lvl_buttons as Dictionary).size() == 5, "LevelSelect exposes all 5 level buttons")
					if lvl_buttons is Dictionary:
						var btn_dict := lvl_buttons as Dictionary
						assert_eq((btn_dict[1] as BaseButton).disabled, false, "Level 1 button unlocked")
						assert_eq((btn_dict[2] as BaseButton).disabled, false, "Level 2 button unlocked after passing L1")
						assert_eq((btn_dict[3] as BaseButton).disabled, true, "Level 3 button locked initially")
						assert_eq((btn_dict[4] as BaseButton).disabled, true, "Level 4 button locked initially")
						assert_eq((btn_dict[5] as BaseButton).disabled, true, "Level 5 button locked initially")

				if gm:
					gm.set("current_level", 5)
					gm.set("unlocked_level", 5)
					gm.set("is_replaying", true)
				var l5_packed := load("res://scene/level/Level05.tscn") as PackedScene
				change_scene_to_packed(l5_packed)
				await process_frame
				await process_frame
				var l5_scene := current_scene as Node2D
				var l5_phone := l5_scene.get_node_or_null("Smartphone") if l5_scene else null
				if l5_phone:
					l5_phone.set("status_evaluasi", "success")
					l5_phone.set("_level_unlocked_for_result", false)
					l5_phone.set("_is_transitioning_level", false)
					l5_phone.call("_on_btn_close_result_pressed")
					var ls_screen := l5_phone.get("level_select_screen") as Control
					assert_true(ls_screen != null and ls_screen.visible, "Passing final Level 5 opens LevelSelect screen")

				if save_existed:
					var fw := FileAccess.open("user://save_data.json", FileAccess.WRITE)
					if fw:
						fw.store_buffer(orig_save_bytes)
				elif FileAccess.file_exists("user://save_data.json"):
					DirAccess.remove_absolute(ProjectSettings.globalize_path("user://save_data.json"))

	paused = false
	unload_current_scene()
	await process_frame

	if gm:
		gm.set("current_level", orig_level)
		gm.set("unlocked_level", orig_unlocked)
		gm.set("is_replaying", orig_replaying)

	return true


func test_drag_and_drop_mechanics() -> bool:
	var host := Node2D.new()
	root.add_child(host)

	var player := CharacterBody2D.new()
	player.name = "Player"
	player.position = Vector2(115.0, -16.0)
	host.add_child(player)

	var chair_tex := PlaceholderTexture2D.new()
	chair_tex.size = Vector2(16, 16)
	var table_tex := PlaceholderTexture2D.new()
	table_tex.size = Vector2(24, 14)
	var lamp_tex := PlaceholderTexture2D.new()
	lamp_tex.size = Vector2(8, 24)

	var table := PROP_SCENE.instantiate() as InteractiveItem
	table.override_home_room = 2
	table.hold_until_dragged = true
	table.position = Vector2(120.0, -7.0)
	host.add_child(table)
	table.configure_prop("table_test", table_tex, Vector2.ONE, Vector2(24.0, 14.0), Vector2.ZERO, true)

	var lamp := PROP_SCENE.instantiate() as InteractiveItem
	lamp.override_home_room = 2
	lamp.hold_until_dragged = true
	lamp.position = Vector2(150.0, -12.0)
	host.add_child(lamp)
	lamp.configure_prop("lamp_test", lamp_tex, Vector2.ONE, Vector2(4.0, 24.0), Vector2.ZERO, false, false)

	var chair := PROP_SCENE.instantiate() as InteractiveItem
	chair.override_home_room = 2
	chair.hold_until_dragged = true
	chair.position = Vector2(100.0, -8.0)
	host.add_child(chair)
	chair.configure_prop("chair_test", chair_tex, Vector2.ONE, Vector2(14.0, 4.0), Vector2(0.0, 2.0), true, true)

	await process_frame

	assert_eq(table.collision_layer, 2, "Climbable table uses Layer 2")
	assert_eq(chair.collision_layer, 2, "Climbable chair uses Layer 2")
	assert_eq(lamp.collision_layer, 0, "Non-climbable lamp leaves Layer 0")
	assert_eq(chair.sync_to_physics, false, "InteractiveItem sets sync_to_physics = false for responsive dragging")
	assert_eq(InteractiveItem.MAX_DISTANCE, 55.0, "InteractiveItem.MAX_DISTANCE expanded to 55.0")

	assert_true(chair.contains_global_point(chair.global_position + Vector2(0.0, -7.0)), "Visual rect covers chair backrest")
	assert_eq(chair.contains_global_point(chair.global_position + Vector2(30.0, 0.0)), false, "Visual rect rejects far points")

	var grab_pt: Vector2 = chair.global_position + Vector2(0.0, -7.0)
	chair.start_drag(grab_pt)
	assert_eq(chair.is_dragging, true, "start_drag activates dragging")
	assert_eq(InteractiveItem._active_drag_item, chair, "_active_drag_item locks onto dragged chair")
	assert_eq(chair.z_index, 10, "Dragged item lifts z_index to 10")
	assert_true(chair.drag_offset.is_equal_approx(Vector2(0.0, 7.0)), "start_drag preserves grab offset")

	var table_stack_y: float = chair.cari_lantai_terdekat(table.global_position.x, -40.0)
	var lamp_floor_y: float = chair.cari_lantai_terdekat(lamp.global_position.x, -40.0)
	assert_true(table_stack_y < chair.floor_y - 10.0, "Stackable table elevates target support y (got %.2f < %.2f)" % [table_stack_y, chair.floor_y])
	assert_true(absf(lamp_floor_y - chair.floor_y) < 0.01, "Non-stackable lamp is skipped by cari_lantai_terdekat")

	chair.stop_drag()
	assert_eq(chair.is_dragging, false, "stop_drag clears is_dragging")
	assert_eq(InteractiveItem._active_drag_item, null, "stop_drag clears _active_drag_item")
	assert_eq(chair.z_index, 0, "stop_drag restores z_index to 0")

	chair.global_position = Vector2(table.global_position.x, -40.0)
	for _pf in range(25):
		await physics_frame

	assert_true(chair.global_position.y > -40.0, "Dropped chair falls smoothly under physics")
	assert_true(absf(chair.global_position.y - table_stack_y) < 0.5, "Dropped chair lands flush on stackable table (%.2f vs %.2f)" % [chair.global_position.y, table_stack_y])

	host.queue_free()
	await process_frame
	return true


func _spawn_catalog_prop(parent_node: Node2D, prop_index: int, pos: Vector2) -> InteractiveItem:
	var def: Dictionary = LevelProgression.get_prop_definition(prop_index)
	var item := PROP_SCENE.instantiate() as InteractiveItem
	item.override_home_room = 2
	item.hold_until_dragged = false
	item.position = pos
	parent_node.add_child(item)
	var tex_path: String = def.get("texture_path", "")
	var tex := load(tex_path) as Texture2D if tex_path != "" else null
	var id_str: String = def.get("item_id", "prop")
	var sz: Vector2 = def.get("shape_size", Vector2(14.0, 4.0))
	var off: Vector2 = def.get("shape_offset", Vector2.ZERO)
	var support: bool = bool(def.get("can_support_stack", true))
	var stand: bool = bool(def.get("can_player_stand", true))
	item.configure_prop(id_str, tex, LevelProgression.DEFAULT_PROP_SCALE, sz, off, support, stand)
	item.global_position.y = item.floor_y
	return item


func test_player_climb_and_stepping_stone() -> bool:
	var host := Node2D.new()
	root.add_child(host)

	var floor_body := StaticBody2D.new()
	floor_body.collision_layer = 1
	floor_body.collision_mask = 0
	var floor_col := CollisionShape2D.new()
	var floor_rect := RectangleShape2D.new()
	floor_rect.size = Vector2(400.0, 20.0)
	floor_col.shape = floor_rect
	floor_col.position = Vector2(100.0, 10.0)
	floor_body.add_child(floor_col)
	host.add_child(floor_body)

	var stool := _spawn_catalog_prop(host, 0, Vector2(50.0, -10.0))       # top ~ -10.87
	var table := _spawn_catalog_prop(host, 3, Vector2(90.0, -10.0))       # top ~ -16.32
	var bookcase := _spawn_catalog_prop(host, 8, Vector2(140.0, -14.0))   # top ~ -26.43
	var lamp := _spawn_catalog_prop(host, 1, Vector2(180.0, -14.0))       # non-climbable (layer 0)

	var player_scene := load("res://scene/player/player.tscn") as PackedScene
	var player := player_scene.instantiate() as CharacterBody2D
	player.position = Vector2(30.0, -16.0)
	host.add_child(player)

	await process_frame
	for _pf in range(4):
		await physics_frame

	# 1. Horizontal pass-through: walk through side of stool without being blocked
	Input.action_press("move_right")
	for _pf in range(20):
		await physics_frame
	Input.action_release("move_right")
	assert_true(player.global_position.x > 65.0, "Player walks freely past stool side (x=%.2f)" % player.global_position.x)

	# 2. Direct jump from floor onto stool (~10.87 px)
	player.global_position = Vector2(stool.global_position.x, -16.0)
	player.velocity = Vector2.ZERO
	for _pf in range(3):
		await physics_frame
	player.velocity.y = float(player.get("jump_velocity"))
	for _pf in range(30):
		await physics_frame
	var feet_stool: float = player.global_position.y + 16.0
	assert_true(player.is_on_floor() and feet_stool <= -9.5, "Player lands on top of stool (feet=%.2f)" % feet_stool)
	assert_eq(bool(player.call("_is_standing_on_one_way_prop")), true, "Player detects standing on one-way prop")

	player.set("_drop_through_timer", 0.15)
	for _pf in range(16):
		await physics_frame
	var feet_after_drop: float = player.global_position.y + 16.0
	assert_true(player.is_on_floor() and absf(feet_after_drop) < 1.0, "Player drops through one-way stool to floor (feet=%.2f)" % feet_after_drop)

	# 3. Direct jump from floor onto table (~16.32 px)
	player.global_position = Vector2(table.global_position.x, -16.0)
	player.velocity = Vector2.ZERO
	for _pf in range(3):
		await physics_frame
	player.velocity.y = float(player.get("jump_velocity"))
	for _pf in range(30):
		await physics_frame
	var feet_table: float = player.global_position.y + 16.0
	assert_true(player.is_on_floor() and feet_table <= -15.0, "Player lands on top of table (feet=%.2f)" % feet_table)

	# 4. Tall bookcase (~26.43 px) cannot be reached by a single jump from floor
	player.global_position = Vector2(bookcase.global_position.x, -16.0)
	player.velocity = Vector2.ZERO
	for _pf in range(3):
		await physics_frame
	player.velocity.y = float(player.get("jump_velocity"))
	for _pf in range(35):
		await physics_frame
	var feet_missed_bookcase: float = player.global_position.y + 16.0
	assert_true(player.is_on_floor() and absf(feet_missed_bookcase) < 1.0, "Tall bookcase requires stepping stone from floor (feet=%.2f)" % feet_missed_bookcase)

	# 5. Stepping-stone climb: place stool beside bookcase, jump from stool top onto bookcase
	stool.global_position.x = bookcase.global_position.x - 20.0
	player.global_position = Vector2(stool.global_position.x, -27.5)
	player.velocity = Vector2.ZERO
	for _pf in range(12):
		await physics_frame
	assert_true(player.is_on_floor() and (player.global_position.y + 16.0) <= -9.5, "Player stands on stepping-stone stool")

	player.velocity.y = float(player.get("jump_velocity"))
	Input.action_press("move_right")
	for _pf in range(9):
		await physics_frame
	Input.action_release("move_right")
	for _pf in range(24):
		await physics_frame
	var feet_bookcase: float = player.global_position.y + 16.0
	assert_true(player.is_on_floor() and feet_bookcase <= -25.0, "Player climbs onto bookcase via stool stepping stone (feet=%.2f)" % feet_bookcase)

	# 6. Non-climbable lamp (can_player_stand = false): player falls cleanly through to floor
	player.global_position = Vector2(lamp.global_position.x, -36.0)
	player.velocity = Vector2.ZERO
	for _pf in range(32):
		await physics_frame
	var feet_lamp: float = player.global_position.y + 16.0
	assert_true(player.is_on_floor() and absf(feet_lamp) < 1.0, "Player falls through non-climbable lamp to floor (feet=%.2f)" % feet_lamp)

	Input.action_release("move_right")
	host.queue_free()
	await process_frame
	return true


func test_measure_tool_and_drag_coexistence() -> bool:
	var gm := root.get_node_or_null("GameManager")
	var orig_level: int = int(gm.get("current_level")) if gm else 1
	var orig_replaying: bool = bool(gm.get("is_replaying")) if gm else false
	if gm:
		gm.set("current_level", 2)
		gm.set("is_replaying", true)

	var packed := load("res://scene/level/Level02.tscn") as PackedScene
	change_scene_to_packed(packed)
	await process_frame
	await process_frame

	var level := current_scene as Node2D
	var player := level.get_node_or_null("Player") as CharacterBody2D
	var mt := level.get_node_or_null("MeasureTool")
	assert_true(level != null and player != null and mt != null, "Level02, Player, and MeasureTool loaded")

	var target_item: InteractiveItem = null
	for n in level.find_children("*", "InteractiveItem", true, false):
		var it := n as InteractiveItem
		if it and it.visible and not it.is_queued_for_deletion() and it.home_room == 2:
			target_item = it
			break
	assert_true(target_item != null, "Found Room 2 InteractiveItem for coexistence test")

	if player and mt and target_item:
		player.global_position = Vector2(target_item.global_position.x, -16.0)
		mt.set("player", player)
		target_item.player = player

		mt.call("toggle_tool")
		assert_eq(bool(mt.get("is_active")), true, "MeasureTool activated")
		assert_eq(mt.get("MAX_INTERACT_DISTANCE"), 55.0, "MeasureTool MAX_INTERACT_DISTANCE aligned to 55.0")

		# Yield helper reports true only while active and unlocked
		mt.set("is_locked", false)
		assert_eq(bool(target_item.call("_should_yield_to_measure_tool")), true, "InteractiveItem yields while MeasureTool active & unlocked")

		# Case A: Locked ruler allows immediate drag without disturbing lock
		mt.set("anchor_point", Vector2(player.global_position.x - 10.0, -20.0))
		mt.set("is_anchored", true)
		mt.set("is_locked", true)
		assert_eq(bool(target_item.call("_should_yield_to_measure_tool")), false, "InteractiveItem does not yield when ruler is locked")
		var consumed_a: bool = bool(mt.call("_handle_left_press", Vector2(200.0, 200.0), target_item.global_position))
		assert_eq(consumed_a, true, "Case A locked ruler press handled")
		assert_eq(target_item.is_dragging, true, "Case A drag starts while ruler is locked")
		assert_eq(bool(mt.get("is_locked")), true, "Case A locked ruler remains locked")
		target_item.stop_drag()

		# Case B: Unlocked ruler + mouse motion >= 6 px drags item without anchoring ruler
		mt.call("reset_measurement")
		var consumed_b: bool = bool(mt.call("_handle_left_press", Vector2(200.0, 200.0), target_item.global_position))
		assert_eq(consumed_b, true, "Case B unlocked ruler press on item pending")
		assert_eq(target_item.is_dragging, false, "Case B drag waits for motion or release")
		mt.call("_handle_mouse_motion", Vector2(210.0, 200.0))
		assert_eq(target_item.is_dragging, true, "Case B >=6px drag starts item drag")
		assert_eq(bool(mt.get("is_anchored")), false, "Case B dragging item does not anchor ruler")
		mt.call("_handle_left_release")
		assert_eq(bool(mt.get("is_anchored")), false, "Case B release after drag does not anchor ruler")
		target_item.stop_drag()

		# Case C: Unlocked ruler + quick click (< 6 px motion) anchors ruler without dragging item
		var consumed_c: bool = bool(mt.call("_handle_left_press", Vector2(200.0, 200.0), target_item.global_position))
		mt.call("_handle_mouse_motion", Vector2(202.0, 200.0))
		mt.call("_handle_left_release")
		assert_eq(consumed_c, true, "Case C quick click handled")
		assert_eq(target_item.is_dragging, false, "Case C quick click does not drag item")
		assert_eq(bool(mt.get("is_anchored")), true, "Case C quick click anchors ruler")
		assert_eq(bool(mt.get("is_locked")), false, "Case C ruler remains unlocked for measurement")

		# Case D: While ruler is anchored & stretching, drag >= 6 px moves item without locking ruler
		var consumed_d: bool = bool(mt.call("_handle_left_press", Vector2(200.0, 200.0), target_item.global_position))
		mt.call("_handle_mouse_motion", Vector2(208.0, 200.0))
		assert_eq(consumed_d, true, "Case D drag press while anchored handled")
		assert_eq(target_item.is_dragging, true, "Case D item drags while ruler actively stretches")
		assert_eq(bool(mt.get("is_anchored")), true, "Case D ruler remains anchored during drag")
		assert_eq(bool(mt.get("is_locked")), false, "Case D ruler not prematurely locked by drag")
		target_item.stop_drag()
		mt.call("reset_measurement")

	paused = false
	unload_current_scene()
	await process_frame

	if gm:
		gm.set("current_level", orig_level)
		gm.set("is_replaying", orig_replaying)

	return true
