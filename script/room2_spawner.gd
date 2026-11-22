class_name Room2Spawner
extends Node2D

## Grounded & stack-aware procedural spawner for Room 2 objects.
## Places every object flush on the floor or squarely stacked atop supporting
## furniture using Rejection Sampling (up to max_attempts) with a deterministic
## Jittered Floor + Stack Grid fallback so objects never float or freeze.

signal objects_spawned(level: int, count: int, used_fallback: bool)

@export var object_scene: PackedScene = preload("res://scene/props/interactive_item.tscn")
@export var room_rect: Rect2 = Rect2(5.0, -96.0, 195.0, 96.0)
@export var object_size: Vector2 = Vector2(16.0, 18.0)
@export_range(0.0, 100.0, 0.5) var wall_padding: float = 6.0
@export_range(0.0, 100.0, 0.5) var min_gap: float = 4.0
@export_range(1, 500, 1) var max_attempts: int = 50
@export var player_spawn_position: Vector2 = Vector2(40.0, -16.0)
@export_range(0.0, 200.0, 1.0) var player_exclusion_radius: float = 24.0
@export_range(0.0, 1.0, 0.05) var stack_probability: float = 0.4
@export_range(1, 5, 1) var max_stack_tiers: int = 3
@export var auto_spawn_on_ready: bool = true
@export var level_override: int = 0
@export var hold_spawned_position_until_drag: bool = false
@export var sync_room1_references: bool = false

var last_spawn_used_fallback: bool = false
var last_spawn_positions: Array[Vector2] = []
var last_spawn_records: Array[Dictionary] = []

var _spawned_room2_nodes: Array[Node2D] = []
var _spawned_room1_nodes: Array[Node2D] = []
var _manual_room1_items: Array[InteractiveItem] = []
var _manual_room1_captured: bool = false


func _ready() -> void:
	_capture_manual_room1_items()
	if auto_spawn_on_ready:
		respawn_current_level()


## Returns the active level index from level_override or GameManager.current_level.
func get_active_level() -> int:
	if level_override > 0:
		return level_override
	var gm: Node = get_node_or_null("/root/GameManager")
	if gm:
		var gm_level: Variant = gm.get("current_level")
		if gm_level != null:
			return maxi(1, int(gm_level))
	return 1


## Computes the Safe Spawn Area by inseting room_rect with half object_size + wall_padding.
func get_safe_spawn_rect() -> Rect2:
	var half_size: Vector2 = object_size * 0.5
	var min_x: float = room_rect.position.x + half_size.x + wall_padding
	var min_y: float = room_rect.position.y + half_size.y + wall_padding
	var max_x: float = room_rect.end.x - half_size.x - wall_padding
	var max_y: float = room_rect.end.y - half_size.y

	if min_x > max_x:
		var center_x: float = room_rect.get_center().x
		min_x = center_x
		max_x = center_x
		push_warning("Room2Spawner: Horizontal Safe Spawn Area collapsed (room width too small for object_size + wall_padding).")

	if min_y > max_y:
		min_y = max_y
		push_warning("Room2Spawner: Vertical Safe Spawn Area collapsed (room height too small for object_size + wall_padding).")

	return Rect2(Vector2(min_x, min_y), Vector2(max_x - min_x, max_y - min_y))


## Frees all previously spawned objects cleanly to prevent ghost or duplicate nodes.
func clear_spawned_objects() -> void:
	for node in _spawned_room2_nodes:
		if is_instance_valid(node):
			if node.get_parent():
				node.get_parent().remove_child(node)
			node.queue_free()
	_spawned_room2_nodes.clear()

	for child in get_children():
		if is_instance_valid(child) and (child.has_meta("spawned_by_room2_spawner") or child is InteractiveItem):
			remove_child(child)
			child.queue_free()

	for r1_node in _spawned_room1_nodes:
		if is_instance_valid(r1_node):
			if r1_node.get_parent():
				r1_node.get_parent().remove_child(r1_node)
			r1_node.queue_free()
	_spawned_room1_nodes.clear()


## Respawns objects for the active level using configured player_spawn_position.
func respawn_current_level() -> Array[Node2D]:
	return spawn_level_objects(get_active_level(), player_spawn_position)


