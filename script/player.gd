extends CharacterBody2D

# Kecepatan lari dan tinggi lompat
@export var speed: float = 160.0
@export var jump_velocity: float = -150.0

# Gravitasi bawaan engine
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var input_locked: bool = false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _physics_process(delta: float) -> void:
	# 1. Tambah gravitasi saat pemain melayang di udara
	if not is_on_floor():
		velocity.y += gravity * delta

	var direction: float = 0.0
	if not input_locked:
		# 2. Lompat dengan Spacebar (Action: jump)
		if Input.is_action_just_pressed("jump") and is_on_floor():
			velocity.y = jump_velocity

		# 3. Gerak kiri/kanan dengan A dan D (Action: move_left & move_right)
		direction = Input.get_axis("move_left", "move_right")

	if direction != 0.0:
		velocity.x = direction * speed
		sprite.flip_h = (direction < 0.0) # Menghadap ke kiri saat arahnya minus
	else:
		velocity.x = move_toward(velocity.x, 0.0, speed)

	# 4. Eksekusi pergerakan fisik bawaan CharacterBody2D
	move_and_slide()

	# 5. Jalankan animasi yang sesuai
	update_animation(direction)

func update_animation(direction: float) -> void:
	if not is_on_floor():
		if velocity.y < 0.0:
			sprite.play("jump")
		else:
			sprite.play("fall")
	else:
		if direction != 0.0:
			sprite.play("walk")
		else:
			sprite.play("idle")
