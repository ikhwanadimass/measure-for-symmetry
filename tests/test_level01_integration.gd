extends SceneTree

var passed := 0
var failed := 0

func _initialize() -> void:
	if await run_tests() != true:
		failed += 1
		push_error("FAIL run_tests: did not finish (runtime error?)")
	print("test_level01_integration: %d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)

func assert_eq(actual, expected, label: String) -> void:
	if actual == expected:
		passed += 1
	else:
		failed += 1
		push_error("FAIL %s: expected %s, got %s" % [label, expected, actual])

func run_tests() -> bool:
	await process_frame
	var level_scene := load("res://scene/Level01.tscn") as PackedScene
	var level: Node2D = level_scene.instantiate() as Node2D
	root.add_child(level)
	await process_frame

	var hud := level.get_node("HUD")
	var player := level.get_node("Player") as CharacterBody2D
	var measure_tool := level.get_node("MeasureTool")
	var portal := level.get_node("DoorPortal") as Area2D

	var cam := player.get_node("Camera2D") as Camera2D

	# 1. Initial state & Room 2 elevated layout & 6.5x camera
	assert_eq(level.current_room, 1, "starts in Room 1")
	assert_eq(level.entries_remaining, 3, "starts with 3 quota")
	assert_eq(level.room2_time_limit, 25.0, "Room 2 timer gives 25s for measuring X & Y")
	assert_eq(cam.zoom, Vector2(6.5, 6.5), "camera uses prototype 6.5x zoom")
	var bookcase_r2 := level.get_node("Bookcase_Room2") as InteractiveItem
	var lamp_r2 := level.get_node("Lamp_Room2") as InteractiveItem
	assert_eq(lamp_r2.position.y < bookcase_r2.position.y - 10.0, true, "Lamp_Room2 stacked above Bookcase_Room2 for Y measurement")
	assert_eq((hud.get_node("%MissionButton") as Button).disabled, false, "Selesaikan Misi enabled in Room 1")

	# 2. Enter Room 2 consumes 1 quota, disables Selesaikan Misi, & timer expiry force-returns to Room 1 + resets ruler
	level._on_portal_requested(1)
	assert_eq(level.current_room, 2, "entered Room 2")
	assert_eq(level.entries_remaining, 2, "quota decremented to 2")
	assert_eq((hud.get_node("%TimerLabel") as Control).visible, true, "TimerLabel visible in Room 2")
	assert_eq((hud.get_node("%MissionButton") as Button).disabled, true, "Selesaikan Misi disabled in Room 2")
	level._on_phone_pressed()
	assert_eq(level.is_level_ended, false, "calling Selesaikan Misi in Room 2 does not end level")
	measure_tool.set_active(true)
	measure_tool.try_anchor_at(Vector2(2.0, -20.0))
	level.force_expire_room2_timer()
	assert_eq(level.current_room, 1, "timer expiry force-returned to Room 1")
	assert_eq(player.global_position.x, level.room1_spawn_x, "player moved back to Room 1")
	assert_eq(measure_tool.is_anchored, false, "ruler anchor cleared on force-return")
	assert_eq((hud.get_node("%TimerLabel") as Control).visible, false, "TimerLabel hidden after return to Room 1")
	assert_eq((portal.get_node("PromptLabel") as Label).text.contains("2"), true, "DoorPortal prompt updated to remaining quota")

	# 3. Exhausting remaining 2 entries blocks 4th entry and shows toast
	level._on_portal_requested(1)
	level._on_portal_requested(2)
	level._on_portal_requested(1)
	assert_eq(level.entries_remaining, 0, "quota now 0")
	level._on_portal_requested(2)
	assert_eq(level.current_room, 1, "back in Room 1 with 0 quota")
	level._on_portal_requested(1)
	assert_eq(level.current_room, 1, "4th entry blocked")
	assert_eq(level.entries_remaining, 0, "quota stays 0")
	assert_eq((hud.get_node("%ToastLabel") as Control).visible, true, "quota-exhausted toast shown")

	# 4. Notes focus locks player & items via signal (no manual _refresh_input_locks); Ruler active blocks item drag
	hud.toggle_notes()
	assert_eq(player.input_locked, true, "notes signal locks player movement")
	hud.toggle_notes()
	assert_eq(player.input_locked, false, "closing notes signal unlocks player")

	var r1_stool := level.get_node("Stool") as InteractiveItem
	measure_tool.set_active(true)
	assert_eq(r1_stool.interaction_blocked, true, "active ruler blocks item drag")
	measure_tool.set_active(false)
	assert_eq(r1_stool.interaction_blocked, false, "inactive ruler allows item drag")

	# 5. Selesaikan Misi initially loses (Klien Marah!), then wins (Klien Senang!) when all mirrored
	level._on_phone_pressed()
	assert_eq((hud.get_node("%PhonePanel") as Control).visible, true, "smartphone opens result")
	assert_eq((hud.get_node("%PhoneResultScreen") as Control).visible, true, "result screen visible")
	assert_eq((hud.get_node("%ResultTitleLabel") as Label).text.contains("Klien Marah"), true, "messy room triggers Klien Marah!")

	for item_node: Node in level.get_children():
		if item_node is InteractiveItem and (item_node as InteractiveItem).home_room == 1:
			var item_r1 := item_node as InteractiveItem
			for ref_node: Node in level.get_children():
				if ref_node is InteractiveItem and (ref_node as InteractiveItem).home_room == 2 and (ref_node as InteractiveItem).item_id == item_r1.item_id:
					var ref_r2 := ref_node as InteractiveItem
					item_r1.global_position = Vector2(-ref_r2.initial_position.x, ref_r2.initial_position.y)
	level.is_level_ended = false
	level._on_phone_pressed()
	assert_eq((hud.get_node("%ResultTitleLabel") as Label).text.contains("Klien Senang"), true, "mirrored room triggers Klien Senang!")

	level.free()
	await process_frame
	return true