## Clears old objects and spawns 1 + level * (level - 1) / 2 grounded/stacked objects in Room 2.
func spawn_level_objects(level: int, player_spawn: Vector2 = player_spawn_position) -> Array[Node2D]:
	clear_spawned_objects()
	last_spawn_used_fallback = false
	last_spawn_positions.clear()
	last_spawn_records.clear()

	if not object_scene:
		push_error("Room2Spawner: object_scene is not assigned.")
		return []

	var target_level: int = maxi(1, level)
	var total_objects: int = LevelProgression.get_total_objects(target_level)
	var exclusion_radius: float = _get_effective_exclusion_radius()

	var descriptors: Array[Dictionary] = _prepare_prop_descriptors(total_objects)
	var ordered_metrics: Array[Dictionary] = _order_descriptors_for_stacking(descriptors)
	var placed_records: Array[Dictionary] = _compute_grounded_placements(
		ordered_metrics,
		player_spawn,
		exclusion_radius
	)

	# Spawn floor items before stacked items so InteractiveItem._ready() finds supports immediately.
	for record in placed_records:
		var world_pos: Vector2 = record["pos"]
		var obj_instance := object_scene.instantiate() as Node2D
		if not obj_instance:
			push_error("Room2Spawner: object_scene root must inherit Node2D.")
			continue

		obj_instance.position = to_local(world_pos) if is_inside_tree() else world_pos
		obj_instance.set_meta("spawned_by_room2_spawner", true)

		if obj_instance is InteractiveItem:
			var item := obj_instance as InteractiveItem
			var desc: Dictionary = record["desc"]
			item.override_home_room = 2
			item.hold_until_dragged = hold_spawned_position_until_drag

			var tex := desc.get("texture", null) as Texture2D
			var sc: Vector2 = desc.get("sprite_scale", LevelProgression.DEFAULT_PROP_SCALE)
			var sz: Vector2 = desc.get("shape_size", Vector2(14.0, 4.0))
			var off: Vector2 = desc.get("shape_offset", Vector2.ZERO)
			var id_str: String = desc.get("item_id", "prop")
			var support_flag: bool = bool(desc.get("can_support_stack", true))
			item.configure_prop(id_str, tex, sc, sz, off, support_flag)

		add_child(obj_instance)
		_spawned_room2_nodes.append(obj_instance)
		last_spawn_positions.append(world_pos)
		last_spawn_records.append(record)

	objects_spawned.emit(target_level, _spawned_room2_nodes.size(), last_spawn_used_fallback)
	return _spawned_room2_nodes.duplicate()


func _get_effective_exclusion_radius() -> float:
	if player_exclusion_radius > 0.0:
		return player_exclusion_radius
	var fallback_min_dist: float = maxf(object_size.x, object_size.y) + min_gap
	return maxf(24.0, fallback_min_dist * 1.25)


func _build_prop_metrics(desc: Dictionary) -> Dictionary:
	var tex := desc.get("texture", null) as Texture2D
	var sprite_scale: Vector2 = desc.get("sprite_scale", LevelProgression.DEFAULT_PROP_SCALE)
	var sprite_offset: Vector2 = desc.get("sprite_offset", Vector2.ZERO)
	var shape_size: Vector2 = desc.get("shape_size", object_size)
	var shape_offset: Vector2 = desc.get("shape_offset", Vector2.ZERO)
	var can_support: bool = bool(desc.get("can_support_stack", true))

	var visual_w: float = float(tex.get_width()) * absf(sprite_scale.x) if tex else object_size.x
	var visual_h: float = float(tex.get_height()) * absf(sprite_scale.y) if tex else object_size.y

	var half_w: float = maxf(visual_w, shape_size.x) * 0.5
	var visual_bottom: float = (visual_h * 0.5) + sprite_offset.y
	var visual_top: float = -(visual_h * 0.5) + sprite_offset.y
	var surface_top_offset: float = shape_offset.y - (shape_size.y * 0.5)
	var surface_half_w: float = shape_size.x * 0.5
	var surface_offset_x: float = shape_offset.x

	# Flat surfaces near sprite top (tables, dressers, nightstands, bookcases) never embed stacked items.
	var has_clear_flat_top: bool = absf(surface_top_offset - visual_top) <= 3.0
	var support_priority: int = 0
	if can_support and surface_half_w >= 5.0 and has_clear_flat_top:
		if shape_size.x >= 16.0 and shape_size.y >= 8.0:
			support_priority = 2
		else:
			support_priority = 1

	return {
		"desc": desc,
		"item_id": str(desc.get("item_id", "")),
		"visual_w": visual_w,
		"visual_h": visual_h,
		"half_w": half_w,
		"visual_bottom": visual_bottom,
		"visual_top": visual_top,
		"surface_top_offset": surface_top_offset,
		"surface_half_w": surface_half_w,
		"surface_offset_x": surface_offset_x,
		"can_support_stack": can_support and support_priority > 0,
		"support_priority": support_priority,
	}


