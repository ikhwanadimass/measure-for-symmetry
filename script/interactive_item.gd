extends AnimatableBody2D
class_name InteractiveItem

@export var item_id: String = "stool_01"
@export var hold_until_dragged: bool = false
@export var override_home_room: int = 0
@export var can_support_stack: bool = true

const MAX_DISTANCE: float = 55.0
const FALL_SPEED: float = 300.0
const LEVEL_FLOOR_Y: float = 0.0

static var _active_drag_item: InteractiveItem = null

var is_dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO
var player: CharacterBody2D = null
var home_room: int = 1
var initial_position: Vector2 = Vector2.ZERO
var floor_y: float = -12.0

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	input_pickable = true
	sync_to_physics = false

	# Pindahkan barang ke Collision Layer 2 (Props) agar terpisah dari tembok/lantai
	collision_layer = 2
	collision_mask = 0

	player = _find_player()
	if override_home_room == 1 or override_home_room == 2:
		home_room = override_home_room
	else:
		home_room = 1 if global_position.x < 0.0 else 2

	hitung_batas_lantai()

	# Letakkan pas di permukaan terdekat (lantai atau atas perabotan lain) saat game mulai
	if not hold_until_dragged:
		var nearest_surface: float = cari_lantai_terdekat(global_position.x, global_position.y)
		if absf(global_position.y - nearest_surface) < 8.0:
			global_position.y = nearest_surface

	initial_position = global_position

func _exit_tree() -> void:
	if _active_drag_item == self:
		_active_drag_item = null


func _find_player() -> CharacterBody2D:
	var parent_node: Node = get_parent()
	if parent_node:
		var direct_player := parent_node.get_node_or_null("Player") as CharacterBody2D
		if direct_player:
			return direct_player

	var tree := get_tree()
	if tree and tree.current_scene:
		var scene_player := tree.current_scene.find_child("Player", true, false) as CharacterBody2D
		if scene_player:
			return scene_player

	var ancestor: Node = parent_node
	while ancestor:
		var found := ancestor.get_node_or_null("Player") as CharacterBody2D
		if found:
			return found
		ancestor = ancestor.get_parent()

	return null


## Configures item identity, sprite texture/scale, collision shape, and stackability.
func configure_prop(
	new_item_id: String,
	new_texture: Texture2D,
	new_sprite_scale: Vector2,
	new_shape_size: Vector2,
	new_shape_offset: Vector2 = Vector2.ZERO,
	new_can_support_stack: bool = true
) -> void:
	item_id = new_item_id.strip_edges()
	can_support_stack = new_can_support_stack
	var target_sprite := get_node_or_null("Sprite2D") as Sprite2D
	if target_sprite:
		if new_texture:
			target_sprite.texture = new_texture
		if new_sprite_scale != Vector2.ZERO:
			target_sprite.scale = new_sprite_scale

	var target_collision := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if target_collision:
		var rect_shape := RectangleShape2D.new()
		rect_shape.size = new_shape_size
		target_collision.shape = rect_shape
		target_collision.position = new_shape_offset
		target_collision.one_way_collision = true

	if is_inside_tree():
		hitung_batas_lantai()


## Returns the rendered visual bounding size of the sprite in pixels.
func get_visual_size() -> Vector2:
	var target_sprite: Sprite2D = sprite if sprite else get_node_or_null("Sprite2D") as Sprite2D
	if target_sprite and target_sprite.texture:
		var w: float = float(target_sprite.texture.get_width()) * absf(target_sprite.scale.x)
		var h: float = float(target_sprite.texture.get_height()) * absf(target_sprite.scale.y)
		return Vector2(w, h)
	return Vector2(16.0, 18.0)

# Batas kaki paling bawah murni dari Sprite visualnya (ANTI AMBLAS)
func get_visual_bottom_offset() -> float:
	var target_sprite: Sprite2D = sprite if sprite else get_node_or_null("Sprite2D") as Sprite2D
	if target_sprite and target_sprite.texture:
		var h: float = float(target_sprite.texture.get_height()) * absf(target_sprite.scale.y)
		return (h / 2.0) + target_sprite.position.y
	return 10.0

