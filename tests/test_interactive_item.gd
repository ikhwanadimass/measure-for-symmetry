extends SceneTree

var passed := 0
var failed := 0

func _initialize() -> void:
	if await run_tests() != true:
		failed += 1
		push_error("FAIL run_tests: did not finish (runtime error?)")
	print("test_interactive_item: %d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)

func assert_eq(actual, expected, label: String) -> void:
	if actual == expected:
		passed += 1
	else:
		failed += 1
		push_error("FAIL %s: expected %s, got %s" % [label, expected, actual])

func _make_item(pos: Vector2, rest_offset: float = 12.0) -> InteractiveItem:
	var item_script := load("res://script/interactive_item.gd") as GDScript
	var item: InteractiveItem = item_script.new()
	item.position = pos
	item.floor_rest_offset = rest_offset
	var col := CollisionShape2D.new()
	col.name = "CollisionShape2D"
	col.one_way_collision = true
	var rect := RectangleShape2D.new()
	rect.size = Vector2(16.0, 12.0)
	col.shape = rect
	item.add_child(col)
	return item

func run_tests() -> bool:
	await process_frame
	var item_r2 := _make_item(Vector2(120.0, -12.0))
	var item_r1 := _make_item(Vector2(-120.0, -18.0), 18.0)
	root.add_child(item_r2)
	root.add_child(item_r1)
	await process_frame

	assert_eq(item_r2.is_locked_reference, true, "Room 2 item is locked reference")
	item_r2.start_drag()
	assert_eq(item_r2.is_dragging, false, "Room 2 item refuses start_drag")

	assert_eq(item_r1.is_locked_reference, false, "Room 1 item is draggable")
	item_r1.interaction_blocked = true
	item_r1.start_drag()
	assert_eq(item_r1.is_dragging, false, "blocked Room 1 item refuses start_drag")

	item_r1.interaction_blocked = false
	item_r1.start_drag()
	assert_eq(item_r1.is_dragging, true, "unblocked Room 1 item starts drag")
	item_r1.cancel_drag()
	assert_eq(item_r1.is_dragging, false, "cancel_drag stops drag")

	# Stacking & collision_layer check: upper item dropped above item_r1 must detect it on mask 2
	item_r1.global_position = Vector2(-120.0, -12.0)
	var item_upper := _make_item(Vector2(-120.0, -40.0), 12.0)
	root.add_child(item_upper)
	await physics_frame
	for _i in range(15):
		await physics_frame
	assert_eq(item_upper.collision_layer & 2, 2, "InteractiveItem uses physics layer 2 for stacking")
	assert_eq(item_upper.global_position.y <= -24.0, true, "upper item stacks above lower item instead of falling to floor")

	item_upper.free()
	item_r2.free()
	item_r1.free()
	await process_frame
	return true