func _order_descriptors_for_stacking(descriptors: Array[Dictionary]) -> Array[Dictionary]:
	var wide_bases: Array[Dictionary] = []
	var prime_bases: Array[Dictionary] = []
	var secondary_bases: Array[Dictionary] = []
	var top_only: Array[Dictionary] = []

	for desc in descriptors:
		var metrics: Dictionary = _build_prop_metrics(desc)
		var prio: int = int(metrics["support_priority"])
		var half_w: float = float(metrics["half_w"])
		if prio >= 2 and half_w > 15.0:
			wide_bases.append(metrics)
		elif prio >= 2:
			prime_bases.append(metrics)
		elif prio == 1:
			secondary_bases.append(metrics)
		else:
			top_only.append(metrics)

	wide_bases.shuffle()
	prime_bases.shuffle()
	secondary_bases.shuffle()
	top_only.shuffle()

	var ordered: Array[Dictionary] = []
	ordered.append_array(wide_bases)
	ordered.append_array(prime_bases)
	ordered.append_array(secondary_bases)
	ordered.append_array(top_only)
	return ordered


func _make_placed_record(pos: Vector2, metrics: Dictionary, support_index: int, tier: int) -> Dictionary:
	var half_w: float = float(metrics["half_w"])
	var visual_top: float = float(metrics["visual_top"])
	var visual_bottom: float = float(metrics["visual_bottom"])
	var surface_top_offset: float = float(metrics["surface_top_offset"])
	var surface_offset_x: float = float(metrics["surface_offset_x"])
	return {
		"pos": pos,
		"desc": metrics["desc"],
		"item_id": metrics["item_id"],
		"metrics": metrics,
		"support_index": support_index,
		"tier": tier,
		"half_w": half_w,
		"left": pos.x - half_w,
		"right": pos.x + half_w,
		"top": pos.y + visual_top,
		"bottom": pos.y + visual_bottom,
		"visual_top": visual_top,
		"visual_bottom": visual_bottom,
		"surface_y": pos.y + surface_top_offset,
		"surface_center_x": pos.x + surface_offset_x,
		"surface_half_w": float(metrics["surface_half_w"]),
		"can_support_stack": bool(metrics["can_support_stack"]),
		"support_priority": int(metrics["support_priority"]),
	}


func _compute_grounded_placements(
	ordered_metrics: Array[Dictionary],
	player_spawn: Vector2,
	exclusion_radius: float
) -> Array[Dictionary]:
	var placed: Array[Dictionary] = []
	var needs_full_fallback: bool = false
	var attempts_limit: int = maxi(1, max_attempts)
	var floor_y: float = room_rect.end.y

	for metrics in ordered_metrics:
		var half_w: float = float(metrics["half_w"])
		var visual_bottom: float = float(metrics["visual_bottom"])
		var safe_min_x: float = room_rect.position.x + wall_padding + half_w
		var safe_max_x: float = room_rect.end.x - wall_padding - half_w
		if safe_min_x > safe_max_x:
			var cx: float = room_rect.get_center().x
			safe_min_x = cx
			safe_max_x = cx

		var eligible_supports: Array[int] = _get_eligible_support_indices(metrics, placed)
		var found: bool = false
		var chosen_record: Dictionary = {}
		var my_prio: int = int(metrics["support_priority"])

		for attempt in range(attempts_limit):
			var stack_chance: float = 0.0 if half_w > 15.0 else (stack_probability * 0.35 if my_prio >= 2 else stack_probability)
			var try_stack: bool = (not eligible_supports.is_empty()) and (
				attempt >= attempts_limit / 2 or randf() < stack_chance
			)

			if try_stack:
				var sup_idx: int = eligible_supports[randi() % eligible_supports.size()]
				var sup: Dictionary = placed[sup_idx]
				var max_dx: float = _get_stack_offset_limit(metrics, sup)
				var cand_dx: float = randf_range(-max_dx, max_dx)
				if float(sup["surface_half_w"]) >= 14.0 and half_w <= 10.0 and randf() < 0.6:
					cand_dx = (-max_dx * randf_range(0.75, 1.0)) if randf() < 0.5 else (max_dx * randf_range(0.75, 1.0))
				var cand_x: float = float(sup["surface_center_x"]) + cand_dx
				cand_x = clampf(cand_x, safe_min_x, safe_max_x)
				var cand_y: float = float(sup["surface_y"]) - visual_bottom
				var cand_pos := Vector2(cand_x, cand_y)
				if _is_valid_grounded_placement(cand_pos, metrics, sup_idx, placed, player_spawn, exclusion_radius):
					chosen_record = _make_placed_record(cand_pos, metrics, sup_idx, int(sup["tier"]) + 1)
					found = true
					break
			else:
				var cand_x: float = randf_range(safe_min_x, safe_max_x)
				var cand_y: float = floor_y - visual_bottom
				var cand_pos := Vector2(cand_x, cand_y)
				if _is_valid_grounded_placement(cand_pos, metrics, -1, placed, player_spawn, exclusion_radius):
					chosen_record = _make_placed_record(cand_pos, metrics, -1, 0)
					found = true
					break

		if found:
			placed.append(chosen_record)
		else:
			last_spawn_used_fallback = true
			var inc_result: Dictionary = _pick_incremental_jittered_slot(
				metrics,
				placed,
				player_spawn,
				exclusion_radius
			)
			if bool(inc_result.get("found", false)):
				placed.append(inc_result["record"])
			else:
				needs_full_fallback = true
				break

	if needs_full_fallback:
		last_spawn_used_fallback = true
		placed = _generate_jittered_floor_and_stack_fallback(
			ordered_metrics,
			player_spawn,
			exclusion_radius
		)

	return placed