# Permukaan atas untuk tempat menaruh barang lain (meja/kursi)
func get_shape_info() -> Dictionary:
	var visual_bottom: float = get_visual_bottom_offset()
	var target_col: CollisionShape2D = collision_shape if collision_shape else get_node_or_null("CollisionShape2D") as CollisionShape2D
	if target_col and target_col.shape:
		var pos_offset: Vector2 = target_col.position
		if target_col.shape is RectangleShape2D:
			var sz: Vector2 = (target_col.shape as RectangleShape2D).size
			return {
				"half_w": sz.x / 2.0,
				"top": pos_offset.y - (sz.y / 2.0),
				"bottom_visual": visual_bottom,
				"offset_x": pos_offset.x
			}
	return {"half_w": 10.0, "top": -visual_bottom, "bottom_visual": visual_bottom, "offset_x": 0.0}

func hitung_batas_lantai() -> void:
	floor_y = LEVEL_FLOOR_Y - get_visual_bottom_offset()

# Sistem Stacking: Meletakkan barang di atas meja/kursi
func cari_lantai_terdekat(cek_x: float, cek_y: float) -> float:
	var target_pijakan: float = floor_y
	var my_info: Dictionary = get_shape_info()

	var tree := get_tree()
	var search_root: Node = tree.current_scene if (tree and tree.current_scene) else get_parent()
	if not search_root:
		return target_pijakan

	var all_items: Array[Node] = search_root.find_children("*", "InteractiveItem", true, false)
	for other_node in all_items:
		var other := other_node as InteractiveItem
		if not other or other == self or not is_instance_valid(other) or other.is_queued_for_deletion():
			continue
		if not other.visible or other.home_room != home_room:
			continue
		if other.is_dragging or not other.can_support_stack:
			continue

		var other_info: Dictionary = other.get_shape_info()
		var other_offset_x: float = other_info.get("offset_x", 0.0)
		var other_half_w: float = other_info.get("half_w", 10.0)
		var other_top: float = other_info.get("top", -10.0)
		var my_half_w: float = my_info.get("half_w", 10.0)
		var my_bottom_visual: float = my_info.get("bottom_visual", 10.0)

		var other_center_x: float = other.global_position.x + other_offset_x
		var batas_x: float = other_half_w + (my_half_w * 0.4)

		if absf(cek_x - other_center_x) <= batas_x:
			var permukaan_atas_other: float = other.global_position.y + other_top
			var letak_menumpuk: float = permukaan_atas_other - my_bottom_visual

			if cek_y <= permukaan_atas_other + 4.0:
				if letak_menumpuk < target_pijakan:
					target_pijakan = letak_menumpuk

	return target_pijakan

func _is_measure_tool_active() -> bool:
	var tree := get_tree()
	if not tree or not tree.current_scene:
		return false
	var mt := tree.current_scene.find_child("MeasureTool", true, false)
	if mt and "is_active" in mt:
		return bool(mt.get("is_active"))
	return false

func _is_player_in_same_room() -> bool:
	if not player or not is_instance_valid(player):
		return false
	return (player.global_position.x < 0.0 and home_room == 1) or (player.global_position.x > 0.0 and home_room == 2)

func _distance_to_player() -> float:
	if not player or not is_instance_valid(player):
		return INF
	return global_position.distance_to(player.global_position)

func get_visual_rect_global(pad: float = 2.0) -> Rect2:
	var target_sprite: Sprite2D = sprite if sprite else get_node_or_null("Sprite2D") as Sprite2D
	if target_sprite and target_sprite.texture:
		var sz := Vector2(
			float(target_sprite.texture.get_width()) * absf(target_sprite.global_scale.x),
			float(target_sprite.texture.get_height()) * absf(target_sprite.global_scale.y)
		)
		var center: Vector2 = target_sprite.global_position
		if not target_sprite.centered:
			center += sz * 0.5
		var half: Vector2 = sz * 0.5 + Vector2(pad, pad)
		return Rect2(center - half, half * 2.0)
	var fallback_half := Vector2(8.0 + pad, 9.0 + pad)
	return Rect2(global_position - fallback_half, fallback_half * 2.0)

