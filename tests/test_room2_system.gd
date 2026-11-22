extends SceneTree

const GAMEPLAY_LEVEL_PATHS: Array[String] = [
	"res://scene/level/Level01.tscn",
	"res://scene/level/Level02.tscn",
	"res://scene/level/Level03.tscn",
	"res://scene/level/Level04.tscn",
	"res://scene/level/Level05.tscn",
	"res://scene/level/Level06.tscn",
	"res://scene/level/Level07.tscn",
	"res://scene/level/Level08.tscn",
	"res://scene/level/Level09.tscn",
	"res://scene/level/Level10.tscn",
]
const PROP_SCENE := preload("res://scene/props/interactive_item.tscn")
const WALL_FRAME_SCENE := preload("res://scene/props/wall_frame_item.tscn")
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
		"test_main_mechanics_compatibility",
		"test_wall_frame_mechanics",
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
	var expected := {1: 1, 2: 2, 3: 4, 4: 7, 5: 11, 6: 2, 7: 3, 8: 5, 9: 8, 10: 12}
	var expected_comp := {
		1: [1, 0], 2: [2, 0], 3: [4, 0], 4: [7, 0], 5: [11, 0],
		6: [1, 1], 7: [1, 2], 8: [3, 2], 9: [4, 4], 10: [7, 5],
	}
	for lvl: int in expected:
		assert_eq(LevelProgression.get_total_objects(lvl), expected[lvl], "TC-01 total_objects L%d" % lvl)
		var comp: Dictionary = LevelProgression.get_level_composition(lvl)
		assert_eq(int(comp["furniture"]), expected_comp[lvl][0], "Composition furniture L%d" % lvl)
		assert_eq(int(comp["frames"]), expected_comp[lvl][1], "Composition frames L%d" % lvl)
		assert_eq(int(comp["total"]), expected[lvl], "Composition total L%d" % lvl)
	return true


func test_min_pass_scores() -> bool:
	var expected := {1: 1, 2: 1, 3: 2, 4: 3, 5: 3, 7: 5, 8: 6, 11: 8, 12: 9}
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
		r1.position = Vector2(x_pos, y_pos)
		container.add_child(r1)

		var r2 := PROP_SCENE.instantiate() as InteractiveItem
		r2.item_id = id
		if i < correct_count:
			r2.position = Vector2(-x_pos, y_pos)
		else:
			r2.position = Vector2(-x_pos + 30.0, y_pos)
		container.add_child(r2)

	return {"container": container, "checker": checker}


