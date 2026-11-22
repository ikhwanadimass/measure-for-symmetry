extends Control

@export var target_scene_path: String = "res://scene/Level01.tscn"
@export var fps: float = 24.0 # Kecepatan animasi loading (frame per detik)
@export var min_display_time: float = 2.5 # Waktu minimal animasi tayang (detik)

@onready var texture_rect: TextureRect = $CenterContainer/LoadingTexture
@onready var fade_overlay: ColorRect = $FadeOverlay

var frames: Array[Texture2D] = []
var current_frame_idx: int = 0
var frame_timer: float = 0.0
var elapsed_time: float = 0.0
var is_transitioning: bool = false

func _ready() -> void:
	# 1. Muat otomatis semua 67 frame dari folder aset
	for i in range(67):
		var path = "res://asset/UI/Sprites/7 - Loading Screen/%d.png" % i
		if FileAccess.file_exists(path):
			var tex = load(path) as Texture2D
			if tex:
				frames.append(tex)
	
	print("[LoadingScreen] Total frame animasi yang dimuat: ", frames.size())
	
	if frames.size() > 0:
		texture_rect.texture = frames[0]
	
	# 2. Mulai background loading scene Level 01
	ResourceLoader.load_threaded_request(target_scene_path)
	
	# 3. Fade in dari hitam saat loading screen mulai
	fade_overlay.color = Color.BLACK
	fade_overlay.modulate.a = 1.0
	var tween = create_tween()
	tween.tween_property(fade_overlay, "modulate:a", 0.0, 0.4)

func _process(delta: float) -> void:
	elapsed_time += delta
	
	# Putar frame animasi bergantian
	if frames.size() > 0:
		frame_timer += delta
		var time_per_frame = 1.0 / fps
		if frame_timer >= time_per_frame:
			frame_timer -= time_per_frame
			current_frame_idx = (current_frame_idx + 1) % frames.size()
			texture_rect.texture = frames[current_frame_idx]
	
	# Cek status background loading
	if not is_transitioning:
		var progress: Array = []
		var status = ResourceLoader.load_threaded_get_status(target_scene_path, progress)
		
		# Jika scene selesai dimuat dan durasi minimal animasi sudah tercapai
		if status == ResourceLoader.THREAD_LOAD_LOADED and elapsed_time >= min_display_time:
			is_transitioning = true
			pindah_ke_game()

func pindah_ke_game() -> void:
	# Fade out ke hitam sebelum ganti scene
	var tween = create_tween()
	tween.tween_property(fade_overlay, "modulate:a", 1.0, 0.5)
	await tween.finished
	
	var packed_scene = ResourceLoader.load_threaded_get(target_scene_path) as PackedScene
	if packed_scene:
		get_tree().change_scene_to_packed(packed_scene)
