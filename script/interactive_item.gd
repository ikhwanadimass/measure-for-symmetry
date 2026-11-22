extends AnimatableBody2D
class_name InteractiveItem

@export var item_id: String = "stool_01"

const MAX_DISTANCE: float = 35.0 
const FALL_SPEED: float = 300.0
const LEVEL_FLOOR_Y: float = 0.0

var is_dragging: bool = false
var player: CharacterBody2D = null
var home_room: int = 1
var initial_position: Vector2 = Vector2.ZERO
var floor_y: float = -12.0

var drag_sound_timer: float = 0.0
var prev_drag_pos: Vector2 = Vector2.ZERO

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	input_pickable = true
	sync_to_physics = true
	
	collision_layer = 2
	collision_mask = 0
	
	player = get_parent().get_node_or_null("Player")
	home_room = 1 if global_position.x < 0 else 2
	
	hitung_batas_lantai()
	
	if abs(global_position.y - floor_y) < 8.0:
		global_position.y = floor_y
		
	initial_position = global_position

func get_visual_bottom_offset() -> float:
	if sprite and sprite.texture:
		var h = sprite.texture.get_height() * abs(sprite.scale.y)
		return (h / 2.0) + sprite.position.y
	return 10.0

func get_shape_info() -> Dictionary:
	var visual_bottom = get_visual_bottom_offset()
	if collision_shape and collision_shape.shape:
		var pos_offset = collision_shape.position
		if collision_shape.shape is RectangleShape2D:
			var sz = (collision_shape.shape as RectangleShape2D).size
			return {
				"half_w": sz.x / 2.0,
				"top": pos_offset.y - (sz.y / 2.0),
				"bottom_visual": visual_bottom,
				"offset_x": pos_offset.x
			}
	return {"half_w": 10.0, "top": -visual_bottom, "bottom_visual": visual_bottom, "offset_x": 0.0}

func hitung_batas_lantai() -> void:
	floor_y = LEVEL_FLOOR_Y - get_visual_bottom_offset()

func cari_lantai_terdekat(cek_x: float, cek_y: float) -> float:
	var target_pijakan = floor_y
	var my_info = get_shape_info()
	
	var all_items = get_parent().find_children("*", "InteractiveItem", true, false)
	for other in all_items:
		if other == self or other.home_room != home_room:
			continue
			
		var other_info = other.get_shape_info() if other.has_method("get_shape_info") else {"half_w": 10.0, "top": -10.0, "offset_x": 0.0}
		var other_center_x = other.global_position.x + other_info["offset_x"]
		var batas_x = other_info["half_w"] + (my_info["half_w"] * 0.4)
		
		if abs(cek_x - other_center_x) <= batas_x:
			var permukaan_atas_other = other.global_position.y + other_info["top"]
			var letak_menumpuk = permukaan_atas_other - my_info["bottom_visual"]
			
			if cek_y <= permukaan_atas_other + 4.0:
				if letak_menumpuk < target_pijakan:
					target_pijakan = letak_menumpuk
					
	return target_pijakan

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
	prev_drag_pos = global_position
	drag_sound_timer = 0.0
	if collision_shape:
		collision_shape.set_deferred("disabled", true)

func stop_drag() -> void:
	is_dragging = false
	if collision_shape:
		collision_shape.set_deferred("disabled", false)
	# Suara ketukan kayu saat perabot ditaruh
	var am = get_node_or_null("/root/AudioManager")
	if am: am.play_sfx("drop", 3.0)

func _physics_process(delta: float) -> void:
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
		var pijakan_saat_ini = cari_lantai_terdekat(target_pos.x, target_pos.y)
		target_pos.y = clamp(target_pos.y, -85.0, pijakan_saat_ini)
		
		if home_room == 1:
			target_pos.x = clamp(target_pos.x, -193.0, -11.0)
		else:
			target_pos.x = clamp(target_pos.x, 11.0, 193.0)
			
		global_position = target_pos

		# Suara gesekan kayu jelas saat perabot bergerak diseret
		var jarak_gerak = global_position.distance_to(prev_drag_pos)
		if jarak_gerak > 0.4:
			drag_sound_timer -= delta
			if drag_sound_timer <= 0.0:
				drag_sound_timer = 0.22
				var am = get_node_or_null("/root/AudioManager")
				if am: am.play_sfx("drag", 3.0, randf_range(0.95, 1.05))
		prev_drag_pos = global_position

	elif not is_dragging:
		var target_floor = cari_lantai_terdekat(global_position.x, global_position.y)
		if global_position.y < target_floor:
			global_position.y = min(target_floor, global_position.y + FALL_SPEED * delta)