func _get_stack_offset_limit(metrics: Dictionary, support_record: Dictionary) -> float:
	var half_w: float = float(metrics["half_w"])
	var sup_half_w: float = float(support_record["surface_half_w"])
	return maxf(0.0, sup_half_w - half_w * 0.5)


func _get_eligible_support_indices(metrics: Dictionary, placed: Array[Dictionary]) -> Array[int]:
	var prio2: Array[int] = []
	var prio1: Array[int] = []
	var my_half_w: float = float(metrics["half_w"])

	for idx in range(placed.size()):
		var sup: Dictionary = placed[idx]
		if not bool(sup["can_support_stack"]):
			continue
		if int(sup["tier"]) + 1 >= max_stack_tiers:
			continue
		var sup_half_w: float = float(sup["surface_half_w"])
		if my_half_w > sup_half_w + 3.0:
			continue
		if int(sup["support_priority"]) >= 2:
			prio2.append(idx)
		else:
			prio1.append(idx)

	return prio2 if not prio2.is_empty() else prio1


func _is_valid_grounded_placement(
	cand_pos: Vector2,
	metrics: Dictionary,
	support_index: int,
	placed: Array[Dictionary],
	player_spawn: Vector2,
	exclusion_radius: float
) -> bool:
	var half_w: float = float(metrics["half_w"])
	var visual_top: float = float(metrics["visual_top"])
	var visual_bottom: float = float(metrics["visual_bottom"])
	var my_surface_half_w: float = float(metrics["surface_half_w"])

	var cand_left: float = cand_pos.x - half_w
	var cand_right: float = cand_pos.x + half_w
	var cand_top: float = cand_pos.y + visual_top
	var cand_bottom: float = cand_pos.y + visual_bottom

	# 1. Safe Spawn Area: inside left/right walls + wall_padding, below ceiling + wall_padding, on/above floor.
	if cand_left < room_rect.position.x + wall_padding - 0.001:
		return false
	if cand_right > room_rect.end.x - wall_padding + 0.001:
		return false
	if cand_top < room_rect.position.y + wall_padding - 0.001:
		return false
	if cand_bottom > room_rect.end.y + 0.5:
		return false

	# 2. Player Spawn Exclusion Zone (radial distance + standing/jump vertical corridor).
	if cand_pos.distance_to(player_spawn) < exclusion_radius:
		return false
	var overlaps_player_x: bool = (cand_right > player_spawn.x - exclusion_radius) and (cand_left < player_spawn.x + exclusion_radius)
	if overlaps_player_x and cand_bottom > player_spawn.y - 26.0:
		return false

	# 3. Validate exact contact with floor or support surface.
	if support_index < 0:
		if absf(cand_bottom - room_rect.end.y) > 0.5:
			return false
	else:
		if support_index >= placed.size():
			return false
		var sup: Dictionary = placed[support_index]
		if not bool(sup["can_support_stack"]):
			return false
		if int(sup["tier"]) + 1 >= max_stack_tiers:
			return false
		if half_w > float(sup["surface_half_w"]) + 3.0:
			return false
		if absf(cand_bottom - float(sup["surface_y"])) > 0.5:
			return false
		var max_dx: float = _get_stack_offset_limit(metrics, sup)
		if absf(cand_pos.x - float(sup["surface_center_x"])) > max_dx + 0.5:
			return false

	# 4. Anti-overlap against all already-placed items (and InteractiveItem support interference guard).
	for idx in range(placed.size()):
		if idx == support_index:
			continue
		var other: Dictionary = placed[idx]
		var v_overlap: bool = (cand_top < float(other["bottom"]) - 0.5) and (cand_bottom > float(other["top"]) + 0.5)
		var h_overlap: bool = (cand_left < float(other["right"]) + min_gap - 0.001) and (cand_right > float(other["left"]) - min_gap + 0.001)
		if v_overlap and h_overlap:
			return false

		# Prevent InteractiveItem.cari_lantai_terdekat() from snapping onto a higher adjacent neighbor.
		var catch_radius: float = float(other["surface_half_w"]) + my_surface_half_w * 0.4
		if absf(cand_pos.x - float(other["surface_center_x"])) <= catch_radius:
			var other_surface_y: float = float(other["surface_y"])
			if cand_pos.y <= other_surface_y + 4.0:
				var snap_y: float = other_surface_y - visual_bottom
				if snap_y < cand_pos.y - 0.5:
					return false

	return true


