extends CharacterBody2D

@export var speed: float = 160.0
@export var jump_velocity: float = -150.0

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var was_on_floor: bool = true
var footstep_timer: float = 0.0
const FOOTSTEP_INTERVAL: float = 0.26

func _ready() -> void:
	collision_mask = 3

func _physics_process(delta: float) -> void:
	# 1. Gravitasi
	if not is_on_floor():
		velocity.y += gravity * delta

	# 2. Lompat (Suara desingan angin lompat / air swish lincah)
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity
		var am = get_node_or_null("/root/AudioManager")
		if am: am.play_sfx("jump", -2.0, 1.2)

	# 3. Gerak kiri / kanan
	var direction := Input.get_axis("move_left", "move_right")
	if direction != 0:
		velocity.x = direction * speed
		sprite.flip_h = (direction < 0)
	else:
		velocity.x = move_toward(velocity.x, 0, speed)

	move_and_slide()

	# 4. Langkah Kaki (Langsung berbunyi di hentakan pertama)
	if is_on_floor() and direction != 0:
		footstep_timer -= delta
		if footstep_timer <= 0.0:
			footstep_timer = FOOTSTEP_INTERVAL
			var am = get_node_or_null("/root/AudioManager")
			if am and am.has_method("play_footstep"):
				am.play_footstep()
	else:
		footstep_timer = 0.0

	# 5. Mendarat Tubuh Manusia (Body Thud empuk)
	if not was_on_floor and is_on_floor():
		var am = get_node_or_null("/root/AudioManager")
		if am: am.play_sfx("land", 4.0, 1.0)

	was_on_floor = is_on_floor()

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
