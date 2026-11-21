extends Area2D

var player_near: CharacterBody2D = null

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _unhandled_input(event: InputEvent) -> void:
	if player_near and event.is_action_pressed("interact"):
		teleport_player()

func teleport_player() -> void:
	var camera = player_near.get_node_or_null("Camera2D") as Camera2D
	
	# Jika pemain di Ruang 1 (sisi kiri), pindah ke Ruang 2 (sisi kanan)
	if player_near.global_position.x < 0:
		player_near.global_position.x = 40.0
		if camera:
			camera.limit_left = 4
			camera.limit_right = 204
	# Jika pemain di Ruang 2 (sisi kanan), pindah ke Ruang 1 (sisi kiri)
	else:
		player_near.global_position.x = -40.0
		if camera:
			camera.limit_left = -204
			camera.limit_right = -4

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		player_near = body

func _on_body_exited(body: Node2D) -> void:
	if body == player_near:
		player_near = null
