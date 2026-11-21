# Measure For Symmetry — Design Document

**Date:** 2026-11-21  
**Engine:** Godot 4.7.2 (GL Compatibility, 2D)  
**Scope:** Complete playable core loop for Level 01 with reusable modular scenes/scripts for future levels.

---

## 1. Intent & Why

Build a 2D side-scroller spatial puzzle game (*Measure For Symmetry*) where the player acts as an interior arranger tasked with mirroring a reference room (**Ruang 2**) inside a messy room (**Ruang 1**) across a central dividing wall. Because the player cannot see both rooms at once and has limited visits and time in the reference room, success depends on **measuring**, **note-taking**, and **accurate placement**.

---

## 2. Goals, Non-Goals, and Anti-Goals

### Goals
- Complete the core gameplay loop end-to-end in `Level01.tscn`:
  1. Move left/right (`A`/`D`) and jump (`Space`/`W`) with gravity in Ruang 1 and Ruang 2.
  2. Enter Ruang 2 via `DoorPortal` with a **3-entry quota** and a **countdown timer**; when the timer expires, automatically force-return the player to Ruang 1 (consuming that entry).
  3. Measure object distances using the **Ruler** (`MeasureTool`): click wall or floor → click an object → display a `Line2D` and distance in **meters**.
  4. Open/close **Notes** from the HUD (or `N`) to record coordinates in a `TextEdit` popup without triggering player movement keys while typing.
  5. Return to Ruang 1 and **drag-and-drop** messy items to their symmetric mirror positions across the central dividing wall (`center_x`) relative to the floor (`floor_y`).
  6. Click **Telepon Klien** in the HUD to run `SymmetryChecker` against tolerance and display a **Menang / Kalah** result screen with per-item feedback and a Restart button.
- Keep the architecture modular (`HUD.tscn` + `LevelController` + signal-driven components) so future levels (`Level02`, `Level03`, ...) can reuse the same prefabs.

### Non-Goals
- Main menu, level select screen, save/load system, or audio/BGM integration (can be layered on later).
- Multiple levels (`Level02+`) in this initial implementation; only `Level01` is populated and verified playable.
- Automatic/smart placement snapping that solves the puzzle for the player.

### Anti-Goals
- **Moving reference items:** Players must not be able to drag items in Ruang 2, which would corrupt the reference positions.
- **Input conflict during note-taking:** Typing `A`, `D`, `W`, `E`, `F`, or `N` inside the Notes `TextEdit` must not move the character, toggle the ruler, or close the popup unexpectedly.
- **Tool conflict between Ruler and Drag:** Clicking an item while Ruler mode is active must measure the item rather than drag it.
- **Global state leaks on restart:** Restarting the level must cleanly reset quota (`3`), timer, item positions, and UI state.

---

## 3. Existing Project Constraints

- **Viewport & Pixel Art:** `1280x480`, `canvas_items` stretch with `expand` aspect, `default_texture_filter=0` (nearest-neighbor). Camera uses `zoom = Vector2(6.5, 6.5)` with `position_smoothing_enabled = true`.
- **Coordinate System (`Level01.tscn`):**
  - Central dividing wall (`CenterWall`): `x = 0.0` (width `10`, spanning `x = -5..5`).
  - Floor surface: `y = 0.0` (`FloorCollision` is centered at `y = 10` with height `20`).
  - Ruang 1 (left): `x ∈ [-200, 0]`, camera limits `limit_left = -204`, `limit_right = -4`.
  - Ruang 2 (right): `x ∈ [0, 200]`, camera limits `limit_left = 4`, `limit_right = 204`.
  - `DoorPortal` sits at `(0, 0)` with a `40x70` trigger area (`x ∈ [-20, 20]`).
- **Existing Scripts:** `player.gd`, `door_portal.gd`, `interactive_item.gd`, `measure_tool.gd`, `symmetry_checker.gd`, and `mirror_room.gd` (editor script).

---

## 4. Approaches Considered

