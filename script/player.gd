extends CharacterBody2D

@export var speed: float = 160.0
@export var jump_velocity: float = -185.0

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var _drop_through_timer: float = 0.0
var _excepted_items: Dictionary[int, PhysicsBody2D] = {}

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	# Deteksi Lantai/Dinding (Layer 1) dan perabotan pijakan satu-arah (Layer 2)
	# sehingga pemain bisa menembus sisi/bawah objek dan melompat naik ke atasnya.
	collision_mask = 3

func _get_feet_y() -> float:
	if collision_shape and collision_shape.shape is CapsuleShape2D:
		var cap := collision_shape.shape as CapsuleShape2D
		return global_position.y + collision_shape.position.y + (cap.height * 0.5)
	return global_position.y + 16.0

func _is_standing_on_one_way_prop() -> bool:
	if not is_on_floor():
		return false
	var standing_on_prop: bool = false
	for i in range(get_slide_collision_count()):
		var col: KinematicCollision2D = get_slide_collision(i)
		if col and col.get_normal().y < -0.5:
			var collider: Object = col.get_collider()
			if collider is InteractiveItem:
				standing_on_prop = true
			else:
				return false
	return standing_on_prop

func _sync_prop_collision_exceptions() -> void:
	for iid: int in _excepted_items.keys():
		var cached: PhysicsBody2D = _excepted_items[iid]
		if not is_instance_valid(cached) or cached.is_queued_for_deletion():
			_excepted_items.erase(iid)

	var tree := get_tree()
	if not tree:
		return

	var feet_y: float = _get_feet_y()
	for node in tree.get_nodes_in_group("interactive_items"):
		var item := node as InteractiveItem
		if not item:
			continue
		var should_collide: bool = (
			_drop_through_timer <= 0.0
			and item.visible
			and not item.is_queued_for_deletion()
			and item.can_player_stand
			and not item.is_dragging
			and velocity.y >= 0.0
			and feet_y <= item.get_platform_top_y() + 1.0
		)
		var iid: int = item.get_instance_id()
		if not should_collide:
			if not _excepted_items.has(iid):
				add_collision_exception_with(item)
				_excepted_items[iid] = item
		elif _excepted_items.has(iid):
			remove_collision_exception_with(item)
			_excepted_items.erase(iid)

func _physics_process(delta: float) -> void:
	if _drop_through_timer > 0.0:
		_drop_through_timer -= delta
	elif (Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN)) and _is_standing_on_one_way_prop():
		_drop_through_timer = 0.15
		position.y += 1.0

	# 1. Tambah gravitasi saat melayang
	if not is_on_floor():
		velocity.y += gravity * delta

	# 2. Lompat dengan Spacebar
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	# 3. Gerak kiri/kanan (A dan D)
	var direction := Input.get_axis("move_left", "move_right")
	if direction != 0:
		velocity.x = direction * speed
		sprite.flip_h = (direction < 0)
	else:
		velocity.x = move_toward(velocity.x, 0, speed)

	# 4. Sinkronkan pengecualian tumbukan sebelum move_and_slide agar sisi/bawah objek selalu tembus
	_sync_prop_collision_exceptions()
	move_and_slide()

	# 5. Animasi
	update_animation(direction)

func update_animation(direction: float) -> void:
	if not is_on_floor():
		if velocity.y < 0:
			sprite.play("jump")
		else:
			sprite.play("fall")
	else:
		if direction != 0:
			sprite.play("walk")
		else:
			sprite.play("idle")
