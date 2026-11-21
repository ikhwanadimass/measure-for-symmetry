extends SceneTree

var passed := 0
var failed := 0

func _initialize() -> void:
	for t: String in ["test_exact_mirror_wins", "test_out_of_tolerance_loses", "test_missing_room1_item_loses"]:
		if call(t) != true:
			failed += 1
			push_error("FAIL %s: runtime error" % t)
	print("test_symmetry_checker: %d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)

func assert_eq(actual, expected, label: String) -> void:
	if actual == expected:
		passed += 1
	else:
		failed += 1
		push_error("FAIL %s: expected %s, got %s" % [label, expected, actual])

func _make_item(id: String, pos: Vector2) -> InteractiveItem:
	var item := InteractiveItem.new()
	item.item_id = id
	item.global_position = pos
	item.initial_position = pos
	var col := CollisionShape2D.new()
	col.name = "CollisionShape2D"
	item.add_child(col)
	return item

func _make_world(r1_pos: Vector2, r2_pos: Vector2, include_r1: bool = true) -> Node2D:
	var world := Node2D.new()
	var checker_script := load("res://script/symmetry_checker.gd") as GDScript
	var checker: Node = checker_script.new()
	checker.name = "SymmetryChecker"
	world.add_child(checker)
	var r2 := _make_item("stool_01", r2_pos)
	world.add_child(r2)
	if include_r1:
		var r1 := _make_item("stool_01", r1_pos)
		world.add_child(r1)
	return world

func test_exact_mirror_wins() -> bool:
	var world := _make_world(Vector2(-120.0, -12.0), Vector2(124.0, -12.0))
	var checker := world.get_node("SymmetryChecker")
	var res: Dictionary = checker.evaluate_symmetry(0.0, 40.0)
	assert_eq(res["won"], true, "4px delta within 6px tolerance wins")
	assert_eq(res["matched_count"], 1, "matched_count is 1")
	assert_eq(res["total_count"], 1, "total_count is 1")
	assert_eq(is_equal_approx(res["items"][0]["delta_m"], 0.10), true, "delta_m is 0.10")
	world.free()
	return true

func test_out_of_tolerance_loses() -> bool:
	var world := _make_world(Vector2(-100.0, -12.0), Vector2(120.0, -12.0))
	var checker := world.get_node("SymmetryChecker")
	var res: Dictionary = checker.evaluate_symmetry(0.0, 40.0)
	assert_eq(res["won"], false, "20px delta fails")
	assert_eq(res["matched_count"], 0, "matched_count is 0")
	assert_eq(res["items"][0]["passed"], false, "item passed false")
	world.free()
	return true

func test_missing_room1_item_loses() -> bool:
	var world := _make_world(Vector2.ZERO, Vector2(120.0, -12.0), false)
	var checker := world.get_node("SymmetryChecker")
	var res: Dictionary = checker.evaluate_symmetry(0.0, 40.0)
	assert_eq(res["won"], false, "missing Room 1 item loses")
	assert_eq(res["items"][0]["missing_in_room1"], true, "missing_in_room1 flagged")
	world.free()
	return true
