extends SceneTree

var passed := 0
var failed := 0

func _initialize() -> void:
	if await run_tests() != true:
		failed += 1
		push_error("FAIL run_tests: did not finish (runtime error?)")
	print("test_measure_tool: %d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)

func assert_eq(actual, expected, label: String) -> void:
	if actual == expected:
		passed += 1
	else:
		failed += 1
		push_error("FAIL %s: expected %s, got %s" % [label, expected, actual])

func run_tests() -> bool:
	await process_frame
	var world := Node2D.new()
	var player := CharacterBody2D.new()
	player.name = "Player"
	player.position = Vector2(120.0, -18.0)
	world.add_child(player)

	var item := InteractiveItem.new()
	item.item_id = "stool_01"
	item.position = Vector2(100.0, -24.0)
	var col := CollisionShape2D.new()
	col.name = "CollisionShape2D"
	item.add_child(col)
	world.add_child(item)

	var tool_scene := load("res://scene/measure_tool.tscn") as PackedScene
	var tool: Node2D = tool_scene.instantiate() as Node2D
	world.add_child(tool)
	root.add_child(world)
	await process_frame

	tool.set_room_context(2, 0.0, 0.0, 40.0)
	var step_messages: Array[String] = []
	tool.step_changed.connect(func(msg: String): step_messages.append(msg))
	tool.set_active(true)
	assert_eq(step_messages.size() >= 1, true, "emits initial ruler step guidance")

	# Far from door/center wall & player far -> rejected
	assert_eq(tool.try_anchor_at(Vector2(90.0, -50.0)), false, "click far from door rejected")

	# Click near door / center wall -> anchors horizontally and measures item X distance in meters
	assert_eq(tool.try_anchor_at(Vector2(16.0, -30.0)), true, "door/wall click anchors")
	assert_eq(tool.try_measure_item(item), true, "item measured horizontally from door")
	var line: Line2D = tool.get_node("Line2D") as Line2D
	var label: Label = tool.get_node("DistanceLabel") as Label
	assert_eq(line.get_point_position(0), Vector2(0.0, -24.0), "horizontal start at door x=0")
	assert_eq(line.get_point_position(1), Vector2(100.0, -24.0), "horizontal end at item")
	assert_eq(label.text, "2.50 m", "100px = 2.50 m")
	assert_eq(step_messages.back().contains("2.50 m"), true, "step_changed reports measured distance")

	# Cable pull mode: player near door anchors even when clicking elsewhere, then walks to 160 -> 4.00 m
	tool.reset_measurement()
	player.global_position = Vector2(15.0, -18.0)
	assert_eq(tool.try_anchor_at(Vector2(45.0, -18.0)), true, "anchors at door when player stands near door")
	player.global_position = Vector2(160.0, -18.0)
	tool.update_cable_to_player()
	assert_eq(line.get_point_position(0), Vector2(0.0, -18.0), "cable starts at door x=0")
	assert_eq(line.get_point_position(1), Vector2(160.0, -18.0), "cable follows player horizontally")
	assert_eq(label.text, "4.00 m", "160px = 4.00 m")
	tool.lock_current_measurement()
	assert_eq(tool.is_locked, true, "lock_current_measurement locks cable")

	world.free()
	await process_frame
	return true
