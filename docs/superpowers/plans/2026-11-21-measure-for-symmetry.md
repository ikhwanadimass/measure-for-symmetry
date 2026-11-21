# Measure For Symmetry Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the complete playable core loop of *Measure For Symmetry* in `Level01.tscn` (Ruang 2 3x entry quota + countdown auto-return, wall/floor-to-item Ruler in meters, Notes `TextEdit` popup, Room 1-only drag-and-drop, Telepon Klien symmetry evaluation, and Win/Lose HUD with restart).

**Architecture:** Modular per-level controller (`script/level_controller.gd`) on `Level01` coordinating `DoorPortal`, `MeasureTool`, `InteractiveItem`, `SymmetryChecker`, `Player`, and a reusable `HUD.tscn` (`CanvasLayer`) via typed signals and explicit room/input-lock APIs—no global autoload singletons.

**Tech Stack:** Godot 4.7.2 (`GL Compatibility`), GDScript 2.0, headless verification via `D:\Godot_v4.7.2-stable_win64\Godot_v4.7.2-stable_win64_console.exe --headless --path . --script <test_script>`.

**Spec:** [2026-11-21-measure-for-symmetry-design.md](file:///d:/My%20Project/Godot%20Projects/measure-for-symmetry/docs/superpowers/specs/2026-11-21-measure-for-symmetry-design.md)

## Global Constraints

- Godot 4.7.2 (`GL Compatibility`), `1280x480` viewport (`canvas_items` / `expand`), `default_texture_filter=0`.
- World coordinates: central dividing wall `center_x = 0.0`, floor surface `floor_y = 0.0`, Ruang 1 `x in [-200, 0]`, Ruang 2 `x in [0, 200]`.
- Scale & tolerance: `pixels_per_meter = 40.0` (`200 px = 5.00 m`), `TOLERANSI = 6.0` px (`0.15 m`).
- Ruang 2 visit rules: `max_room2_entries = 3`, `room2_time_limit = 15.0` s; timer expiry force-returns player to Ruang 1 (Option A).
- Ruler allows clicking anywhere in the currently active room (no `35 px` player proximity check); Ruang 1 item dragging keeps `MAX_DISTANCE = 35.0`; Ruang 2 items are locked reference objects.
- Keep `project.godot` autoload-free; all level state resets cleanly via `get_tree().reload_current_scene()`.

## Review Focus

- Typing `A`, `D`, `W`, `E`, `F`, `N`, or `Enter` inside the Notes `TextEdit` must never move `Player`, toggle `MeasureTool`, activate `DoorPortal`, or evaluate symmetry.
- When the Ruang 2 countdown expires mid-measurement, `LevelController` must force-return `Player` to Ruang 1, reset `MeasureTool` lines/anchors, and update `HUD` + `DoorPortal` prompt immediately.
- Clicking an `InteractiveItem` in Ruang 1 while `MeasureTool` is active must measure the item rather than drag it.
- Calling `SymmetryChecker.evaluate_symmetry()` when a Ruang 1 item is missing or out of tolerance must return `won = false` with accurate per-item status and zero null-reference errors.
- Pressing `interact` (`E`) at `DoorPortal` in Ruang 1 when `entries_remaining == 0` must keep the player in Ruang 1, keep `entries_remaining == 0`, and trigger the HUD quota-exhausted toast.

---

### Task 1: Structured `SymmetryChecker` Evaluation

**Files:**
- Modify: `script/symmetry_checker.gd:1-59`
- Test: `tests/test_symmetry_checker.gd`

**Interfaces:**
- Consumes: `InteractiveItem` nodes in parent tree (`item.item_id: String`, `item.global_position: Vector2`, `item.initial_position: Vector2`).
- Produces: `SymmetryChecker.evaluate_symmetry(center_x: float = 0.0, pixels_per_meter: float = 40.0) -> Dictionary` returning `{ "won": bool, "matched_count": int, "total_count": int, "items": Array[Dictionary] }` where each item entry is `{ "item_id": String, "passed": bool, "delta_m": float, "delta_px": float, "missing_in_room1": bool }`.

- [ ] **Step 1: Write the failing test `tests/test_symmetry_checker.gd`**

```gdscript
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
	item.add_child(col)
	return item

func _make_world(r1_pos: Vector2, r2_pos: Vector2, include_r1: bool = true) -> Node2D:
	var world := Node2D.new()
	var checker := load("res://script/symmetry_checker.gd").new()
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `D:\Godot_v4.7.2-stable_win64\Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/test_symmetry_checker.gd`
Expected: FAIL (`evaluate_symmetry` method not found / returns null).

- [ ] **Step 3: Implement `evaluate_symmetry(center_x: float = 0.0, pixels_per_meter: float = 40.0) -> Dictionary` in `script/symmetry_checker.gd`**

Update `script/symmetry_checker.gd`:
- Remove `_unhandled_input` (`ui_accept` trigger) so evaluation only happens when triggered explicitly (e.g. Telepon Klien).
- Implement `evaluate_symmetry(center_x: float = 0.0, pixels_per_meter: float = 40.0) -> Dictionary`:
  - Partition `InteractiveItem` children of `get_parent()` by `item.global_position.x < center_x` (Room 1) vs `>= center_x` (Room 2).
  - For each `id` in Room 2, compute mirrored target `Vector2(2.0 * center_x - ref_pos.x, ref_pos.y)` using `item_r2.initial_position`.
  - Track missing Room 1 items (`missing_in_room1 = true`, `passed = false`, `delta_px = -1.0`, `delta_m = -1.0`) and valid items (`delta_px <= TOLERANSI`, `delta_m = delta_px / pixels_per_meter`).
  - Set `won = (total_count > 0 and matched_count == total_count)` and return the structured dictionary.

- [ ] **Step 4: Run test to verify it passes**

Run: `D:\Godot_v4.7.2-stable_win64\Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/test_symmetry_checker.gd`
Expected: Exit code `0`, `test_symmetry_checker: 8 passed, 0 failed`.

- [ ] **Step 5: Commit**

```bash
git add script/symmetry_checker.gd tests/test_symmetry_checker.gd
git commit -m "feat: return structured symmetry results from SymmetryChecker"
```

---

### Task 2: `InteractiveItem` Room 2 Locking & Flexible Floor Rest

**Files:**
- Modify: `script/interactive_item.gd:1-84`
- Test: `tests/test_interactive_item.gd`

**Interfaces:**
- Consumes: nothing.
- Produces:
  - `@export var floor_rest_offset: float = 12.0`
  - `@export var floor_y: float = 0.0`
  - `var is_locked_reference: bool` (`true` when `home_room == 2`)
  - `var interaction_blocked: bool` (blocks drag start & cancels active drag when `true`)
  - `cancel_drag() -> void`

- [ ] **Step 1: Write the failing test `tests/test_interactive_item.gd`**

```gdscript
extends SceneTree

var passed := 0
var failed := 0

func _initialize() -> void:
	await run_tests()
	print("test_interactive_item: %d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)

func assert_eq(actual, expected, label: String) -> void:
	if actual == expected:
		passed += 1
	else:
		failed += 1
		push_error("FAIL %s: expected %s, got %s" % [label, expected, actual])

func _make_item(pos: Vector2, rest_offset: float = 12.0) -> InteractiveItem:
	var item: InteractiveItem = load("res://script/interactive_item.gd").new()
	item.position = pos
	item.floor_rest_offset = rest_offset
	var col := CollisionShape2D.new()
	col.name = "CollisionShape2D"
	item.add_child(col)
	return item

func run_tests() -> void:
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

	item_r2.queue_free()
	item_r1.queue_free()
	await process_frame
```

- [ ] **Step 2: Run test to verify it fails**

Run: `D:\Godot_v4.7.2-stable_win64\Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/test_interactive_item.gd`
Expected: FAIL (`is_locked_reference` / `interaction_blocked` / `cancel_drag` not declared).

- [ ] **Step 3: Update `script/interactive_item.gd`**

- Replace hardcoded `FLOOR_Y` constant with `@export var floor_y: float = 0.0` and `@export var floor_rest_offset: float = 12.0` (rest target = `floor_y - floor_rest_offset`).
- Add `var is_locked_reference: bool = false` (set to `home_room == 2` in `_ready()`).
- Add `var interaction_blocked: bool = false` (with setter calling `cancel_drag()` if set to `true`).
- Guard `_input_event` and `start_drag()` with `if is_locked_reference or interaction_blocked: return`.
- Add `cancel_drag() -> void` calling `stop_drag()` when `is_dragging` is `true`.
- Keep Room 1 clamping (`x in [-193.0, -11.0]`, `y in [-85.0, floor_y - floor_rest_offset]`) and raycast stacking using `floor_y - floor_rest_offset`.

- [ ] **Step 4: Run test to verify it passes**

Run: `D:\Godot_v4.7.2-stable_win64\Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/test_interactive_item.gd`
Expected: Exit code `0`, `test_interactive_item: 6 passed, 0 failed`.

- [ ] **Step 5: Commit**

```bash
git add script/interactive_item.gd tests/test_interactive_item.gd
git commit -m "feat: lock Room 2 reference items and support per-item floor rest offset"
```

---

### Task 3: `MeasureTool` Wall/Floor → Item Snap & Meter Readout

**Files:**
- Modify: `script/measure_tool.gd:1-104`
- Modify: `scene/measure_tool.tscn:1-25`
- Test: `tests/test_measure_tool.gd`

**Interfaces:**
- Consumes: `InteractiveItem` nodes in parent (`item.global_position`).
- Produces:
  - `signal active_changed(is_active: bool)`
  - `signal hint_requested(message: String)`
  - `set_active(active: bool) -> void`
  - `set_room_context(room: int, center_x: float, floor_y: float, pixels_per_meter: float) -> void`
  - `set_input_blocked(blocked: bool) -> void`
  - `reset_measurement() -> void`
  - `try_anchor_at(world_pos: Vector2) -> bool`
  - `try_measure_item(item: InteractiveItem) -> bool`

- [ ] **Step 1: Write the failing test `tests/test_measure_tool.gd`**

```gdscript
extends SceneTree

var passed := 0
var failed := 0

func _initialize() -> void:
	await run_tests()
	print("test_measure_tool: %d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)

func assert_eq(actual, expected, label: String) -> void:
	if actual == expected:
		passed += 1
	else:
		failed += 1
		push_error("FAIL %s: expected %s, got %s" % [label, expected, actual])

func run_tests() -> void:
	await process_frame
	var world := Node2D.new()
	var item := InteractiveItem.new()
	item.position = Vector2(100.0, -24.0)
	var col := CollisionShape2D.new()
	col.name = "CollisionShape2D"
	item.add_child(col)
	world.add_child(item)

	var tool: Node2D = load("res://scene/measure_tool.tscn").instantiate()
	world.add_child(tool)
	root.add_child(world)
	await process_frame

	tool.set_room_context(2, 0.0, 0.0, 40.0)
	tool.set_active(true)

	# Click away from wall and floor -> does not anchor
	assert_eq(tool.try_anchor_at(Vector2(90.0, -50.0)), false, "mid-air click rejected")

	# Click near central wall (x = 0) -> snaps X axis and measures horizontal meters
	assert_eq(tool.try_anchor_at(Vector2(6.0, -30.0)), true, "wall click anchors")
	assert_eq(tool.try_measure_item(item), true, "item measured from wall")
	var line: Line2D = tool.get_node("Line2D")
	var label: Label = tool.get_node("DistanceLabel")
	assert_eq(line.get_point_position(0), Vector2(0.0, -24.0), "wall anchor perpendicular Y")
	assert_eq(line.get_point_position(1), Vector2(100.0, -24.0), "wall end at item")
	assert_eq(label.text, "2.50 m", "100px = 2.50 m")

	# Click near floor (y = 0) -> snaps Y axis and measures vertical meters
	tool.reset_measurement()
	assert_eq(tool.try_anchor_at(Vector2(80.0, -4.0)), true, "floor click anchors")
	assert_eq(tool.try_measure_item(item), true, "item measured from floor")
	assert_eq(line.get_point_position(0), Vector2(100.0, 0.0), "floor anchor perpendicular X")
	assert_eq(line.get_point_position(1), Vector2(100.0, -24.0), "floor end at item")
	assert_eq(label.text, "0.60 m", "24px = 0.60 m")

	world.queue_free()
	await process_frame
```

- [ ] **Step 2: Run test to verify it fails**

Run: `D:\Godot_v4.7.2-stable_win64\Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/test_measure_tool.gd`
Expected: FAIL (`set_room_context` / `try_anchor_at` / `try_measure_item` not declared).

- [ ] **Step 3: Implement `script/measure_tool.gd` and adjust `scene/measure_tool.tscn`**

- Remove `MAX_INTERACT_DISTANCE` completely.
- Add `@export var axis_snap_threshold: float = 14.0` and `@export var item_pick_radius: float = 18.0`.
- Implement `set_room_context(room: int, center_x: float, floor_y: float, pixels_per_meter: float) -> void`, `set_active(active: bool) -> void` (emitting `active_changed`), and `set_input_blocked(blocked: bool) -> void`.
- Implement `try_anchor_at(world_pos: Vector2) -> bool`:
  - Snap to `"wall"` if `abs(world_pos.x - center_x) <= axis_snap_threshold`; else snap to `"floor"` if `abs(world_pos.y - floor_y) <= axis_snap_threshold`; else emit `hint_requested("Klik tembok tengah atau lantai dulu")` and return `false`.
- Implement `try_measure_item(item: InteractiveItem) -> bool`:
  - Reject if `item == null` or item is not in `active_room`.
  - For `"wall"`: perpendicular line `(center_x, item.global_position.y) -> item.global_position`, readout `"%.2f m" % (abs(item.global_position.x - center_x) / pixels_per_meter)`.
  - For `"floor"`: perpendicular line `(item.global_position.x, floor_y) -> item.global_position`, readout `"%.2f m" % (abs(floor_y - item.global_position.y) / pixels_per_meter)`.
- Wire `_unhandled_input` (`measure` toggles `set_active`, left click anchors or picks closest `InteractiveItem` in `active_room` within `item_pick_radius` / physics point query, right click resets Step 1) and `_process` live preview while anchored and unlocked. Ensure `MeasureTool.z_index = 20` in `scene/measure_tool.tscn` so the line and label draw above furniture.

- [ ] **Step 4: Run test to verify it passes**

Run: `D:\Godot_v4.7.2-stable_win64\Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/test_measure_tool.gd`
Expected: Exit code `0`, `test_measure_tool: 9 passed, 0 failed`.

- [ ] **Step 5: Commit**

```bash
git add script/measure_tool.gd scene/measure_tool.tscn tests/test_measure_tool.gd
git commit -m "feat: snap MeasureTool to wall/floor axes and display meters"
```

---

### Task 4: `DoorPortal` Visual Prompt & Signal Interface

**Files:**
- Modify: `script/door_portal.gd:1-35`
- Modify: `scene/door_portal.tscn:1-13`
- Test: `tests/test_door_portal.gd`

**Interfaces:**
- Consumes: `CharacterBody2D` (`Player`) entering/exiting `Area2D`.
- Produces:
  - `signal portal_requested(from_room: int)`
  - `teleport_player_to(player: CharacterBody2D, target_room: int, spawn_x: float) -> void`
  - `update_prompt(current_room: int, entries_remaining: int) -> void`
  - `set_input_blocked(blocked: bool) -> void`

- [ ] **Step 1: Write the failing test `tests/test_door_portal.gd`**

```gdscript
extends SceneTree

var passed := 0
var failed := 0
var requested_from := -1

func _initialize() -> void:
	await run_tests()
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

func run_tests() -> void:
	await process_frame
	var portal: Area2D = load("res://scene/door_portal.tscn").instantiate()
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
	var prompt: Label = portal.get_node("PromptLabel")
	assert_eq(prompt.visible, true, "prompt visible when player near")
	assert_eq(prompt.text.contains("2"), true, "prompt shows remaining quota")

	portal.trigger_portal()
	assert_eq(requested_from, 1, "emits portal_requested from Room 1")

	portal.teleport_player_to(player, 2, 40.0)
	assert_eq(player.global_position.x, 40.0, "teleported to Room 2 x=40")
	assert_eq(cam.limit_left, 4, "camera limit_left updated")
	assert_eq(cam.limit_right, 204, "camera limit_right updated")

	portal.queue_free()
	player.queue_free()
	await process_frame
```

- [ ] **Step 2: Run test to verify it fails**

Run: `D:\Godot_v4.7.2-stable_win64\Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/test_door_portal.gd`
Expected: FAIL (`PromptLabel` / `portal_requested` / `teleport_player_to` not declared).

- [ ] **Step 3: Implement `scene/door_portal.tscn` and `script/door_portal.gd`**

- Add a subtle visual door `Polygon2D` (or `ColorRect` frame) and a centered `PromptLabel` (`Label`, hidden by default) to `scene/door_portal.tscn`.
- In `script/door_portal.gd`:
  - Emit `portal_requested(from_room: int)` from `trigger_portal()` when `player_near != null` and not `input_blocked` (called from `_unhandled_input` on `interact`).
  - Implement `teleport_player_to(player: CharacterBody2D, target_room: int, spawn_x: float) -> void` setting `player.global_position.x = spawn_x` and switching `Camera2D` limits (`-204..-4` for Room 1, `4..204` for Room 2).
  - Implement `update_prompt(current_room: int, entries_remaining: int) -> void` showing `[E] Ruang 2 (Sisa: %d)` in Room 1 (`Kuota Habis` when `0`) or `[E] Kembali Ruang 1` in Room 2, visible only while `player_near != null`.

- [ ] **Step 4: Run test to verify it passes**

Run: `D:\Godot_v4.7.2-stable_win64\Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/test_door_portal.gd`
Expected: Exit code `0`, `test_door_portal: 6 passed, 0 failed`.

- [ ] **Step 5: Commit**

```bash
git add scene/door_portal.tscn script/door_portal.gd tests/test_door_portal.gd
git commit -m "feat: add DoorPortal prompt UI and signal-based room transitions"
```

---

### Task 5: Reusable `HUD` (`scene/ui/hud.tscn` & `script/hud.gd`)

**Files:**
- Create: `scene/ui/hud.tscn`
- Create: `script/hud.gd`
- Test: `tests/test_hud.gd`

**Interfaces:**
- Consumes: nothing.
- Produces:
  - `signal ruler_toggled(active: bool)`
  - `signal phone_pressed`
  - `signal restart_pressed`
  - `signal notes_focus_changed(is_typing: bool)`
  - `update_status(room: int, entries_remaining: int, max_entries: int, time_remaining: float) -> void`
  - `set_ruler_active(active: bool) -> void`
  - `toggle_notes() -> void`
  - `show_result(result: Dictionary) -> void`
  - `show_toast(message: String) -> void`
  - `is_blocking_world_input() -> bool`

- [ ] **Step 1: Write the failing test `tests/test_hud.gd`**

```gdscript
extends SceneTree

var passed := 0
var failed := 0

func _initialize() -> void:
	await run_tests()
	print("test_hud: %d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)

func assert_eq(actual, expected, label: String) -> void:
	if actual == expected:
		passed += 1
	else:
		failed += 1
		push_error("FAIL %s: expected %s, got %s" % [label, expected, actual])

func run_tests() -> void:
	await process_frame
	var hud: CanvasLayer = load("res://scene/ui/hud.tscn").instantiate()
	root.add_child(hud)
	await process_frame

	hud.update_status(2, 2, 3, 4.5)
	assert_eq(hud.get_node("%RoomLabel").text, "Ruang 2 (Acuan)", "room label shows Room 2")
	assert_eq(hud.get_node("%QuotaLabel").text, "Kuota: 2/3", "quota label formatted")
	assert_eq(hud.get_node("%TimerLabel").visible, true, "timer visible in Room 2")
	assert_eq(hud.get_node("%TimerLabel").text.contains("4.5"), true, "timer shows 4.5s")

	assert_eq(hud.is_blocking_world_input(), false, "initially not blocking")
	hud.toggle_notes()
	assert_eq(hud.get_node("%NotesPanel").visible, true, "notes popup opened")
	assert_eq(hud.is_blocking_world_input(), true, "notes popup blocks world input")
	hud.toggle_notes()
	assert_eq(hud.get_node("%NotesPanel").visible, false, "notes popup closed")

	hud.show_result({
		"won": true,
		"matched_count": 2,
		"total_count": 2,
		"items": [
			{"item_id": "stool_01", "passed": true, "delta_m": 0.05, "delta_px": 2.0, "missing_in_room1": false}
		]
	})
	assert_eq(hud.get_node("%ResultPanel").visible, true, "result panel visible")
	assert_eq(hud.get_node("%ResultTitleLabel").text.contains("MENANG"), true, "win title shown")
	assert_eq(hud.is_blocking_world_input(), true, "result panel blocks world input")

	hud.queue_free()
	await process_frame
```

- [ ] **Step 2: Run test to verify it fails**

Run: `D:\Godot_v4.7.2-stable_win64\Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/test_hud.gd`
Expected: FAIL (cannot load `res://scene/ui/hud.tscn`).

- [ ] **Step 3: Create `scene/ui/hud.tscn` and `script/hud.gd`**

- Build `scene/ui/hud.tscn` (`CanvasLayer`, `layer = 10`) with clean `StyleBoxFlat` panels:
  - Top bar (`MarginContainer` -> `HBoxContainer`):
    - Left: `%RoomLabel`, `%QuotaLabel`, `%TimerLabel` (hidden when `room == 1`, turns warning red when `time_remaining <= 5.0`).
    - Right: `%RulerButton` (`toggle_mode = true`, `"Ruler [F]"`), `%NotesButton` (`"Notes [N]"`), `%PhoneButton` (`"Telepon Klien"`).
  - `%ToastLabel`: centered transient feedback label (`visible = false`, auto-hides via timer).
  - `%NotesPanel` (`PanelContainer`, `visible = false`): header `"Catatan Koordinat"`, `%CloseNotesButton`, and `%NotesTextEdit` (`TextEdit` with `placeholder_text = "Catat jarak tembok & lantai (meter)..."`).
  - `%ResultPanel` (`PanelContainer`, `visible = false`): `%ResultTitleLabel`, `%ResultDetailsLabel`, and `%RestartButton` (`"Ulangi Level"`).
- Implement `script/hud.gd`:
  - Connect button signals and `%NotesTextEdit` focus signals (`focus_entered` / `focus_exited`) + `_unhandled_input` for `notebook` (`N`, only when `not %NotesTextEdit.has_focus()`) and `ui_cancel` (`Escape`, closes Notes and releases focus).
  - Ensure `is_blocking_world_input()` returns `%NotesPanel.visible or %ResultPanel.visible or %NotesTextEdit.has_focus()`.
  - Ensure `RulerButton.focus_mode = Control.FOCUS_NONE`, `NotesButton.focus_mode = Control.FOCUS_NONE`, `PhoneButton.focus_mode = Control.FOCUS_NONE` so pressing `Space` to jump never accidentally re-clicks a HUD button!

- [ ] **Step 4: Run test to verify it passes**

Run: `D:\Godot_v4.7.2-stable_win64\Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/test_hud.gd`
Expected: Exit code `0`, `test_hud: 10 passed, 0 failed`.

- [ ] **Step 5: Commit**

```bash
git add scene/ui/hud.tscn script/hud.gd tests/test_hud.gd
git commit -m "feat: add reusable HUD with quota, timer, Notes popup, and result modal"
```

---

### Task 6: `LevelController`, `Player` Input Lock, & `Level01.tscn` Integration

**Files:**
- Modify: `script/player.gd:1-45`
- Create: `script/level_controller.gd`
- Modify: `scene/Level01.tscn:1-2135`
- Test: `tests/test_level01_integration.gd`

**Interfaces:**
- Consumes:
  - `DoorPortal` (`portal_requested`, `teleport_player_to`, `update_prompt`, `set_input_blocked`)
  - `MeasureTool` (`active_changed`, `hint_requested`, `set_active`, `set_room_context`, `set_input_blocked`, `reset_measurement`)
  - `InteractiveItem` (`interaction_blocked`, `cancel_drag`)
  - `SymmetryChecker` (`evaluate_symmetry`)
  - `HUD` (`ruler_toggled`, `phone_pressed`, `restart_pressed`, `notes_focus_changed`, `update_status`, `set_ruler_active`, `show_result`, `show_toast`, `is_blocking_world_input`)
- Produces:
  - `Player.input_locked: bool`
  - Complete wired `Level01.tscn` with 3 furniture pairs (`stool_01`, `bookcase_01`, `lamp_01`).

- [ ] **Step 1: Write the failing integration test `tests/test_level01_integration.gd`**

```gdscript
extends SceneTree

var passed := 0
var failed := 0

func _initialize() -> void:
	await run_tests()
	print("test_level01_integration: %d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)

func assert_eq(actual, expected, label: String) -> void:
	if actual == expected:
		passed += 1
	else:
		failed += 1
		push_error("FAIL %s: expected %s, got %s" % [label, expected, actual])

func run_tests() -> void:
	await process_frame
	var level: Node2D = load("res://scene/Level01.tscn").instantiate()
	root.add_child(level)
	await process_frame

	var hud := level.get_node("HUD")
	var player := level.get_node("Player")
	var measure_tool := level.get_node("MeasureTool")
	var portal := level.get_node("DoorPortal")

	# 1. Initial state
	assert_eq(level.current_room, 1, "starts in Room 1")
	assert_eq(level.entries_remaining, 3, "starts with 3 quota")

	# 2. Enter Room 2 consumes 1 quota & timer expiry force-returns to Room 1 + resets ruler
	level._on_portal_requested(1)
	assert_eq(level.current_room, 2, "entered Room 2")
	assert_eq(level.entries_remaining, 2, "quota decremented to 2")
	measure_tool.set_active(true)
	measure_tool.try_anchor_at(Vector2(2.0, -20.0))
	level.force_expire_room2_timer()
	assert_eq(level.current_room, 1, "timer expiry force-returned to Room 1")
	assert_eq(player.global_position.x, level.room1_spawn_x, "player moved back to Room 1")
	assert_eq(measure_tool.is_anchored, false, "ruler anchor cleared on force-return")

	# 3. Exhausting remaining 2 entries blocks 4th entry
	level._on_portal_requested(1)
	level._on_portal_requested(2)
	level._on_portal_requested(1)
	assert_eq(level.entries_remaining, 0, "quota now 0")
	level._on_portal_requested(2)
	assert_eq(level.current_room, 1, "back in Room 1 with 0 quota")
	level._on_portal_requested(1)
	assert_eq(level.current_room, 1, "4th entry blocked")
	assert_eq(level.entries_remaining, 0, "quota stays 0")

	# 4. Notes focus locks player & items; Ruler active blocks item drag
	hud.toggle_notes()
	level._refresh_input_locks()
	assert_eq(player.input_locked, true, "notes locks player movement")
	hud.toggle_notes()
	level._refresh_input_locks()
	assert_eq(player.input_locked, false, "closing notes unlocks player")

	var r1_stool := level.get_node("Stool")
	measure_tool.set_active(true)
	assert_eq(r1_stool.interaction_blocked, true, "active ruler blocks item drag")
	measure_tool.set_active(false)
	assert_eq(r1_stool.interaction_blocked, false, "inactive ruler allows item drag")

	# 5. Phone check initially loses (items messy), then wins when all mirrored
	level._on_phone_pressed()
	assert_eq(hud.get_node("%ResultPanel").visible, true, "phone opens result")
	assert_eq(hud.get_node("%ResultTitleLabel").text.contains("KALAH"), true, "messy room loses")

	# Mirror all Room 1 items to Room 2 reference positions and verify WIN
	for item in level.get_children():
		if item is InteractiveItem and item.home_room == 1:
			for ref in level.get_children():
				if ref is InteractiveItem and ref.home_room == 2 and ref.item_id == item.item_id:
					item.global_position = Vector2(-ref.initial_position.x, ref.initial_position.y)
	level.is_level_ended = false
	level._on_phone_pressed()
	assert_eq(hud.get_node("%ResultTitleLabel").text.contains("MENANG"), true, "mirrored room wins")

	level.queue_free()
	await process_frame
```

- [ ] **Step 2: Run test to verify it fails**

Run: `D:\Godot_v4.7.2-stable_win64\Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/test_level01_integration.gd`
Expected: FAIL (`current_room` / `entries_remaining` / `input_locked` not found).

- [ ] **Step 3: Update `script/player.gd`, create `script/level_controller.gd`, and update `scene/Level01.tscn`**

- In `script/player.gd`: add `var input_locked: bool = false`. When `input_locked` is `true`, skip jump and horizontal input, set `velocity.x = move_toward(velocity.x, 0, speed)`, keep gravity + `move_and_slide()` + `update_animation(0.0)`.
- Create `script/level_controller.gd` (`extends Node2D`):
  - Exports: `max_room2_entries: int = 3`, `room2_time_limit: float = 15.0`, `center_x: float = 0.0`, `floor_y: float = 0.0`, `pixels_per_meter: float = 40.0`, `room1_spawn_x: float = -40.0`, `room2_spawn_x: float = 40.0`.
  - Connects `DoorPortal`, `MeasureTool`, `HUD`, and `SymmetryChecker` in `_ready()`.
  - Implements `_process(delta)` countdown when `current_room == 2` and calls `force_expire_room2_timer() -> void` when `time_remaining <= 0.0` (returns player to Room 1, resets `MeasureTool`, cancels item drags, refreshes HUD/DoorPortal).
  - Implements `_on_portal_requested(from_room: int)`, `_refresh_input_locks()`, `_on_phone_pressed()`, and `_on_restart_pressed()`.
- Update `scene/Level01.tscn`:
  - Attach `script/level_controller.gd` to root `Level01`.
  - Instance `res://scene/ui/hud.tscn` as `HUD`.
  - Ensure `Stool` (`item_id = "stool_01"`) and `Stool_Room2` (`item_id = "stool_01"`) exist, and add 2 more furniture pairs using existing textures in `asset/tileseet/CartoonRooms/separate images/`:
    - `Bookcase` (`item_id = "bookcase_01"`, `bookcase_small_1.png`, Room 1 messy position vs `Bookcase_Room2` reference position).
    - `Lamp` (`item_id = "lamp_01"`, `lamp_big.png`, Room 1 messy position vs `Lamp_Room2` reference position).
  - Verify `floor_rest_offset` and `CollisionShape2D` positions match each sprite's bottom edge so all furniture rests cleanly on `floor_y = 0.0`.

- [ ] **Step 4: Run all tests and headless Level01 smoke check**

Run:
1. `D:\Godot_v4.7.2-stable_win64\Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/test_symmetry_checker.gd`
2. `D:\Godot_v4.7.2-stable_win64\Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/test_interactive_item.gd`
3. `D:\Godot_v4.7.2-stable_win64\Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/test_measure_tool.gd`
4. `D:\Godot_v4.7.2-stable_win64\Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/test_door_portal.gd`
5. `D:\Godot_v4.7.2-stable_win64\Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/test_hud.gd`
6. `D:\Godot_v4.7.2-stable_win64\Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/test_level01_integration.gd`
7. `D:\Godot_v4.7.2-stable_win64\Godot_v4.7.2-stable_win64_console.exe --headless --path . --quit-after 300 res://scene/Level01.tscn`

Expected: All 6 test scripts exit with code `0` (`0 failed`), and the 300-frame `Level01.tscn` smoke run produces zero `SCRIPT ERROR` or `ERROR:` lines.

- [ ] **Step 5: Commit**

```bash
git add script/player.gd script/level_controller.gd scene/Level01.tscn tests/test_level01_integration.gd
git commit -m "feat: wire LevelController, HUD, and Level01 furniture loop"
```