func test_symmetry_checker_all_levels() -> bool:
	var cases: Array[Array] = [
		[1, 0, "game_over", "sad"],
		[1, 1, "success", "happy"],
		[2, 0, "game_over", "sad"],
		[2, 1, "medium", "neutral"],
		[2, 2, "success", "happy"],
		[4, 1, "game_over", "sad"],
		[4, 2, "medium", "neutral"],
		[4, 3, "medium", "neutral"],
		[4, 4, "success", "happy"],
		[7, 2, "game_over", "sad"],
		[7, 3, "medium", "neutral"],
		[7, 6, "success", "happy"],
		[11, 4, "game_over", "sad"],
		[11, 5, "medium", "neutral"],
		[11, 9, "success", "happy"],
		[11, 11, "success", "happy"],
	]

	for c in cases:
		var total_count: int = c[0]
		var correct_count: int = c[1]
		var expected_status: String = c[2]
		var expected_grade: String = c[3]

		var rig: Dictionary = _build_eval_rig(total_count, correct_count)
		var container: Node2D = rig["container"]
		var checker: Node = rig["checker"]
		var eval: Dictionary = checker.call("hitung_evaluasi")

		assert_eq(eval.get("status", ""), expected_status, "Eval status %d/%d" % [correct_count, total_count])
		assert_eq(eval.get("grade", ""), expected_grade, "Eval grade %d/%d" % [correct_count, total_count])
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
		var is_wall: bool = bool(rec.get("is_wall_mounted", false))

		# Safe Spawn Area (walls, ceiling, floor)
		assert_true(left >= spawner.room_rect.position.x + spawner.wall_padding - 0.01, "Left wall padding L%d iter %d idx %d" % [level, iteration, idx])
		assert_true(right <= spawner.room_rect.end.x - spawner.wall_padding + 0.01, "Right wall padding L%d iter %d idx %d" % [level, iteration, idx])
		assert_true(top >= spawner.room_rect.position.y + spawner.wall_padding - 0.01, "Ceiling wall padding L%d iter %d idx %d" % [level, iteration, idx])
		assert_true(bottom <= spawner.room_rect.end.y + 0.5, "Floor boundary L%d iter %d idx %d" % [level, iteration, idx])

		# Player spawn exclusion zone
		var dist_player: float = pos.distance_to(spawner.player_spawn_position)
		assert_true(dist_player >= exclusion_radius - 0.01, "Player exclusion L%d iter %d idx %d (dist=%.2f)" % [level, iteration, idx, dist_player])

		if is_wall:
			assert_eq(support_idx, -1, "Wall frame has no support_index L%d iter %d idx %d" % [level, iteration, idx])
			assert_true(pos.y >= spawner.room_rect.end.y - spawner.wall_frame_max_height - 0.01, "Wall frame within max reach height L%d iter %d idx %d (y=%.2f)" % [level, iteration, idx, pos.y])
			assert_true(pos.y <= spawner.room_rect.end.y - minf(spawner.wall_frame_min_height, spawner.wall_frame_max_height) + 0.01, "Wall frame above min wall height L%d iter %d idx %d (y=%.2f)" % [level, iteration, idx, pos.y])
			assert_true(bottom <= spawner.room_rect.end.y - 10.0 + 0.01, "Wall frame mounted above floor L%d iter %d idx %d (bottom=%.2f)" % [level, iteration, idx, bottom])
			for other_idx in range(idx + 1, records.size()):
				var other: Dictionary = records[other_idx]
				if not bool(other.get("is_wall_mounted", false)):
					continue
				var v_overlap: bool = (top < float(other["bottom"]) + spawner.min_gap - 0.01) and (bottom > float(other["top"]) - spawner.min_gap + 0.01)
				var h_overlap: bool = (left < float(other["right"]) + spawner.min_gap - 0.01) and (right > float(other["left"]) - spawner.min_gap + 0.01)
				assert_true(not (v_overlap and h_overlap), "No wall frame overlap L%d iter %d (%d vs %d)" % [level, iteration, idx, other_idx])
			continue

		# Zero floating: must rest flush on floor OR flush on a valid support object
		if support_idx < 0:
			assert_true(absf(bottom - spawner.room_rect.end.y) <= 0.5, "Grounded on floor L%d iter %d idx %d (bottom=%.2f)" % [level, iteration, idx, bottom])
		else:
			any_stacked = true
			assert_true(support_idx < records.size() and support_idx != idx, "Valid support index L%d iter %d idx %d" % [level, iteration, idx])
			var sup: Dictionary = records[support_idx]
			assert_true(bool(sup["can_support_stack"]), "Support allows stacking L%d iter %d idx %d" % [level, iteration, idx])
			assert_true(absf(bottom - float(sup["surface_y"])) <= 0.5, "Flush on support surface L%d iter %d idx %d" % [level, iteration, idx])
			assert_true(absf(bottom - float(sup["top"])) <= 1.0, "Zero visual stack gap L%d iter %d idx %d (bottom=%.2f sup_top=%.2f)" % [level, iteration, idx, bottom, float(sup["top"])])
			assert_true(left >= float(sup["left"]) - 1.05 and right <= float(sup["right"]) + 1.05, "Zero visual overhang L%d iter %d idx %d (L=%.1f..%.1f on %.1f..%.1f)" % [level, iteration, idx, left, right, float(sup["left"]), float(sup["right"])])

		# Zero overlap against all non-supporting furniture items
		for other_idx in range(idx + 1, records.size()):
			if int(records[other_idx]["support_index"]) == idx or support_idx == other_idx:
				continue
			var other: Dictionary = records[other_idx]
			if bool(other.get("is_wall_mounted", false)):
				continue
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
	var wall_frames_observed_high_levels: bool = false
	for lvl in range(1, 11):
		var expected_comp: Dictionary = LevelProgression.get_level_composition(lvl)
		for iter in range(20):
			spawner.spawn_level_objects(lvl, spawner.player_spawn_position)
			var has_stack: bool = _validate_grounded_spatial_invariants(spawner, lvl, iter)
			if lvl >= 4 and has_stack:
				stacked_observed_high_levels = true
			var furn_cnt: int = 0
			var frame_cnt: int = 0
			for rec in spawner.last_spawn_records:
				if bool(rec.get("is_wall_mounted", false)):
					frame_cnt += 1
					wall_frames_observed_high_levels = true
				else:
					furn_cnt += 1
			assert_eq(furn_cnt, int(expected_comp["furniture"]), "Spawner furniture count L%d iter %d" % [lvl, iter])
			assert_eq(frame_cnt, int(expected_comp["frames"]), "Spawner frame count L%d iter %d" % [lvl, iter])

	assert_true(stacked_observed_high_levels, "Natural stacking observed in high levels")
	assert_true(wall_frames_observed_high_levels, "Wall frames spawned in Levels 6-10")

	host.queue_free()
	await process_frame
	return true


