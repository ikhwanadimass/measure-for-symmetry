extends Area2D

signal portal_requested(from_room: int)

@onready var prompt_label: Label = $PromptLabel

var player_near: CharacterBody2D = null
var input_blocked: bool = false
var current_room_state: int = 1
var entries_remaining_state: int = 3

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	if prompt_label:
		prompt_label.visible = false

func set_input_blocked(blocked: bool) -> void:
	input_blocked = blocked

func _unhandled_input(event: InputEvent) -> void:
	if input_blocked:
		return
	if player_near and event.is_action_pressed("interact"):
		trigger_portal()

func trigger_portal() -> void:
	if player_near == null:
		return
	var from_room: int = 1 if player_near.global_position.x < 0.0 else 2
	portal_requested.emit(from_room)

func teleport_player_to(player: CharacterBody2D, target_room: int, spawn_x: float) -> void:
	if player == null:
		return
	player.global_position.x = spawn_x
	var camera := player.get_node_or_null("Camera2D") as Camera2D
	if camera:
		if target_room == 2:
			camera.limit_left = 4
			camera.limit_right = 204
		else:
			camera.limit_left = -204
			camera.limit_right = -4
		camera.reset_smoothing()

func update_prompt(current_room: int, entries_remaining: int) -> void:
	current_room_state = current_room
	entries_remaining_state = entries_remaining
	if prompt_label == null:
		return
	if current_room == 1:
		if entries_remaining > 0:
			prompt_label.text = "[E] Masuk Ruang 2 (Sisa: %d)" % entries_remaining
		else:
			prompt_label.text = "Kuota Masuk Habis"
	else:
		prompt_label.text = "[E] Kembali ke Ruang 1"
	prompt_label.visible = (player_near != null)

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		player_near = body as CharacterBody2D
		update_prompt(current_room_state, entries_remaining_state)

func _on_body_exited(body: Node2D) -> void:
	if body == player_near:
		player_near = null
		update_prompt(current_room_state, entries_remaining_state)
