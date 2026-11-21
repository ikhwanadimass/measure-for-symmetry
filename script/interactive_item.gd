extends AnimatableBody2D
class_name InteractiveItem

@export var item_id: String = "stool_01"

const MAX_DISTANCE: float = 35.0 
const FLOOR_Y: float = -12.0 # Ketinggian lantai yang pas untuk bangku
const FALL_SPEED: float = 300.0 # Kecepatan jatuh saat dilepas di udara

var is_dragging: bool = false
var player: CharacterBody2D = null
var home_room: int = 1
var initial_position: Vector2 = Vector2.ZERO

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	input_pickable = true
	sync_to_physics = true
	player = get_parent().get_node_or_null("Player")
	home_room = 1 if global_position.x < 0 else 2
	initial_position = global_position

func _input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if not player:
			return
		var player_in_same_room = (player.global_position.x < 0 and home_room == 1) or (player.global_position.x > 0 and home_room == 2)
		if not player_in_same_room:
			return
		if global_position.distance_to(player.global_position) <= MAX_DISTANCE:
			start_drag()

func _input(event: InputEvent) -> void:
	if is_dragging and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		stop_drag()

func start_drag() -> void:
	is_dragging = true
	collision_shape.set_deferred("disabled", true)

func stop_drag() -> void:
	is_dragging = false
	collision_shape.set_deferred("disabled", false)

func _physics_process(delta: float) -> void:
	# 1. Saat sedang di-drag oleh pemain
	if is_dragging and player:
		var player_in_same_room = (player.global_position.x < 0 and home_room == 1) or (player.global_position.x > 0 and home_room == 2)
		if not player_in_same_room:
			stop_drag()
			return

		var mouse_pos = get_global_mouse_position()
		var from_player = mouse_pos - player.global_position
		if from_player.length() > MAX_DISTANCE:
			from_player = from_player.normalized() * MAX_DISTANCE
		
		var target_pos = player.global_position + from_player
		
		# Batas ruangan horizontal (mepet dinding tanpa menembus dinding)
		if home_room == 1:
			target_pos.x = clamp(target_pos.x, -193.0, -11.0)
		else:
			target_pos.x = clamp(target_pos.x, 11.0, 193.0)
			
		# Saat di-drag, pemain bisa mengangkatnya ke atas untuk melewati barang lain
		target_pos.y = clamp(target_pos.y, -85.0, FLOOR_Y)
		global_position = target_pos

	# 2. Saat dilepas: bangku otomatis jatuh kembali ke lantai (jangan sampai melayang)
	elif not is_dragging:
		var target_floor = FLOOR_Y
		
		# Cek apakah ada bangku lain di bawahnya jika ditumpuk
		var space_state = get_world_2d().direct_space_state
		var query = PhysicsRayQueryParameters2D.create(global_position, Vector2(global_position.x, FLOOR_Y + 10.0), 2)
		query.exclude = [get_rid()]
		var result = space_state.intersect_ray(query)
		if result:
			target_floor = min(FLOOR_Y, result.position.y - 12.0)
			
		if global_position.y < target_floor:
			global_position.y = min(target_floor, global_position.y + FALL_SPEED * delta)