func test_jittered_grid_fallback() -> bool:
	var host := Node2D.new()
	root.add_child(host)

	# Case 1: Force fallback in standard Room 2 bounds with max_attempts = 1 (L5 & L10 with frames)
	var spawner := Room2Spawner.new()
	spawner.auto_spawn_on_ready = false
	spawner.object_scene = PROP_SCENE
	spawner.max_attempts = 1
	host.add_child(spawner)

	for iter in range(10):
		spawner.spawn_level_objects(5, spawner.player_spawn_position)
		assert_true(spawner.last_spawn_used_fallback, "Fallback triggered L5 iter %d" % iter)
		_validate_grounded_spatial_invariants(spawner, 5, iter)

	var any_l10_fallback: bool = false
	for iter in range(10):
		spawner.spawn_level_objects(10, spawner.player_spawn_position)
		if spawner.last_spawn_used_fallback:
			any_l10_fallback = true
		_validate_grounded_spatial_invariants(spawner, 10, iter)
	assert_true(any_l10_fallback, "Fallback triggered in at least one L10 max_attempts=1 run")

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
			assert_eq(player.collision_mask, 3, "Player matches main collision_mask == 3 L%d" % lvl)
			assert_eq(player.get("jump_velocity"), -150.0, "Player matches main jump_velocity == -150.0 L%d" % lvl)

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

			var mt_node := level.get_node_or_null("MeasureTool")
			if player and mt_node:
				assert_true(mt_node.get_index() > player.get_index(), "MeasureTool draws in front of Player L%d" % lvl)

			if player:
				_assert_strict_z_order(level, player, lvl, "initial")

			# Record Room 2 items + wall frames immediately, then settle 1 frame + step 60 physics frames
			var wall_script := preload("res://script/wall_frame_item.gd")
			var all_items_before: Array[Node] = level.find_children("*", "InteractiveItem", true, false)
			var pre_physics_r2: Dictionary[int, Vector2] = {}
			for n in all_items_before:
				var it := n as InteractiveItem
				if it and it.visible and not it.is_queued_for_deletion():
					var is_wall: bool = is_instance_of(it, wall_script)
					assert_eq(it.collision_layer, 4 if is_wall else 2, "InteractiveItem collision_layer L%d %s" % [lvl, it.item_id])
					assert_eq(it.sync_to_physics, false if is_wall else true, "InteractiveItem sync_to_physics L%d %s" % [lvl, it.item_id])
					if it.home_room == 2 or is_wall:
						pre_physics_r2[it.get_instance_id()] = it.global_position
					if it.home_room == 2:
						assert_eq(it.player, player, "Room 2 item resolves Player cleanly L%d %s" % [lvl, it.item_id])

			await physics_frame
			_assert_room1_clean_and_mirrorable(level, lvl)
			var settled_pos: Dictionary[int, Vector2] = {}
			for n in all_items_before:
				var it := n as InteractiveItem
				if it and it.visible and not it.is_queued_for_deletion():
					settled_pos[it.get_instance_id()] = it.global_position

			for _pf in range(60):
				await physics_frame

			for n in all_items_before:
				var it := n as InteractiveItem
				if not it:
					continue
				if pre_physics_r2.has(it.get_instance_id()):
					var drift_init: float = it.global_position.distance_to(pre_physics_r2[it.get_instance_id()])
					assert_true(drift_init < 0.05, "Zero initial drift L%d %s (drift=%.3f)" % [lvl, it.item_id, drift_init])
				if settled_pos.has(it.get_instance_id()):
					var drift_60: float = it.global_position.distance_to(settled_pos[it.get_instance_id()])
					assert_true(drift_60 < 0.05, "Zero 60-frame drift L%d %s (drift=%.3f)" % [lvl, it.item_id, drift_60])

			# Mirror Room 2 items to Room 1 references and confirm 100% pass
			var r1_map: Dictionary[String, InteractiveItem] = {}
			var r2_list: Array[InteractiveItem] = []
			var r1_furn: int = 0
			var r1_frames: int = 0
			var r2_furn: int = 0
			var r2_frames: int = 0
			for n in all_items_before:
				var it := n as InteractiveItem
				if not it or not it.visible or it.is_queued_for_deletion():
					continue
				var is_w: bool = is_instance_of(it, wall_script)
				if it.home_room == 1:
					r1_map[it.item_id.strip_edges()] = it
					if is_w:
						r1_frames += 1
					else:
						r1_furn += 1
				else:
					r2_list.append(it)
					if is_w:
						r2_frames += 1
					else:
						r2_furn += 1

			var comp: Dictionary = LevelProgression.get_level_composition(lvl)
			assert_eq(r1_map.size(), LevelProgression.get_total_objects(lvl), "L%d Room 1 item count" % lvl)
			assert_eq(r2_list.size(), LevelProgression.get_total_objects(lvl), "L%d Room 2 item count" % lvl)
			assert_eq(r1_furn, int(comp["furniture"]), "L%d Room 1 furniture count" % lvl)
			assert_eq(r1_frames, int(comp["frames"]), "L%d Room 1 frame count" % lvl)
			assert_eq(r2_furn, int(comp["furniture"]), "L%d Room 2 furniture count" % lvl)
			assert_eq(r2_frames, int(comp["frames"]), "L%d Room 2 frame count" % lvl)

			for r2 in r2_list:
				var id: String = r2.item_id.strip_edges()
				assert_true(r1_map.has(id), "L%d Room 1 reference exists for %s" % [lvl, id])
				if r1_map.has(id):
					var r1: InteractiveItem = r1_map[id]
					r2.sync_to_physics = false
					r2.global_position = Vector2(-r1.global_position.x, r1.global_position.y)
					if not is_instance_of(r2, wall_script):
						r2.sync_to_physics = true

			var expected_total: int = LevelProgression.get_total_objects(lvl)
			var eval_perfect: Dictionary = checker.call("hitung_evaluasi")
			assert_eq(eval_perfect.get("status", ""), "success", "L%d 100%% mirror status success" % lvl)
			assert_eq(eval_perfect.get("grade", ""), "happy", "L%d 100%% mirror grade happy" % lvl)
			assert_eq(eval_perfect.get("text", ""), "BERHASIL!\n(%d/%d)" % [expected_total, expected_total], "L%d 100%% mirror text" % lvl)

			if lvl == 3 and r2_list.size() == 4:
				r2_list[3].sync_to_physics = false
				r2_list[3].global_position.x += 25.0
				r2_list[3].sync_to_physics = true
				var eval_3_of_4: Dictionary = checker.call("hitung_evaluasi")
				assert_eq(eval_3_of_4.get("status", ""), "medium", "Main L3 3/4 medium status")
				assert_eq(eval_3_of_4.get("grade", ""), "neutral", "Main L3 3/4 neutral grade")

				r2_list[2].sync_to_physics = false
				r2_list[2].global_position.x += 25.0
				r2_list[2].sync_to_physics = true
				var eval_2_of_4: Dictionary = checker.call("hitung_evaluasi")
				assert_eq(eval_2_of_4.get("status", ""), "medium", "Main L3 2/4 medium status")
				assert_eq(eval_2_of_4.get("grade", ""), "neutral", "Main L3 2/4 neutral grade")

				r2_list[1].sync_to_physics = false
				r2_list[1].global_position.x += 25.0
				r2_list[1].sync_to_physics = true
				var eval_1_of_4: Dictionary = checker.call("hitung_evaluasi")
				assert_eq(eval_1_of_4.get("status", ""), "game_over", "Main L3 1/4 game_over status")
				assert_eq(eval_1_of_4.get("grade", ""), "sad", "Main L3 1/4 sad grade")

			if lvl >= 6:
				var min_frame_y_limit: float = -61.01 if lvl <= 7 else -65.01
				var r1_min_y: float = INF
				var r1_max_y: float = -INF
				var r2_init_min_y: float = INF
				var r2_init_max_y: float = -INF
				for n in all_items_before:
					var it := n as InteractiveItem
					if not it or not it.visible or it.is_queued_for_deletion():
						continue
					if is_instance_of(it, wall_script):
						assert_true(it.global_position.y >= min_frame_y_limit, "Wall frame climb-reachable L%d %s (y=%.2f)" % [lvl, it.item_id, it.global_position.y])
						if it.home_room == 1:
							r1_min_y = minf(r1_min_y, it.global_position.y)
							r1_max_y = maxf(r1_max_y, it.global_position.y)
						else:
							r2_init_min_y = minf(r2_init_min_y, it.global_position.y)
							r2_init_max_y = maxf(r2_init_max_y, it.global_position.y)
				if lvl >= 7:
					assert_true(r1_max_y - r1_min_y >= 15.0, "R1 wall frames varied height L%d (spread=%.2f)" % [lvl, r1_max_y - r1_min_y])

			if lvl >= 5:
				var min_r2_y_limit: float = -61.01 if lvl <= 7 else -65.01
				var max_r2_spread: float = 0.0
				for spawn_iter in range(15):
					spawner.respawn_current_level()
					_validate_grounded_spatial_invariants(spawner, lvl, spawn_iter + 1)
					if player:
						_assert_strict_z_order(level, player, lvl, "respawn_%d" % spawn_iter)
					_assert_room2_no_frame_furniture_overlap(spawner, lvl, spawn_iter)
					if lvl >= 6:
						var s_min_y: float = INF
						var s_max_y: float = -INF
						for rec in spawner.last_spawn_records:
							if bool(rec.get("is_wall_mounted", false)):
								var fy: float = float((rec["pos"] as Vector2).y)
								assert_true(fy >= min_r2_y_limit, "R2 respawn frame reachable L%d iter %d (y=%.2f)" % [lvl, spawn_iter, fy])
								s_min_y = minf(s_min_y, fy)
								s_max_y = maxf(s_max_y, fy)
						if s_min_y < INF:
							max_r2_spread = maxf(max_r2_spread, s_max_y - s_min_y)
				if lvl >= 7:
					assert_true(max_r2_spread >= 8.0, "R2 wall frames varied heights across respawns L%d (max_spread=%.2f)" % [lvl, max_r2_spread])

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
					assert_true(lvl_buttons is Dictionary and (lvl_buttons as Dictionary).size() == 10, "LevelSelect exposes all 10 level buttons")
					if lvl_buttons is Dictionary:
						var btn_dict := lvl_buttons as Dictionary
						assert_eq((btn_dict[1] as BaseButton).disabled, false, "Level 1 button unlocked")
						assert_eq((btn_dict[2] as BaseButton).disabled, false, "Level 2 button unlocked after passing L1")
						for locked_lvl in range(3, 11):
							assert_eq((btn_dict[locked_lvl] as BaseButton).disabled, true, "Level %d button locked initially" % locked_lvl)

				if gm:
					gm.set("current_level", 10)
					gm.set("unlocked_level", 10)
					gm.set("is_replaying", true)
				var l10_packed := load("res://scene/level/Level10.tscn") as PackedScene
				change_scene_to_packed(l10_packed)
				await process_frame
				await process_frame
				var l10_scene := current_scene as Node2D
				var l10_phone := l10_scene.get_node_or_null("Smartphone") if l10_scene else null
				if l10_phone:
					l10_phone.set("status_evaluasi", "success")
					l10_phone.set("_level_unlocked_for_result", false)
					l10_phone.set("_is_transitioning_level", false)
					l10_phone.call("_on_btn_close_result_pressed")
					var ls_screen := l10_phone.get("level_select_screen") as Control
					assert_true(ls_screen != null and ls_screen.visible, "Passing final Level 10 opens LevelSelect screen")

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


