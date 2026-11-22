extends Area2D

var jumlah_masuk: int = 0
var player_near: CharacterBody2D = null

func get_max_masuk() -> int:
	var gm = get_node_or_null("/root/GameManager")
	return gm.get_mode_info()["max_masuk"] if gm else 3

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _unhandled_input(event: InputEvent) -> void:
	if player_near and event.is_action_pressed("interact"):
		teleport_player()

func teleport_player() -> void:
	var camera = player_near.get_node_or_null("Camera2D") as Camera2D
	var phone = get_tree().current_scene.find_child("Smartphone", true, false)
	var max_m = get_max_masuk()
	
	# 1. Masuk ke Ruang 2
	if player_near.global_position.x < 0:
		if jumlah_masuk >= max_m:
			return
		
		jumlah_masuk += 1
		player_near.global_position.x = 40.0
		if camera:
			camera.limit_left = 4
			camera.limit_right = 204
			
		if phone and phone.has_method("mulai_timer_ruang2"):
			phone.mulai_timer_ruang2()
			
		update_interact_prompt()
		
	# 2. Kembali ke Ruang 1
	else:
		player_near.global_position.x = -40.0
		if camera:
			camera.limit_left = -204
			camera.limit_right = -4
			
		if phone and phone.has_method("reset_dan_hentikan_timer"):
			phone.reset_dan_hentikan_timer()
			
		update_interact_prompt()

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		player_near = body
		update_interact_prompt()

func _on_body_exited(body: Node2D) -> void:
	if body == player_near:
		player_near = null
		kirim_prompt_ke_hud("")

func update_interact_prompt() -> void:
	if not player_near:
		return
		
	var max_m = get_max_masuk()
	if player_near.global_position.x < 0:
		if max_m >= 999: # Mode Bebas
			kirim_prompt_ke_hud("[E] PINDAH")
		elif jumlah_masuk >= max_m:
			kirim_prompt_ke_hud("TERKUNCI!\n(%d/%d)" % [jumlah_masuk, max_m])
		else:
			kirim_prompt_ke_hud("[E] PINDAH\n(%d/%d)" % [jumlah_masuk, max_m])
	else:
		kirim_prompt_ke_hud("[E] KEMBALI")

func kirim_prompt_ke_hud(pesan: String) -> void:
	var phone = get_tree().current_scene.find_child("Smartphone", true, false)
	if phone and phone.has_method("tampilkan_interaksi"):
		phone.tampilkan_interaksi(pesan)