1. **Modular per-Level + Reusable `HUD.tscn` *(Selected)***
   - A `LevelController` script on the level root coordinates `DoorPortal`, `MeasureTool`, `SymmetryChecker`, and a standalone `HUD.tscn` via signals.
   - *Trade-off:* Adds `HUD.tscn`, `hud.gd`, and `level_controller.gd`, keeping each responsibility isolated and preventing global singleton state bugs on restart while making future levels trivial to assemble.
2. **Global `GameManager.gd` Autoload** *(Rejected)*
   - Centralizes quota, timer, and notes in an autoload singleton.
   - *Trade-off:* Risks stale state across scene reloads/restarts and couples level scenes to a global singleton, contrary to removing the unused `GameManager` autoload earlier.
3. **Monolithic `Level01.tscn` Script** *(Rejected)*
   - Places all HUD nodes and game loop logic directly inside `Level01.tscn`.
   - *Trade-off:* Fast for a single prototype, but requires duplicating UI and logic for every new level.

---

## 5. System Architecture & Component Design

```
Level01 (Node2D + level_controller.gd)
├── TileMapLayer
├── RoomBoundaries (StaticBody2D: FloorCollision, LeftWall, RightWall, CenterWall, Ceiling)
├── DoorPortal (Area2D + door_portal.gd + PromptLabel)
├── Items (Node2D container)
│   ├── Ruang 1 InteractiveItems (draggable)
│   └── Ruang 2 InteractiveItems (locked reference)
├── Player (CharacterBody2D + Camera2D)
├── MeasureTool (Node2D + measure_tool.gd)
├── SymmetryChecker (Node + symmetry_checker.gd)
└── HUD (CanvasLayer instance of scene/ui/hud.tscn)
```

### 5.1 `LevelController` (`script/level_controller.gd`)
- **Exports:**
  - `max_room2_entries: int = 3`
  - `room2_time_limit: float = 15.0`
  - `center_x: float = 0.0`
  - `floor_y: float = 0.0`
  - `pixels_per_meter: float = 40.0` (200 px room width = `5.00 m`)
  - `room1_spawn_x: float = -40.0`
  - `room2_spawn_x: float = 40.0`
- **State:**
  - `entries_remaining: int` (starts at `max_room2_entries`)
  - `current_room: int` (`1` or `2`, starts at `1`)
  - `time_remaining: float`
  - `is_level_ended: bool`
- **Behavior:**
  - Listens to `DoorPortal.portal_requested`:
    - From Room 1 → Room 2: allowed only if `entries_remaining > 0` and not `is_level_ended`. Decrements `entries_remaining`, teleports player to Room 2, updates camera limits, sets `time_remaining = room2_time_limit`, starts countdown. If `entries_remaining == 0`, shows brief HUD feedback ("Kuota masuk Ruang 2 habis!").
    - From Room 2 → Room 1: teleports player back to Room 1, updates camera limits, stops countdown.
  - During `current_room == 2`: decrements `time_remaining` every frame and updates HUD timer. When `time_remaining <= 0`, **automatically force-returns player to Room 1** (Option A), cancels any active ruler measurement, and updates HUD.
  - On room transition: cancels any active `MeasureTool` anchor/measurement and stops any active item drag.
  - Listens to `HUD.ruler_toggled`, `HUD.phone_pressed`, and `HUD.restart_pressed`.
  - On `phone_pressed`: calls `SymmetryChecker.evaluate_symmetry(center_x, pixels_per_meter)`, sets `is_level_ended = true`, disables player/tool input, and displays the Win/Lose result in `HUD`.

### 5.2 `DoorPortal` (`scene/door_portal.tscn` & `script/door_portal.gd`)
- Adds a subtle visual door sprite/marker and an in-world `Label` prompt (`[E] Ke Ruang 2` when player is on the left, `[E] Kembali ke Ruang 1` when on the right; shows `Kuota Habis` if in Room 1 with `0` entries left).
- Emits `portal_requested(from_room: int)` on `interact` (`E`) when `player_near` is valid and `LevelController` allows input.
- `LevelController` executes the teleport and camera limit switch via a helper on `DoorPortal` (or `LevelController`).