func test_main_mechanics_compatibility() -> bool:
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
	assert_true(level != null and player != null and mt != null, "Level02, Player, and MeasureTool loaded cleanly")

	if player:
		assert_eq(player.collision_mask, 3, "Main Player collision_mask == 3")
		assert_eq(player.get("jump_velocity"), -150.0, "Main Player jump_velocity == -150.0")
		assert_eq(player.get("speed"), 160.0, "Main Player speed == 160.0")

	var r2_items: Array[InteractiveItem] = []
	for n in level.find_children("*", "InteractiveItem", true, false):
		var it := n as InteractiveItem
		if it and it.visible and not it.is_queued_for_deletion() and it.home_room == 2:
			r2_items.append(it)
	assert_eq(r2_items.size(), 2, "Level02 spawns 2 Room 2 items compatible with main InteractiveItem")

	if r2_items.size() > 0 and player:
		var item: InteractiveItem = r2_items[0]
		assert_eq(item.get_parent(), level, "Spawned Room 2 item is child of Level root so main InteractiveItem finds Player")
		assert_eq(item.player, player, "Main InteractiveItem resolves Player reference")
		assert_eq(InteractiveItem.MAX_DISTANCE, 35.0, "Main InteractiveItem.MAX_DISTANCE == 35.0")

		player.global_position = Vector2(maxf(item.global_position.x, 40.0), -16.0)
		item.start_drag()
		await process_frame
		assert_eq(item.is_dragging, true, "Main InteractiveItem.start_drag sets is_dragging")
		var col := item.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if col:
			assert_eq(col.disabled, true, "Main InteractiveItem.start_drag disables collider")

		item.stop_drag()
		await process_frame
		assert_eq(item.is_dragging, false, "Main InteractiveItem.stop_drag clears is_dragging")
		if col:
			assert_eq(col.disabled, false, "Main InteractiveItem.stop_drag re-enables collider")

	if mt:
		assert_eq(mt.get("MAX_INTERACT_DISTANCE"), 35.0, "Main MeasureTool.MAX_INTERACT_DISTANCE == 35.0")
		mt.call("toggle_tool")
		assert_eq(bool(mt.get("is_active")), true, "Main MeasureTool activates cleanly")
		mt.set("is_anchored", true)
		mt.set("is_locked", false)
		mt.call("handle_click")
		assert_eq(bool(mt.get("is_locked")), true, "Main MeasureTool locks measurement on handle_click")
		mt.call("reset_measurement")
		assert_eq(bool(mt.get("is_anchored")), false, "Main MeasureTool reset clears anchor")
		assert_eq(bool(mt.get("is_locked")), false, "Main MeasureTool reset clears lock")

	paused = false
	unload_current_scene()
	await process_frame

	if gm:
		gm.set("current_level", orig_level)
		gm.set("is_replaying", orig_replaying)

	return true


