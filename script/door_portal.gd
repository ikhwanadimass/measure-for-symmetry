extends Area2D

# Batas kesempatan masuk ke Ruang 2
const MAX_MASUK: int = 3
var jumlah_masuk: int = 0

var player_near: CharacterBody2D = null

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _unhandled_input(event: InputEvent) -> void:
	if player_near and event.is_action_pressed("interact"):
		teleport_player()

func teleport_player() -> void:
	var camera = player_near.get_node_or_null("Camera2D") as Camera2D
	var phone = get_tree().current_scene.find_child("Smartphone", true, false)
	
	# 1. Pindah dari Ruang 1 (kiri) ke Ruang 2 (kanan)
	if player_near.global_position.x < 0:
		if jumlah_masuk >= MAX_MASUK:
			return
		
		jumlah_masuk += 1
		
		player_near.global_position.x = 40.0
		if camera:
			camera.limit_left = 4
			camera.limit_right = 204
			
		# Mulai hitung mundur 120 detik di Ruang 2
		if phone and phone.has_method("mulai_timer_ruang2"):
			phone.mulai_timer_ruang2()
			
		update_interact_prompt()
		
	# 2. Pindah dari Ruang 2 (kanan) kembali ke Ruang 1 (kiri)
	else:
		player_near.global_position.x = -40.0
		if camera:
			camera.limit_left = -204
			camera.limit_right = -4
			
		# Reset waktu ke 02:00 dan hentikan hitungan saat di Ruang 1
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
		
	if player_near.global_position.x < 0:
		if jumlah_masuk >= MAX_MASUK:
			kirim_prompt_ke_hud("TERKUNCI!\n(3/3)")
		else:
			kirim_prompt_ke_hud("[E] PINDAH\n(%d/%d)" % [jumlah_masuk, MAX_MASUK])
	else:
		kirim_prompt_ke_hud("[E] KEMBALI")

func kirim_prompt_ke_hud(pesan: String) -> void:
	var phone = get_tree().current_scene.find_child("Smartphone", true, false)
	if phone and phone.has_method("tampilkan_interaksi"):
		phone.tampilkan_interaksi(pesan)