### 5.3 `MeasureTool` (`scene/measure_tool.tscn` & `script/measure_tool.gd`)
- **Activation & Reach:** Toggled via HUD **Ruler** button or `measure` key (`F`). Emits `active_changed(is_active: bool)` so the HUD button stays visually synced, and disables `InteractiveItem` dragging while active. Measurement clicks work **anywhere within the currently active room** (no `35 px` player proximity check — `MAX_INTERACT_DISTANCE` is removed for the ruler so players can measure wall/floor-to-item across the `200 px` room under the `15 s` timer, while `InteractiveItem` keeps `MAX_DISTANCE` for physical dragging).
- **Measurement Flow (Wall/Floor → Item):**
  1. **Step 1 — Click Wall or Floor (Anchor):**
     - Left-clicking near the central dividing wall (`abs(mouse.x - center_x) <= axis_snap_threshold` while `mouse.y` is within room height) snaps the reference axis to **Wall (`X` axis measurement)** at `(center_x, mouse.y)`.
     - Left-clicking near the floor (`abs(mouse.y - floor_y) <= axis_snap_threshold`) snaps the reference axis to **Floor (`Y` axis measurement)** at `(mouse.x, floor_y)`.
     - If the player clicks elsewhere (neither wall nor floor within snap threshold), display a brief status hint (e.g. "Klik tembok tengah atau lantai dulu").
  2. **Step 2 — Click Target Object:**
     - Left-clicking an `InteractiveItem` in the current room locks the `Line2D` cleanly perpendicular to the chosen reference axis:
       - **Wall reference:** line from `(center_x, item.global_position.y)` to `item.global_position`. Distance = `abs(item.global_position.x - center_x) / pixels_per_meter`.
       - **Floor reference:** line from `(item.global_position.x, floor_y)` to `item.global_position`. Distance = `abs(floor_y - item.global_position.y) / pixels_per_meter`.
     - While moving the mouse between Step 1 and Step 2, preview a dashed/live `Line2D` perpendicular from the snapped axis to the cursor/hovered item with live meter readout (`%.2f m`).
  3. **Reset / Cancel:** Right-clicking resets the current measurement back to Step 1 (ready for a new wall/floor click). Toggling the Ruler off clears the line and label.
- **Distance Units:** Converted to meters using `pixels_per_meter` (`40.0 px = 1.00 m`, formatted as `%.2f m`).

### 5.4 `InteractiveItem` (`script/interactive_item.gd`)
- **Exports:** `item_id: String`, `floor_rest_offset: float = 12.0` (so items of different heights rest cleanly on `floor_y = 0` without hardcoding `-12.0` for all furniture).
- **Room 2 Locking:** Items with `home_room == 2` are **locked** (`is_locked_reference = true`) and ignore drag input.
- **Room 1 Dragging:**
  - Only allowed when player is in Room 1, within `MAX_DISTANCE`, and `MeasureTool` is **inactive** (and no modal UI like Notes or Result is blocking).
  - Supports lifting/moving within Room 1 bounds (`x ∈ [-193, -11]`, `y ∈ [-85, floor_y - floor_rest_offset]`) and drops smoothly to `floor_y - floor_rest_offset` (or stacks onto an item beneath it) on release.

### 5.5 `SymmetryChecker` (`script/symmetry_checker.gd`)
- Matches all `InteractiveItem` nodes by `item_id` between Room 2 (reference `initial_position`) and Room 1 (`global_position`).
- Expected mirrored position:
  - `target_x = 2.0 * center_x - ref_pos.x`
  - `target_y = ref_pos.y`
- Computes `delta_x`, `delta_y`, and `delta_total` (in pixels and meters) against `TOLERANSI` (`6.0 px`, i.e. `0.15 m`).
- Returns a structured `Dictionary`:
  ```gdscript
  {
      "won": bool,
      "matched_count": int,
      "total_count": int,
      "items": [ { "item_id": String, "passed": bool, "delta_m": float, "delta_px": float } ]
  }
  ```