func test_wall_frame_mechanics() -> bool:
	var gm := root.get_node_or_null("GameManager")
	var orig_level: int = int(gm.get("current_level")) if gm else 1
	var orig_replaying: bool = bool(gm.get("is_replaying")) if gm else false
	if gm:
		gm.set("current_level", 6)
		gm.set("is_replaying", true)

	var packed := load("res://scene/level/Level06.tscn") as PackedScene
	change_scene_to_packed(packed)
	await process_frame
	await process_frame

	var level := current_scene as Node2D
	var player := level.get_node_or_null("Player") as CharacterBody2D
	var checker := level.get_node_or_null("SymmetryChecker")
	assert_true(level != null and player != null and checker != null, "Level06, Player, and SymmetryChecker loaded")

	var r1_map: Dictionary[String, InteractiveItem] = {}
	var r2_frames: Array[InteractiveItem] = []
	var r2_floor_items: Array[InteractiveItem] = []
	for n in level.find_children("*", "InteractiveItem", true, false):
		var it := n as InteractiveItem
		if not it or not it.visible or it.is_queued_for_deletion():
			continue
		if it.home_room == 1:
			r1_map[it.item_id.strip_edges()] = it
		elif is_instance_of(it, preload("res://script/wall_frame_item.gd")):
			r2_frames.append(it)
		else:
			r2_floor_items.append(it)

	assert_eq(r2_frames.size(), 1, "Level06 spawns 1 Room 2 WallFrameItem")
	assert_eq(r2_floor_items.size(), 1, "Level06 spawns 1 Room 2 furniture item")

	if r2_frames.size() > 0 and player:
		var frame: InteractiveItem = r2_frames[0]
		assert_eq(frame.collision_layer, 4, "WallFrameItem uses Layer 4")
		assert_eq(player.collision_mask & frame.collision_layer, 0, "Player passes cleanly through WallFrameItem")

		# Place frame at arbitrary wall locations and verify 0.0 px falling after 20 physics frames
		frame.global_position = Vector2(100.0, -58.0)
		for _pf in range(20):
			await physics_frame
		assert_true(absf(frame.global_position.y - (-58.0)) < 0.001, "WallFrameItem stays at y=-58 without gravity")

		frame.global_position = Vector2(150.0, -36.0)
		for _pf in range(20):
			await physics_frame
		assert_true(absf(frame.global_position.y - (-36.0)) < 0.001, "WallFrameItem stays at y=-36 without gravity")

		assert_eq(frame.cari_lantai_terdekat(150.0, -45.0), -45.0, "WallFrameItem cari_lantai_terdekat returns input y")

		# Verify WallFrameItem drag clamping keeps frames strictly inside walls, ceiling, and floor
		var r2_hw: float = frame.call("get_visual_half_width")
		var r2_hh: float = frame.get_visual_bottom_offset()
		player.global_position = Vector2(250.0, -140.0)
		frame.start_drag()
		await physics_frame
		assert_true(frame.global_position.x - r2_hw >= 8.0 - 0.01 and frame.global_position.x + r2_hw <= 200.0 + 0.01, "R2 frame clamped inside X walls top-right")
		assert_true(frame.global_position.y - r2_hh >= -94.0 - 0.01 and frame.global_position.y + r2_hh <= -1.0 + 0.01, "R2 frame clamped below ceiling top-right")
		frame.stop_drag()

		player.global_position = Vector2(250.0, 50.0)
		frame.start_drag()
		await physics_frame
		assert_true(frame.global_position.x - r2_hw >= 8.0 - 0.01 and frame.global_position.x + r2_hw <= 200.0 + 0.01, "R2 frame clamped inside X walls bottom-right")
		assert_true(frame.global_position.y - r2_hh >= -94.0 - 0.01 and frame.global_position.y + r2_hh <= -1.0 + 0.01, "R2 frame clamped above floor bottom-right")
		frame.stop_drag()

		if r1_map.has("frame_01"):
			var r1_frame: InteractiveItem = r1_map["frame_01"]
			var r1_hw: float = r1_frame.call("get_visual_half_width")
			var r1_hh: float = r1_frame.get_visual_bottom_offset()
			player.global_position = Vector2(-250.0, -140.0)
			r1_frame.start_drag()
			await physics_frame
			assert_true(r1_frame.global_position.x - r1_hw >= -199.0 - 0.01 and r1_frame.global_position.x + r1_hw <= -9.0 + 0.01, "R1 frame clamped inside X walls top-left")
			assert_true(r1_frame.global_position.y - r1_hh >= -94.0 - 0.01 and r1_frame.global_position.y + r1_hh <= -1.0 + 0.01, "R1 frame clamped below ceiling top-left")
			r1_frame.stop_drag()

			player.global_position = Vector2(-250.0, 50.0)
			r1_frame.start_drag()
			await physics_frame
			assert_true(r1_frame.global_position.x - r1_hw >= -199.0 - 0.01 and r1_frame.global_position.x + r1_hw <= -9.0 + 0.01, "R1 frame clamped inside X walls bottom-left")
			assert_true(r1_frame.global_position.y - r1_hh >= -94.0 - 0.01 and r1_frame.global_position.y + r1_hh <= -1.0 + 0.01, "R1 frame clamped above floor bottom-left")
			r1_frame.stop_drag()

	# Mirror all Room 2 items including WallFrameItem and verify SymmetryChecker evaluates 2/2
	var all_r2: Array[InteractiveItem] = []
	all_r2.append_array(r2_floor_items)
	for wf in r2_frames:
		all_r2.append(wf)
	for r2 in all_r2:
		var id: String = r2.item_id.strip_edges()
		if r1_map.has(id):
			var r1: InteractiveItem = r1_map[id]
			r2.sync_to_physics = false
			r2.global_position = Vector2(-r1.global_position.x, r1.global_position.y)
			if not is_instance_of(r2, preload("res://script/wall_frame_item.gd")):
				r2.sync_to_physics = true

	var eval_res: Dictionary = checker.call("hitung_evaluasi")
	assert_eq(eval_res.get("status", ""), "success", "Level06 2/2 mirrored frame+furniture passes SymmetryChecker")
	assert_eq(eval_res.get("text", ""), "BERHASIL!\n(2/2)", "Level06 SymmetryChecker counts 2/2 including wall frame")

	paused = false
	unload_current_scene()
	await process_frame

	# Isolated test: verify floor furniture never stacks onto a WallFrameItem positioned directly above
	var host := Node2D.new()
	root.add_child(host)
	var test_frame := WALL_FRAME_SCENE.instantiate() as InteractiveItem
	test_frame.position = Vector2(100.0, -55.0)
	host.add_child(test_frame)
	var test_stool := PROP_SCENE.instantiate() as InteractiveItem
	test_stool.position = Vector2(100.0, -12.0)
	host.add_child(test_stool)
	await process_frame

	var support_y: float = test_stool.cari_lantai_terdekat(test_frame.global_position.x, -70.0)
	assert_true(absf(support_y - test_stool.floor_y) < 0.01, "Floor furniture ignores WallFrameItem when finding support")

	host.queue_free()
	await process_frame

	if gm:
		gm.set("current_level", orig_level)
		gm.set("is_replaying", orig_replaying)

	return true


