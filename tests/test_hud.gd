extends SceneTree

var passed := 0
var failed := 0

func _initialize() -> void:
	if await run_tests() != true:
		failed += 1
		push_error("FAIL run_tests: did not finish (runtime error?)")
	print("test_hud: %d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)

func assert_eq(actual, expected, label: String) -> void:
	if actual == expected:
		passed += 1
	else:
		failed += 1
		push_error("FAIL %s: expected %s, got %s" % [label, expected, actual])

func run_tests() -> bool:
	await process_frame
	var hud_scene := load("res://scene/ui/hud.tscn") as PackedScene
	var hud: CanvasLayer = hud_scene.instantiate() as CanvasLayer
	root.add_child(hud)
	await process_frame

	hud.update_status(2, 2, 3, 4.5)
	assert_eq((hud.get_node("%RoomLabel") as Label).text, "Ruang 2 (Acuan)", "room label shows Room 2")
	assert_eq((hud.get_node("%QuotaLabel") as Label).text, "Kuota: 2/3", "quota label formatted")
	assert_eq((hud.get_node("%TimerLabel") as Label).visible, true, "timer visible in Room 2")
	assert_eq((hud.get_node("%TimerLabel") as Label).text.contains("4.5"), true, "timer shows 4.5s")
	assert_eq((hud.get_node("%MissionButton") as Button).disabled, true, "Selesaikan Misi disabled in Room 2")

	assert_eq(hud.is_blocking_world_input(), false, "initially not blocking")
	hud.toggle_notes()
	assert_eq((hud.get_node("%PhonePanel") as Control).visible, true, "smartphone opened for notes")
	assert_eq((hud.get_node("%PhoneNotesScreen") as Control).visible, true, "nota screen visible")
	assert_eq(hud.is_blocking_world_input(), true, "smartphone notes blocks world input")
	hud.toggle_notes()
	assert_eq((hud.get_node("%PhonePanel") as Control).visible, false, "smartphone closed")

	hud.show_result({
		"won": true,
		"matched_count": 2,
		"total_count": 2,
		"items": [
			{"item_id": "stool_01", "passed": true, "delta_m": 0.05, "delta_px": 2.0, "missing_in_room1": false}
		]
	})
	assert_eq((hud.get_node("%PhonePanel") as Control).visible, true, "smartphone opened for result")
	assert_eq((hud.get_node("%PhoneResultScreen") as Control).visible, true, "result screen visible")
	assert_eq((hud.get_node("%ResultTitleLabel") as Label).text.contains("Klien Senang"), true, "win title shows Klien Senang!")
	assert_eq(hud.is_blocking_world_input(), true, "result screen blocks world input")

	hud.free()
	await process_frame
	return true