func _pick_incremental_jittered_slot(
	metrics: Dictionary,
	placed: Array[Dictionary],
	player_spawn: Vector2,
	exclusion_radius: float
) -> Dictionary:
	var half_w: float = float(metrics["half_w"])
	var visual_bottom: float = float(metrics["visual_bottom"])
	var safe_min_x: float = room_rect.position.x + wall_padding + half_w
	var safe_max_x: float = room_rect.end.x - wall_padding - half_w
	if safe_min_x > safe_max_x:
		var cx: float = room_rect.get_center().x
		safe_min_x = cx
		safe_max_x = cx

	# Try floor slots via 1D Jittered Grid first, then eligible top-surface stack slots.
	var step: float = maxf(6.0, half_w * 2.0 + min_gap)
	var span: float = maxf(0.0, safe_max_x - safe_min_x)
	var slot_count: int = maxi(1, int(floor(span / step)) + 1)
	var jitter_x: float = maxf(0.0, step * 0.35)
	var floor_xs: Array[float] = []
	for s in range(slot_count):
		var base_x: float = safe_min_x + (span * float(s) / float(slot_count - 1)) if slot_count > 1 else (safe_min_x + safe_max_x) * 0.5
		floor_xs.append(clampf(base_x + randf_range(-jitter_x, jitter_x), safe_min_x, safe_max_x))
		floor_xs.append(base_x)
	floor_xs.shuffle()

	for cand_x in floor_xs:
		var cand_pos := Vector2(cand_x, room_rect.end.y - visual_bottom)
		if _is_valid_grounded_placement(cand_pos, metrics, -1, placed, player_spawn, exclusion_radius):
			return {"found": true, "record": _make_placed_record(cand_pos, metrics, -1, 0)}

	var supports: Array[int] = _get_eligible_support_indices(metrics, placed)
	supports.shuffle()
	for sup_idx in supports:
		var sup: Dictionary = placed[sup_idx]
		var max_dx: float = _get_stack_offset_limit(metrics, sup)
		var offsets: Array[float] = [
			randf_range(-max_dx, max_dx),
			0.0,
			-max_dx,
			max_dx,
			-max_dx * 0.5,
			max_dx * 0.5,
		]
		for dx in offsets:
			var cand_x: float = clampf(float(sup["surface_center_x"]) + dx, safe_min_x, safe_max_x)
			var cand_pos := Vector2(cand_x, float(sup["surface_y"]) - visual_bottom)
			if _is_valid_grounded_placement(cand_pos, metrics, sup_idx, placed, player_spawn, exclusion_radius):
				return {"found": true, "record": _make_placed_record(cand_pos, metrics, sup_idx, int(sup["tier"]) + 1)}

	return {"found": false}


func _get_clear_floor_intervals(player_spawn: Vector2, exclusion_radius: float) -> Array[Vector2]:
	var left_edge: float = room_rect.position.x + wall_padding
	var right_edge: float = room_rect.end.x - wall_padding
	var excl_left: float = player_spawn.x - exclusion_radius
	var excl_right: float = player_spawn.x + exclusion_radius

	var intervals: Array[Vector2] = []
	if excl_left > left_edge + 1.0:
		intervals.append(Vector2(left_edge, minf(right_edge, excl_left)))
	if excl_right < right_edge - 1.0:
		intervals.append(Vector2(maxf(left_edge, excl_right), right_edge))
	if intervals.is_empty():
		intervals.append(Vector2(left_edge, right_edge))

	# Prefer wider clear intervals first, keeping random variety between equal widths.
	intervals.sort_custom(func(a: Vector2, b: Vector2) -> bool:
		return (a.y - a.x) > (b.y - b.x)
	)
	return intervals