func _get_item_visual_rect(it: InteractiveItem) -> Rect2:
	var spr := it.get_node_or_null("Sprite2D") as Sprite2D
	var tex_sz: Vector2 = spr.texture.get_size() if (spr and spr.texture) else Vector2(14.0, 14.0)
	var spr_sc: Vector2 = spr.scale if spr else Vector2.ONE
	var spr_pos: Vector2 = spr.position if spr else Vector2.ZERO
	var size := Vector2(tex_sz.x * absf(spr_sc.x), tex_sz.y * absf(spr_sc.y))
	return Rect2(it.global_position + spr_pos - size * 0.5, size)


func _assert_strict_z_order(level: Node2D, player: CharacterBody2D, lvl: int, context_label: String) -> void:
	var wall_script := preload("res://script/wall_frame_item.gd")
	var player_idx: int = player.get_index()
	var max_frame_idx: int = -1
	var min_floor_idx: int = 999999

	for n in level.find_children("*", "InteractiveItem", true, false):
		var it := n as InteractiveItem
		if not it or not it.visible or it.is_queued_for_deletion():
			continue
		assert_eq(it.get_parent(), level, "Direct child of level L%d %s (%s)" % [lvl, it.item_id, context_label])
		var idx: int = it.get_index()
		assert_true(idx < player_idx, "Renders behind Player L%d %s (%s)" % [lvl, it.item_id, context_label])
		if is_instance_of(it, wall_script):
			max_frame_idx = maxi(max_frame_idx, idx)
		else:
			min_floor_idx = mini(min_floor_idx, idx)

	if max_frame_idx >= 0 and min_floor_idx < 999999:
		assert_true(max_frame_idx < min_floor_idx, "WallFrames render behind Floor items L%d (%s)" % [lvl, context_label])


