extends Node2D

signal active_changed(is_active: bool)
signal hint_requested(message: String)
signal step_changed(message: String)

@export var door_snap_threshold: float = 28.0
@export var player_door_range: float = 35.0
@export var item_pick_radius: float = 20.0

@onready var line: Line2D = $Line2D
@onready var label: Label = $DistanceLabel

var active_room: int = 1
var center_x: float = 0.0
var floor_y: float = 0.0
var pixels_per_meter: float = 40.0

var is_active: bool = false
var input_blocked: bool = false
var is_anchored: bool = false
var is_locked: bool = false
var anchor_point: Vector2 = Vector2.ZERO
var current_end_point: Vector2 = Vector2.ZERO
var _last_dist_m: float = 0.0

func _ready() -> void:
	line.visible = false
	label.visible = false

func _get_player() -> CharacterBody2D:
	if get_tree() != null:
		var grouped := get_tree().get_first_node_in_group("player") as CharacterBody2D
		if grouped != null:
			return grouped
	if get_parent() != null:
		return get_parent().get_node_or_null("Player") as CharacterBody2D
	return null

func set_active(active: bool) -> void:
	if is_active == active:
		return
	is_active = active
	if not is_active:
		reset_measurement()
		step_changed.emit("")
	else:
		step_changed.emit("Alat Ukur Aktif — Dekati atau klik pintu untuk menancapkan meteran")
	queue_redraw()
	active_changed.emit(is_active)

func set_room_context(room: int, new_center_x: float, new_floor_y: float, new_ppm: float) -> void:
	var room_changed: bool = (room != active_room)
	active_room = room
	center_x = new_center_x
	floor_y = new_floor_y
	pixels_per_meter = maxf(new_ppm, 1.0)
	if room_changed:
		reset_measurement()
		queue_redraw()

func set_input_blocked(blocked: bool) -> void:
	input_blocked = blocked
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if input_blocked:
		return

	if event.is_action_pressed("measure"):
		set_active(not is_active)
		return

	if not is_active:
		return

	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
			reset_measurement()
		elif mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			handle_click(get_global_mouse_position())

func handle_click(mouse_pos: Vector2) -> void:
	if not is_anchored:
		try_anchor_at(mouse_pos)
	elif not is_locked:
		var picked_item: InteractiveItem = _find_item_near(mouse_pos)
		if picked_item != null:
			try_measure_item(picked_item)
		else:
			lock_current_measurement()
	else:
		reset_measurement()
		try_anchor_at(mouse_pos)

func try_anchor_at(world_pos: Vector2) -> bool:
	var p: CharacterBody2D = _get_player()
	var mouse_near_door: bool = absf(world_pos.x - center_x) <= door_snap_threshold and world_pos.y <= floor_y + 15.0 and world_pos.y >= -105.0
	var player_near_door: bool = p != null and absf(p.global_position.x - center_x) <= player_door_range
	if not mouse_near_door and not player_near_door:
		hint_requested.emit("Dekati atau klik pintu terlebih dahulu!")
		return false

	var anchor_y: float = p.global_position.y if p != null else clampf(world_pos.y, -95.0, floor_y)
	anchor_point = Vector2(center_x, anchor_y)
	current_end_point = anchor_point
	is_anchored = true
	is_locked = false
	line.visible = true
	label.visible = true
	line.clear_points()
	line.add_point(anchor_point)
	line.add_point(anchor_point)
	_last_dist_m = 0.0
	label.text = "0.00 m"
	label.global_position = anchor_point + Vector2(-20.0, -14.0)
	step_changed.emit("Tarik kabel ke barang, lalu klik kiri untuk mengunci jarak")
	queue_redraw()
	return true

func try_measure_item(item: InteractiveItem) -> bool:
	if not is_anchored or item == null:
		return false
	if not _is_item_in_active_room(item):
		return false
	_last_dist_m = _update_horizontal_cable(Vector2(center_x, item.global_position.y), item.global_position)
	is_locked = true
	var item_label: String = item.get_display_name()
	step_changed.emit("Jarak %s: %.2f m dari pintu (Klik kanan atau [F] untuk gulung)" % [item_label, _last_dist_m])
	queue_redraw()
	return true

func lock_current_measurement() -> void:
	if not is_anchored:
		return
	is_locked = true
	step_changed.emit("Jarak terkunci: %.2f m dari pintu (Klik kanan atau [F] untuk gulung)" % _last_dist_m)
	queue_redraw()