func _generate_jittered_floor_and_stack_fallback(
	ordered_metrics: Array[Dictionary],
	player_spawn: Vector2,
	exclusion_radius: float
) -> Array[Dictionary]:
	var intervals: Array[Vector2] = _get_clear_floor_intervals(player_spawn, exclusion_radius)
	var min_item_w: float = INF
	for m in ordered_metrics:
		min_item_w = minf(min_item_w, float(m["half_w"]) * 2.0)

	var usable_intervals: Array[Vector2] = []
	for iv in intervals:
		if (iv.y - iv.x) >= min_item_w - 0.001:
			usable_intervals.append(iv)
	if usable_intervals.is_empty():
		usable_intervals = intervals

	var interval_cursors: Array[float] = []
	for iv in usable_intervals:
		interval_cursors.append(iv.x)

	var placed: Array[Dictionary] = []

	# 1. Partition into flat bases and top-only props to guarantee enough floor columns for all items.
	var wide_bases: Array[Dictionary] = []
	var other_bases: Array[Dictionary] = []
	var top_items: Array[Dictionary] = []
	for metrics in ordered_metrics:
		var prio: int = int(metrics["support_priority"])
		var hw: float = float(metrics["half_w"])
		if prio >= 1 and hw > 15.0:
			wide_bases.append(metrics)
		elif prio >= 1:
			other_bases.append(metrics)
		else:
			top_items.append(metrics)

	wide_bases.shuffle()
	other_bases.shuffle()
	other_bases.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var wa: bool = float(a["surface_half_w"]) >= 12.0
		var wb: bool = float(b["surface_half_w"]) >= 12.0
		if wa != wb:
			return wa
		return false
	)

	var all_bases: Array[Dictionary] = []
	all_bases.append_array(wide_bases)
	all_bases.append_array(other_bases)

	var base_tiers: int = maxi(1, max_stack_tiers - 1)
	var min_floor_bases: int = mini(all_bases.size(), int(ceil(float(all_bases.size()) / float(base_tiers))))
	var floor_bases: Array[Dictionary] = []
	var extra_bases: Array[Dictionary] = []
	for b_i in range(all_bases.size()):
		if b_i < min_floor_bases:
			floor_bases.append(all_bases[b_i])
		else:
			extra_bases.append(all_bases[b_i])

	var needed_floor_tops: int = maxi(0, top_items.size() - floor_bases.size())
	var sorted_tops: Array[Dictionary] = top_items.duplicate()
	sorted_tops.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a["half_w"]) < float(b["half_w"])
	)
	var reserved_floor_tops: Array[Dictionary] = []
	var extra_tops: Array[Dictionary] = []
	for t_i in range(sorted_tops.size()):
		if t_i < needed_floor_tops:
			reserved_floor_tops.append(sorted_tops[t_i])
		else:
			extra_tops.append(sorted_tops[t_i])
	extra_tops.shuffle()

	var must_floor: Array[Dictionary] = []
	must_floor.append_array(floor_bases)
	must_floor.append_array(reserved_floor_tops)

	var optional_pool: Array[Dictionary] = []
	optional_pool.append_array(extra_bases)
	optional_pool.append_array(extra_tops)

	# Pack must_floor into usable_intervals, then greedily fit optional_pool into remaining slack.
	var iv_buckets: Array[Array] = []
	for _i in range(usable_intervals.size()):
		iv_buckets.append([])

	var unplaced: Array[Dictionary] = []
	var floor_candidates: Array[Dictionary] = []
	floor_candidates.append_array(must_floor)
	floor_candidates.append_array(optional_pool)

	for metrics in floor_candidates:
		var item_w: float = float(metrics["half_w"]) * 2.0
		var fitted: bool = false
		for iv_idx in range(usable_intervals.size()):
			var iv: Vector2 = usable_intervals[iv_idx]
			var cursor: float = interval_cursors[iv_idx]
			var lead_gap: float = min_gap if not iv_buckets[iv_idx].is_empty() else 0.0
			if cursor + lead_gap + item_w <= iv.y + 0.001:
				iv_buckets[iv_idx].append(metrics)
				interval_cursors[iv_idx] = cursor + lead_gap + item_w
				fitted = true
				break
		if not fitted:
			unplaced.append(metrics)

	var overflow_for_stack: Array[Dictionary] = []
	for iv_idx in range(usable_intervals.size()):
		var bucket: Array = iv_buckets[iv_idx]
		if bucket.is_empty():
			continue
		bucket.shuffle()
		var iv: Vector2 = usable_intervals[iv_idx]
		var slack: float = maxf(0.0, iv.y - interval_cursors[iv_idx])
		var x_pos: float = iv.x
		for b_idx in range(bucket.size()):
			var metrics: Dictionary = bucket[b_idx]
			var half_w: float = float(metrics["half_w"])
			var jitter: float = randf_range(0.0, slack * 0.5) if slack > 0.0 else 0.0
			slack = maxf(0.0, slack - jitter)
			x_pos += jitter
			var cand_pos := Vector2(x_pos + half_w, room_rect.end.y - float(metrics["visual_bottom"]))
			if _is_valid_grounded_placement(cand_pos, metrics, -1, placed, player_spawn, exclusion_radius):
				placed.append(_make_placed_record(cand_pos, metrics, -1, 0))
				x_pos += half_w * 2.0 + min_gap
			else:
				overflow_for_stack.append(metrics)

	var remaining: Array[Dictionary] = []
	remaining.append_array(overflow_for_stack)
	remaining.append_array(unplaced)
	# Stack remaining bases first (widest first), then top-only props (widest first).
	remaining.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var pa: int = int(a["support_priority"])
		var pb: int = int(b["support_priority"])
		if pa != pb:
			return pa > pb
		return float(a["half_w"]) > float(b["half_w"])
	)

	# 2. Place all remaining items onto zero-overhang / jittered support slots across placed furniture.
	for metrics in remaining:
		var placed_ok: bool = _place_on_best_support_slot(metrics, placed, player_spawn, exclusion_radius)
		if not placed_ok:
			var inc: Dictionary = _pick_incremental_jittered_slot(metrics, placed, player_spawn, exclusion_radius)
			if bool(inc.get("found", false)):
				placed.append(inc["record"])
				placed_ok = true

		if not placed_ok:
			# Last-resort grounded fallback: try full floor sweep before giving up.
			var half_w: float = float(metrics["half_w"])
			var visual_bottom: float = float(metrics["visual_bottom"])
			var safe_min_x: float = room_rect.position.x + wall_padding + half_w
			var safe_max_x: float = room_rect.end.x - wall_padding - half_w
			var fallback_pos := Vector2(clampf(player_spawn.x + exclusion_radius + half_w, safe_min_x, safe_max_x), room_rect.end.y - visual_bottom)
			for step_i in range(25):
				var test_x: float = lerpf(safe_min_x, safe_max_x, float(step_i) / 24.0)
				var test_pos := Vector2(test_x, room_rect.end.y - visual_bottom)
				if _is_valid_grounded_placement(test_pos, metrics, -1, placed, player_spawn, exclusion_radius):
					fallback_pos = test_pos
					break
			push_warning("Room2Spawner: Tight room constraints on '%s'; placed on floor fallback." % str(metrics["item_id"]))
			placed.append(_make_placed_record(fallback_pos, metrics, -1, 0))

	return placed


