extends SceneTree

var passed := 0
var failed := 0
var requested_from := -1

func _initialize() -> void:
	if await run_tests() != true:
		failed += 1
		push_error("FAIL run_tests: did not finish (runtime error?)")
	print("test_door_portal: %d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)

func assert_eq(actual, expected, label: String) -> void:
	if actual == expected:
		passed += 1
	else:
		failed += 1
		push_error("FAIL %s: expected %s, got %s" % [label, expected, actual])

func _on_portal_requested(from_room: int) -> void:
	requested_from = from_room

func run_tests() -> bool:
	await process_frame
	var portal_scene := load("res://scene/door_portal.tscn") as PackedScene
	var portal: Area2D = portal_scene.instantiate() as Area2D
	var player := CharacterBody2D.new()
	player.position = Vector2(-10.0, -12.0)
	var cam := Camera2D.new()
	cam.name = "Camera2D"
	player.add_child(cam)
	root.add_child(portal)
	root.add_child(player)
	await process_frame

	portal.portal_requested.connect(_on_portal_requested)
	portal._on_body_entered(player)
	portal.update_prompt(1, 2)
	var prompt: Label = portal.get_node("PromptLabel") as Label
	assert_eq(prompt.visible, true, "prompt visible when player near")
	assert_eq(prompt.text.contains("2"), true, "prompt shows remaining quota")

	portal.trigger_portal()
	assert_eq(requested_from, 1, "emits portal_requested from Room 1")

	portal.teleport_player_to(player, 2, 40.0)
	assert_eq(player.global_position.x, 40.0, "teleported to Room 2 x=40")
	assert_eq(cam.limit_left, 4, "camera limit_left restores 6.5x Room 2 view")
	assert_eq(cam.limit_right, 204, "camera limit_right restores 6.5x Room 2 view")

	portal.free()
	player.free()
	await process_frame
	return true
