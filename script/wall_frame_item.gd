extends InteractiveItem
class_name WallFrameItem

## Figura / frame dinding yang dapat menempel bebas di mana saja pada dinding tanpa jatuh.

func _ready() -> void:
	input_pickable = true
	sync_to_physics = false

	# Gunakan Collision Layer 4 agar tetap bisa di-klik mouse namun diabaikan Player (mask = 3).
	collision_layer = 4
	collision_mask = 0
	if collision_shape:
		collision_shape.one_way_collision = false

	var parent_node: Node = get_parent()
	player = parent_node.get_node_or_null("Player") as CharacterBody2D if parent_node else null
	home_room = 1 if global_position.x < 0.0 else 2

	hitung_batas_lantai()
	initial_position = global_position


func get_visual_half_width() -> float:
	if sprite and sprite.texture:
		var w: float = sprite.texture.get_width() * absf(sprite.scale.x)
		return (w / 2.0) + absf(sprite.position.x)
	return 10.0


func get_shape_info() -> Dictionary:
	# Nilai non-support agar perabotan lantai tidak pernah bertumpuk ke figura dinding.
	return {
		"half_w": -10000.0,
		"top": 10000.0,
		"bottom_visual": get_visual_bottom_offset(),
		"offset_x": 0.0
	}


func cari_lantai_terdekat(_cek_x: float, cek_y: float) -> float:
	return cek_y


func _physics_process(_delta: float) -> void:
	if is_dragging and player:
		var player_in_same_room: bool = (player.global_position.x < 0.0 and home_room == 1) or (player.global_position.x > 0.0 and home_room == 2)
		if not player_in_same_room:
			stop_drag()
			return

		var mouse_pos: Vector2 = get_global_mouse_position()
		var from_player: Vector2 = mouse_pos - player.global_position
		if from_player.length() > MAX_DISTANCE:
			from_player = from_player.normalized() * MAX_DISTANCE

		var target_pos: Vector2 = player.global_position + from_player
		var half_h: float = get_visual_bottom_offset()
		var half_w: float = get_visual_half_width()
		target_pos.y = clampf(target_pos.y, -96.0 + half_h + 2.0, -half_h - 1.0)

		if home_room == 1:
			target_pos.x = clampf(target_pos.x, -200.0 + half_w + 1.0, -8.0 - half_w - 1.0)
		else:
			target_pos.x = clampf(target_pos.x, 8.0 + half_w + 1.0, 200.0 - half_w - 1.0)

		global_position = target_pos