func _place_on_best_support_slot(
	metrics: Dictionary,
	placed: Array[Dictionary],
	player_spawn: Vector2,
	exclusion_radius: float
) -> bool:
	var half_w: float = float(metrics["half_w"])
	var visual_bottom: float = float(metrics["visual_bottom"])
	var safe_min_x: float = room_rect.position.x + wall_padding + half_w
	var safe_max_x: float = room_rect.end.x - wall_padding - half_w

	var candidates: Array[int] = _get_eligible_support_indices(metrics, placed)
	var my_prio: int = int(metrics["support_priority"])
	candidates.shuffle()
	candidates.sort_custom(func(a: int, b: int) -> bool:
		var tier_a: int = int(placed[a]["tier"])
		var tier_b: int = int(placed[b]["tier"])
		var hw_a: float = float(placed[a]["surface_half_w"])
		var hw_b: float = float(placed[b]["surface_half_w"])
		if my_prio >= 1:
			# Remaining bases stack on Tier 0 first, preferring wide-enough snug fits.
			if tier_a != tier_b:
				return tier_a < tier_b
			var fit_a: bool = hw_a >= half_w - 0.5
			var fit_b: bool = hw_b >= half_w - 0.5
			if fit_a != fit_b:
				return fit_a
			return hw_a < hw_b
		# Top-only items fill Tier 1 tops on Tier 2 before empty Tier 0 tops.
		if tier_a != tier_b:
			return tier_a > tier_b
		return hw_a < hw_b
	)

	for sup_idx in candidates:
		var sup: Dictionary = placed[sup_idx]
		var max_dx: float = _get_stack_offset_limit(metrics, sup)
		var sup_hw: float = float(sup["surface_half_w"])
		var safe_dx: float = maxf(0.0, sup_hw - half_w)
		var sup_cx: float = float(sup["surface_center_x"])
		var sup_y: float = float(sup["surface_y"])

		var offsets: Array[float] = [
			0.0,
			randf_range(-safe_dx, safe_dx),
			-safe_dx,
			safe_dx,
			randf_range(-max_dx, max_dx),
			-max_dx * 0.75,
			max_dx * 0.75,
			-max_dx,
			max_dx,
		]
		for dx in offsets:
			var cand_x: float = clampf(sup_cx + dx, safe_min_x, safe_max_x)
			var cand_pos := Vector2(cand_x, sup_y - visual_bottom)
			if _is_valid_grounded_placement(cand_pos, metrics, sup_idx, placed, player_spawn, exclusion_radius):
				placed.append(_make_placed_record(cand_pos, metrics, sup_idx, int(sup["tier"]) + 1))
				return true

	return false