func _assert_room1_clean_and_mirrorable(level: Node2D, lvl: int) -> void:
	var wall_script := preload("res://script/wall_frame_item.gd")
	var r1_items: Array[InteractiveItem] = []
	var r1_rects: Array[Rect2] = []
	for n in level.find_children("*", "InteractiveItem", true, false):
		var it := n as InteractiveItem
		if not it or not it.visible or it.is_queued_for_deletion() or it.home_room != 1:
			continue
		var rect: Rect2 = _get_item_visual_rect(it)
		r1_items.append(it)
		r1_rects.append(rect)

		var mirror_x: float = -it.global_position.x
		if is_instance_of(it, wall_script):
			var hw: float = rect.size.x * 0.5
			var hh: float = rect.size.y * 0.5
			assert_true(mirror_x >= 8.0 + hw + 1.0 - 0.01 and mirror_x <= 200.0 - hw - 1.0 + 0.01, "R1 frame mirror X in drag bounds L%d %s" % [lvl, it.item_id])
			assert_true(it.global_position.y >= -96.0 + hh + 2.0 - 0.01 and it.global_position.y <= -hh - 1.0 + 0.01, "R1 frame mirror Y in drag bounds L%d %s" % [lvl, it.item_id])
		else:
			assert_true(mirror_x >= 11.0 - 0.01 and mirror_x <= 193.0 + 0.01, "R1 furniture mirror X in drag bounds L%d %s" % [lvl, it.item_id])

	for i in range(r1_items.size()):
		for j in range(i + 1, r1_items.size()):
			var a: Rect2 = r1_rects[i]
			var b: Rect2 = r1_rects[j]
			var h_ov: float = minf(a.end.x, b.end.x) - maxf(a.position.x, b.position.x)
			var v_ov: float = minf(a.end.y, b.end.y) - maxf(a.position.y, b.position.y)
			assert_true(not (h_ov > 0.5 and v_ov > 0.5), "No R1 visual overlap L%d (%s vs %s)" % [lvl, r1_items[i].item_id, r1_items[j].item_id])


func _assert_room2_no_frame_furniture_overlap(spawner: Room2Spawner, lvl: int, iter: int) -> void:
	var frames: Array[Dictionary] = []
	var furns: Array[Dictionary] = []
	for rec in spawner.last_spawn_records:
		if bool(rec.get("is_wall_mounted", false)):
			frames.append(rec)
		else:
			furns.append(rec)
	for f in frames:
		for g in furns:
			var h_ov: float = minf(float(f["right"]), float(g["right"])) - maxf(float(f["left"]), float(g["left"]))
			var v_ov: float = minf(float(f["bottom"]), float(g["bottom"])) - maxf(float(f["top"]), float(g["top"]))
			assert_true(not (h_ov > 0.5 and v_ov > 0.5), "No R2 frame vs furniture overlap L%d iter %d (%s vs %s)" % [lvl, iter, str(f["item_id"]), str(g["item_id"])])