func contains_global_point(world_point: Vector2, pad: float = 2.0) -> bool:
	return get_visual_rect_global(pad).has_point(world_point)

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed):
		return
	if not visible or is_queued_for_deletion() or is_dragging:
		return
	var tree := get_tree()
	if not tree or tree.paused:
		return
	if _active_drag_item != null and is_instance_valid(_active_drag_item):
		return
	if _is_measure_tool_active():
		return

	if not player or not is_instance_valid(player):
		player = _find_player()
	if not _is_player_in_same_room():
		return

	var mouse_pos: Vector2 = get_global_mouse_position()
	if not contains_global_point(mouse_pos):
		return
	if _distance_to_player() > MAX_DISTANCE:
		return

	var best_item: InteractiveItem = self
	var best_dist: float = global_position.distance_to(mouse_pos)
	var search_root: Node = tree.current_scene if tree.current_scene else get_parent()
	if search_root:
		var all_items: Array[Node] = search_root.find_children("*", "InteractiveItem", true, false)
		for other_node in all_items:
			var other := other_node as InteractiveItem
			if not other or other == self or not is_instance_valid(other) or other.is_queued_for_deletion():
				continue
			if not other.visible or other.home_room != home_room or other.is_dragging:
				continue
			other.player = player
			if not other.contains_global_point(mouse_pos) or other._distance_to_player() > MAX_DISTANCE:
				continue
			var d: float = other.global_position.distance_to(mouse_pos)
			if d < best_dist - 0.5 or (absf(d - best_dist) <= 0.5 and other.get_index() > best_item.get_index()):
				best_item = other
				best_dist = d

	best_item.start_drag(mouse_pos)
	get_viewport().set_input_as_handled()

func _input(event: InputEvent) -> void:
	if is_dragging and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		stop_drag()

func start_drag(grab_world_pos: Vector2 = global_position) -> void:
	if _active_drag_item and is_instance_valid(_active_drag_item) and _active_drag_item != self:
		_active_drag_item.stop_drag()
	if not player or not is_instance_valid(player):
		player = _find_player()
	is_dragging = true
	_active_drag_item = self
	hold_until_dragged = false
	drag_offset = global_position - grab_world_pos
	z_index = 10
	modulate = Color(1.15, 1.15, 0.9, 1.0)
	if collision_shape:
		collision_shape.set_deferred("disabled", true)

func stop_drag() -> void:
	is_dragging = false
	drag_offset = Vector2.ZERO
	if _active_drag_item == self:
		_active_drag_item = null
	z_index = 0
	modulate = Color(1.0, 1.0, 1.0, 1.0)
	if collision_shape:
		collision_shape.set_deferred("disabled", false)

func _physics_process(delta: float) -> void:
	if is_dragging and player:
		if not _is_player_in_same_room():
			stop_drag()
			return

		var desired_pos: Vector2 = get_global_mouse_position() + drag_offset
		var from_player: Vector2 = desired_pos - player.global_position
		if from_player.length() > MAX_DISTANCE:
			from_player = from_player.normalized() * MAX_DISTANCE

		var target_pos: Vector2 = player.global_position + from_player
		var pijakan_saat_ini: float = cari_lantai_terdekat(target_pos.x, target_pos.y)
		target_pos.y = clampf(target_pos.y, -85.0, pijakan_saat_ini)

		if home_room == 1:
			target_pos.x = clampf(target_pos.x, -193.0, -11.0)
		else:
			target_pos.x = clampf(target_pos.x, 11.0, 193.0)

		global_position = target_pos

	elif not is_dragging:
		if not hold_until_dragged:
			var target_floor: float = cari_lantai_terdekat(global_position.x, global_position.y)
			if global_position.y < target_floor:
				global_position.y = minf(target_floor, global_position.y + FALL_SPEED * delta)