func _capture_manual_room1_items() -> void:
	if _manual_room1_captured:
		return
	_manual_room1_captured = true
	_manual_room1_items.clear()

	var parent_node: Node = get_parent()
	if not parent_node:
		return

	var found: Array[Node] = parent_node.find_children("*", "InteractiveItem", true, false)
	for node in found:
		if node.get_parent() == self or node.has_meta("spawned_by_room2_spawner"):
			continue
		var item := node as InteractiveItem
		if item and (item.override_home_room == 1 or item.global_position.x < 0.0):
			_manual_room1_items.append(item)


func _set_manual_item_active(item: InteractiveItem, active: bool) -> void:
	if not is_instance_valid(item):
		return
	item.visible = active
	item.collision_layer = 2 if active else 0
	var col := item.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if col:
		col.set_deferred("disabled", not active)


func _prepare_prop_descriptors(total_objects: int) -> Array[Dictionary]:
	_capture_manual_room1_items()
	var descriptors: Array[Dictionary] = []
	var parent_node: Node = get_parent()

	if sync_room1_references:
		for i in range(_manual_room1_items.size()):
			var manual_item: InteractiveItem = _manual_room1_items[i]
			_set_manual_item_active(manual_item, i < total_objects)

	var count_to_build: int = _manual_room1_items.size() if (not sync_room1_references and _manual_room1_items.size() >= total_objects) else total_objects

	for i in range(total_objects):
		if i < _manual_room1_items.size() and is_instance_valid(_manual_room1_items[i]) and i < count_to_build:
			var r1: InteractiveItem = _manual_room1_items[i]
			var r1_sprite := r1.get_node_or_null("Sprite2D") as Sprite2D
			var r1_col := r1.get_node_or_null("CollisionShape2D") as CollisionShape2D
			var shape_size := Vector2(14.0, 4.0)
			var shape_offset := Vector2.ZERO
			if r1_col:
				shape_offset = r1_col.position
				if r1_col.shape is RectangleShape2D:
					shape_size = (r1_col.shape as RectangleShape2D).size
			descriptors.append({
				"item_id": r1.item_id.strip_edges(),
				"texture": r1_sprite.texture if r1_sprite else null,
				"sprite_scale": r1_sprite.scale if r1_sprite else LevelProgression.DEFAULT_PROP_SCALE,
				"sprite_offset": r1_sprite.position if r1_sprite else Vector2.ZERO,
				"shape_size": shape_size,
				"shape_offset": shape_offset,
				"can_support_stack": r1.can_support_stack,
			})
		else:
			var def: Dictionary = LevelProgression.get_prop_definition(i)
			var tex_path: String = def.get("texture_path", "")
			var tex := load(tex_path) as Texture2D if tex_path != "" else null
			var def_id: String = def.get("item_id", "prop_%02d" % (i + 1))
			var def_size: Vector2 = def.get("shape_size", Vector2(14.0, 4.0))
			var def_offset: Vector2 = def.get("shape_offset", Vector2.ZERO)
			var def_support: bool = bool(def.get("can_support_stack", true))

			if sync_room1_references and parent_node and object_scene:
				var r1_extra := object_scene.instantiate() as Node2D
				if r1_extra:
					var r1_pos: Vector2 = def.get("room1_pos", Vector2(-30.0 - float(i) * 12.0, -12.0))
					r1_extra.name = "ExtraRef_%s" % def_id
					r1_extra.position = r1_pos
					r1_extra.set_meta("spawned_by_room2_spawner", true)
					if r1_extra is InteractiveItem:
						var r1_item := r1_extra as InteractiveItem
						r1_item.override_home_room = 1
						r1_item.hold_until_dragged = false
						r1_item.configure_prop(def_id, tex, LevelProgression.DEFAULT_PROP_SCALE, def_size, def_offset, def_support)
					parent_node.add_child(r1_extra)
					_spawned_room1_nodes.append(r1_extra)

			descriptors.append({
				"item_id": def_id,
				"texture": tex,
				"sprite_scale": LevelProgression.DEFAULT_PROP_SCALE,
				"sprite_offset": Vector2.ZERO,
				"shape_size": def_size,
				"shape_offset": def_offset,
				"can_support_stack": def_support,
			})

	return descriptors
