extends RigidBody2D
class_name InteractiveItem

@export var item_id: String = "stool_01"

const MAX_DISTANCE: float = 35.0 

var is_dragging: bool = false
var player: CharacterBody2D = null
var home_room: int = 1 # 1: Ruang 1 (Kiri), 2: Ruang 2 (Kanan)
var initial_position: Vector2 = Vector2.ZERO # Posisi patokan awal asli

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	input_pickable = true
	lock_rotation = true
	player = get_parent().get_node_or_null("Player")
	
	# 1. Catat ruangan asal dan posisi patokan awal barang
	home_room = 1 if global_position.x < 0 else 2
	initial_position = global_position

func _input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if not player:
			return
			
		# Hanya bisa di-drag jika pemain berada di ruangan yang sama DAN dekat
		var player_in_same_room = (player.global_position.x < 0 and home_room == 1) or (player.global_position.x > 0 and home_room == 2)
		if not player_in_same_room:
			return
			
		var distance = global_position.distance_to(player.global_position)
		if distance <= MAX_DISTANCE:
			start_drag()

func _input(event: InputEvent) -> void:
	if is_dragging and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		stop_drag()

func start_drag() -> void:
	is_dragging = true
	freeze = true
	# Matikan tabrakan sementara: agar tidak mendorong pemain
	collision_shape.set_deferred("disabled", true)

func stop_drag() -> void:
	is_dragging = false
	freeze = false
	# Nyalakan kembali tabrakan: bangku kembali padat dan bisa dinaiki
	collision_shape.set_deferred("disabled", false)

func _physics_process(_delta: float) -> void:
	if is_dragging and player:
		# Jika pemain tiba-tiba pindah ruangan (tekan E di pintu), lepas barangnya seketika!
		var player_in_same_room = (player.global_position.x < 0 and home_room == 1) or (player.global_position.x > 0 and home_room == 2)
		if not player_in_same_room:
			stop_drag()
			return

		var mouse_pos = get_global_mouse_position()
		
		# Batasi jarak bawa dari pemain
		var from_player = mouse_pos - player.global_position
		if from_player.length() > MAX_DISTANCE:
			from_player = from_player.normalized() * MAX_DISTANCE
		
		var target_pos = player.global_position + from_player
		
		# Kunci agar tidak pernah bisa menyeberang batas ruangan asalnya
		if home_room == 1:
			target_pos.x = clamp(target_pos.x, -200.0, -8.0)
		else:
			target_pos.x = clamp(target_pos.x, 8.0, 200.0)
			
		target_pos.y = clamp(target_pos.y, -90.0, 0.0)
		
		global_position = target_pos
