extends AnimatableBody2D
class_name InteractiveItem

signal drag_rejected(message: String)

@export var item_id: String = "stool_01"
@export var display_name: String = ""
@export var room_id: int = 0
@export var reference_room_override: bool = false
@export var floor_y: float = 0.0
@export var floor_rest_offset: float = 12.0
@export var room_x_min: float = -193.0
@export var room_x_max: float = -11.0
@export var room_y_min: float = -85.0

const MAX_DISTANCE: float = 35.0
const FALL_SPEED: float = 300.0

var is_dragging: bool = false
var is_locked_reference: bool = false
var interaction_blocked: bool = false:
	set(value):
		interaction_blocked = value
		if interaction_blocked:
			cancel_drag()

var player: CharacterBody2D = null
var home_room: int = 1
var initial_position: Vector2 = Vector2.ZERO
var _is_hovered: bool = false

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	input_pickable = true
	sync_to_physics = false
	collision_layer |= 2
	if get_tree() != null:
		player = get_tree().get_first_node_in_group("player") as CharacterBody2D
	if player == null and get_parent() != null:
		player = get_parent().get_node_or_null("Player") as CharacterBody2D
	home_room = room_id if room_id > 0 else (1 if global_position.x < 0.0 else 2)
	is_locked_reference = reference_room_override or (home_room % 2 == 0)
	initial_position = global_position
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func get_display_name() -> String:
	if not display_name.is_empty():
		return display_name
	if not item_id.is_empty():
		return item_id
	return name

func _is_player_in_same_room() -> bool:
	if player == null:
		return false
	var same_side: bool = (player.global_position.x < 0.0 and (home_room % 2 == 1)) or (player.global_position.x >= 0.0 and (home_room % 2 == 0))
	var same_floor: bool = absf(player.global_position.y - (floor_y - 16.0)) < 75.0
	return same_side and same_floor

func _input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if is_locked_reference or interaction_blocked:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if not _is_player_in_same_room():
			return
		if global_position.distance_to(player.global_position) <= MAX_DISTANCE:
			start_drag()
			get_viewport().set_input_as_handled()
		else:
			drag_rejected.emit("Dekati %s terlebih dahulu untuk memindahkannya!" % get_display_name())

func _input(event: InputEvent) -> void:
	if is_dragging and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		stop_drag()

func start_drag() -> void:
	if is_locked_reference or interaction_blocked:
		return
	is_dragging = true
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
	_update_visual_highlight()

func stop_drag() -> void:
	is_dragging = false
	if collision_shape:
		collision_shape.set_deferred("disabled", false)
	_update_visual_highlight()

func cancel_drag() -> void:
	if is_dragging:
		stop_drag()

func _on_mouse_entered() -> void:
	_is_hovered = true
	_update_visual_highlight()

func _on_mouse_exited() -> void:
	_is_hovered = false
	_update_visual_highlight()

func _update_visual_highlight() -> void:
	if is_dragging:
		modulate = Color(1.15, 1.15, 0.9, 1.0)
	elif _is_hovered and not is_locked_reference and not interaction_blocked:
		modulate = Color(1.08, 1.08, 1.08, 1.0)
	else:
		modulate = Color.WHITE

func _physics_process(delta: float) -> void:
	var rest_y: float = floor_y - floor_rest_offset
	if is_dragging and player:
		if is_locked_reference or interaction_blocked or not _is_player_in_same_room():
			stop_drag()
			return

		var mouse_pos: Vector2 = get_global_mouse_position()
		var from_player: Vector2 = mouse_pos - player.global_position
		if from_player.length() > MAX_DISTANCE:
			from_player = from_player.normalized() * MAX_DISTANCE

		var target_pos: Vector2 = player.global_position + from_player
		target_pos.x = clampf(target_pos.x, room_x_min, room_x_max)
		target_pos.y = clampf(target_pos.y, room_y_min, rest_y)
		global_position = target_pos

	elif not is_dragging and not is_locked_reference:
		var target_floor: float = rest_y
		var space_state := get_world_2d().direct_space_state
		var query := PhysicsRayQueryParameters2D.create(global_position, Vector2(global_position.x, rest_y + 10.0), 2)
		query.exclude = [get_rid()]
		var result: Dictionary = space_state.intersect_ray(query)
		if not result.is_empty():
			var hit_pos: Vector2 = result["position"] as Vector2
			target_floor = minf(rest_y, hit_pos.y - floor_rest_offset)

		if global_position.y < target_floor:
			global_position.y = minf(target_floor, global_position.y + FALL_SPEED * delta)
