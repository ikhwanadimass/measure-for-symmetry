extends CharacterBody2D

@export var speed: float = 160.0
@export var jump_velocity: float = -150.0

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	# Pemain hanya bertumbukan dengan Lantai/Dinding (Layer 1) dan menembus perabotan (Layer 2)
	# agar pemain leluasa menumpuk dan mengatur objek tanpa terhalang collider perabotan.
	collision_mask = 1

func _physics_process(delta: float) -> void:
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

	# 4. Gerakan CharacterBody2D
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