- Keeps `ui_accept` debug print only if invoked manually or removed in favor of the Phone Check button to avoid accidental triggers while typing.

### 5.6 `HUD` (`scene/ui/hud.tscn` & `script/hud.gd`)
- `CanvasLayer` (`layer = 10`) scaled cleanly for `1280x480` viewport:
  - **Top-Left Status:** Current Room badge (`Ruang 1` / `Ruang 2`), Entry Quota badge (`Kuota Ruang 2: 3 / 3`), Countdown Timer label (highlighted/warning color when `<= 5s` in Ruang 2).
  - **Top-Right Toolbar:**
    - **Ruler Button (`[F]`)**: Toggleable button showing active state.
    - **Notes Button (`[N]`)**: Opens/closes the Notes popup.
    - **Telepon Klien Button**: Triggers symmetry check (enabled in Ruang 1, or warns if still in Ruang 2 / triggers check after confirming).
  - **Notes Popup (`PanelContainer` + `TextEdit`):**
    - Floating/draggable or anchored panel with a `TextEdit` (placeholder: `"Catat jarak dari tembok & lantai..."`) and a close button (`X`).
    - When `TextEdit` has focus, game movement/shortcut actions (`A`, `D`, `W`, `E`, `F`, `N`, `Space`) are suppressed so the player can type freely (note: clicking `X` or pressing `Escape` closes/unfocuses Notes).
  - **Result Modal (`PanelContainer`):**
    - Displays **MENANG!** or **KALAH!** header, per-item accuracy breakdown in meters (`stool_01: 0.05 m ✓` / `bookcase_01: 0.42 m ✗`), and an **Ulangi Level** button (`get_tree().reload_current_scene()`).

### 5.7 `Level01.tscn` Content
- Keep the existing `TileMapLayer` symmetrical room layout, `RoomBoundaries`, `DoorPortal`, and `Player`.
- Populate **2–3 furniture pairs** using existing sprites in `asset/tileseet/CartoonRooms/separate images/` (e.g., `chair_front.png` as `stool_01`, `bookcase_small_1.png` or `table_small_1.png` as `table_01`, `lamp_big.png` as `lamp_01`).
- Place Ruang 2 items at deliberate target coordinates (some on the floor, optionally one stacked or positioned at specific meter distances) and place Ruang 1 items in messy starting positions.

---

## 6. What's Left to the Builder

- Exact pixel coordinates, collision sizes, and `floor_rest_offset` values for each furniture item in `Level01.tscn`.
- Visual polish (choosing matching sprites from `asset/UI/Sprites/` vs crisp `StyleBoxFlat` styling, colors, and tween feedback on HUD buttons/timer).
- Exact `axis_snap_threshold` (e.g. `12–16 px` in world space at `6.5x` camera zoom) and `room2_time_limit` playtest tuning.

---

## 7. Multi-Room / 4-Room Level Extension Blueprint (`Level02+`)

To scale into 4-room (2-floor) or multi-door levels where Ruang 3 & Ruang 4 sit below Ruang 1 & Ruang 2 (Ruang 3 mirrors Ruang 4 across `center_x`, reached via extra doors):
- **`InteractiveItem`:** Set `room_id` (`1`, `2`, `3`, `4`), `floor_y` (e.g. `0.0` for top floor, `120.0` for bottom floor), `room_x_min` / `room_x_max`, and `room_y_min`. Even-numbered rooms (`2`, `4`) auto-lock as reference rooms (`is_locked_reference = true`).
- **`SymmetryChecker`:** Add `Vector2i(3, 4)` to `room_pairs` (`[Vector2i(1, 2), Vector2i(3, 4)]`) so one evaluation checks both floors across `center_x`.
- **`DoorPortal`:** Add additional `DoorPortal` instances (e.g. a wall door in Ruang 1/2 leading down to Ruang 3/4) routed through `LevelController` room limits and `floor_y` context.