func update_cable_to_player() -> void:
	if not is_anchored or is_locked:
		return
	var p: CharacterBody2D = _get_player()
	var mouse_pos: Vector2 = get_global_mouse_position()
	var hovered_item: InteractiveItem = _find_item_near(mouse_pos)
	var cable_y: float = p.global_position.y if p != null else anchor_point.y
	var end_x: float = anchor_point.x

	if hovered_item != null:
		cable_y = hovered_item.global_position.y
		end_x = hovered_item.global_position.x
	elif p != null:
		if absf(mouse_pos.x - p.global_position.x) <= 35.0 and _is_x_in_active_room(mouse_pos.x):
			end_x = mouse_pos.x
		else:
			end_x = p.global_position.x
	else:
		end_x = _clamp_to_active_room(mouse_pos).x

	end_x = _clamp_x_to_active_room(end_x)
	_last_dist_m = _update_horizontal_cable(Vector2(center_x, cable_y), Vector2(end_x, cable_y))

func _process(_delta: float) -> void:
	if not is_active or input_blocked:
		return
	queue_redraw()
	if is_anchored and not is_locked:
		update_cable_to_player()

func _draw() -> void:
	if not is_active:
		return
	var axis_color := Color(0.35, 0.85, 1.0, 0.55)
	draw_line(Vector2(center_x, -96.0), Vector2(center_x, floor_y), axis_color, 1.5)

	if input_blocked:
		return

	var mouse_pos: Vector2 = get_global_mouse_position()
	var p: CharacterBody2D = _get_player()
	if not is_anchored:
		var mouse_near_door: bool = absf(mouse_pos.x - center_x) <= door_snap_threshold and mouse_pos.y <= floor_y + 15.0 and mouse_pos.y >= -105.0
		var player_near_door: bool = p != null and absf(p.global_position.x - center_x) <= player_door_range
		if mouse_near_door or player_near_door:
			var snap_y: float = p.global_position.y if p != null else clampf(mouse_pos.y, -95.0, floor_y)
			draw_circle(Vector2(center_x, snap_y), 3.5, Color(1.0, 0.9, 0.25, 0.95))
	elif not is_locked:
		var hovered_item: InteractiveItem = _find_item_near(mouse_pos)
		if hovered_item != null:
			draw_circle(hovered_item.global_position, 5.0, Color(0.4, 1.0, 0.55, 0.85))

func _update_horizontal_cable(start_pos: Vector2, end_pos: Vector2) -> float:
	current_end_point = end_pos
	if line.get_point_count() < 2:
		line.clear_points()
		line.add_point(start_pos)
		line.add_point(end_pos)
	else:
		line.set_point_position(0, start_pos)
		line.set_point_position(1, end_pos)

	var dist_px: float = absf(end_pos.x - center_x)
	var dist_m: float = dist_px / pixels_per_meter
	label.text = "%.2f m" % dist_m
	var mid_point: Vector2 = (start_pos + end_pos) / 2.0
	var label_x: float = mid_point.x - 20.0
	if active_room == 1:
		label_x = clampf(label_x, -196.0, center_x - 36.0)
	else:
		label_x = clampf(label_x, center_x + 4.0, 160.0)
	var label_y: float = clampf(mid_point.y - 16.0, -86.0, floor_y - 14.0)
	label.global_position = Vector2(label_x, label_y)
	return dist_m

func _find_item_near(world_pos: Vector2) -> InteractiveItem:
	var parent_node := get_parent()
	if parent_node == null:
		return null
	var best_item: InteractiveItem = null
	var best_dist: float = item_pick_radius
	for node: Node in parent_node.find_children("*", "InteractiveItem", true, false):
		var item := node as InteractiveItem
		if item == null or not _is_item_in_active_room(item):
			continue
		var d: float = item.global_position.distance_to(world_pos)
		if d <= best_dist:
			best_dist = d
			best_item = item
	return best_item

func _is_item_in_active_room(item: InteractiveItem) -> bool:
	if active_room == 1:
		return item.global_position.x < center_x
	return item.global_position.x >= center_x

func _is_x_in_active_room(x: float) -> bool:
	if active_room == 1:
		return x >= -204.0 and x <= center_x + door_snap_threshold
	return x >= center_x - door_snap_threshold and x <= 204.0

func _clamp_x_to_active_room(x: float) -> float:
	if active_room == 1:
		return clampf(x, -200.0, center_x)
	return clampf(x, center_x, 200.0)

func _clamp_to_active_room(pos: Vector2) -> Vector2:
	return Vector2(_clamp_x_to_active_room(pos.x), clampf(pos.y, -96.0, floor_y))

func reset_measurement() -> void:
	is_anchored = false
	is_locked = false
	_last_dist_m = 0.0
	line.clear_points()
	line.visible = false
	label.visible = false
	if is_active:
		step_changed.emit("Alat Ukur Aktif — Dekati atau klik pintu untuk menancapkan meteran")
	queue_redraw()
