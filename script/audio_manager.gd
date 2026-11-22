extends Node

var bgm_player: AudioStreamPlayer = null
var sfx_dict: Dictionary = {}
var bgm_dict: Dictionary = {}

var bgm_volume_pct: float = 100.0
var sfx_volume_pct: float = 100.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	setup_bgm_player()
	load_audio_assets()
	play_bgm("home")

func setup_bgm_player() -> void:
	bgm_player = AudioStreamPlayer.new()
	bgm_player.name = "BGMPlayer"
	bgm_player.bus = "Master"
	bgm_player.volume_db = -18.0
	add_child(bgm_player)
	bgm_player.finished.connect(_on_bgm_finished)

func load_audio_assets() -> void:
	# 1. BGM: Home (track 7) & Gameplay (track 3)
	bgm_dict["home"] = load("res://asset/music/track 7.wav")
	bgm_dict["game"] = load("res://asset/music/track 3.wav")
	
	# 2. SFX Langkah Kaki Foley
	sfx_dict["step_1"] = load("res://asset/Sound/400 Sounds Pack/Footsteps/foley_footstep_vinyl_1.wav")
	sfx_dict["step_2"] = load("res://asset/Sound/400 Sounds Pack/Footsteps/foley_footstep_vinyl_2.wav")
	sfx_dict["step_3"] = load("res://asset/Sound/400 Sounds Pack/Footsteps/foley_footstep_vinyl_3.wav")
	sfx_dict["step_4"] = load("res://asset/Sound/400 Sounds Pack/Footsteps/foley_footstep_vinyl_4.wav")
	
	# 3. SFX Karakter
	sfx_dict["jump"] = load("res://asset/Sound/400 Sounds Pack/Other/whoosh_1.wav")
	sfx_dict["land"] = load("res://asset/Sound/400 Sounds Pack/Materials/clothing_thud.wav")
	
	# 4. SFX Perabot
	sfx_dict["drag"] = load("res://asset/Sound/96 Extra SFX/wood_scrape_1.wav")
	sfx_dict["drop"] = load("res://asset/Sound/96 Extra SFX/wood_on_wood.wav")
	
	# 5. SFX UI & HP
	sfx_dict["click"] = load("res://asset/Sound/96 Extra SFX/light_switch_on.wav")
	sfx_dict["phone"] = load("res://asset/Sound/400 Sounds Pack/Other/whoosh_1.wav")
	sfx_dict["phone_close"] = load("res://asset/Sound/96 Extra SFX/light_switch_off.wav")
	sfx_dict["measure"] = load("res://asset/Sound/400 Sounds Pack/Card and Board/card_fan.wav")
	sfx_dict["door"] = load("res://asset/Sound/96 Extra SFX/wood_creak_1.wav")
	sfx_dict["note"] = load("res://asset/Sound/96 Extra SFX/page_turn.wav")
	
	# 6. SFX Evaluasi
	sfx_dict["win"] = load("res://asset/Sound/400 Sounds Pack/Musical Effects/xylophone_level_complete.wav")
	sfx_dict["medium"] = load("res://asset/Sound/400 Sounds Pack/Musical Effects/xylophone_chime_positive.wav")
	sfx_dict["game_over"] = load("res://asset/Sound/400 Sounds Pack/Musical Effects/xylophone_defeated.wav")

func set_bgm_volume(pct: float) -> void:
	bgm_volume_pct = clamp(pct, 0.0, 100.0)
	if bgm_player:
		if bgm_volume_pct <= 0.0:
			bgm_player.volume_db = -80.0
		else:
			bgm_player.volume_db = -18.0 + linear_to_db(bgm_volume_pct / 100.0)

func set_sfx_volume(pct: float) -> void:
	sfx_volume_pct = clamp(pct, 0.0, 100.0)

func play_bgm(track_key: String) -> void:
	if not bgm_dict.has(track_key): return
	var stream = bgm_dict[track_key]
	if stream and bgm_player.stream != stream:
		bgm_player.stream = stream
		bgm_player.play()
	elif stream and not bgm_player.playing:
		bgm_player.play()

func _on_bgm_finished() -> void:
	if bgm_player and bgm_player.stream:
		bgm_player.play()

func play_footstep() -> void:
	var idx = randi_range(1, 4)
	play_sfx("step_%d" % idx, 3.0, randf_range(0.95, 1.05))

func play_sfx(sfx_key: String, volume_db: float = 0.0, pitch_scale: float = 1.0) -> void:
	if sfx_volume_pct <= 0.0: return
	if not sfx_dict.has(sfx_key): return
	var stream = sfx_dict[sfx_key] as AudioStream
	if not stream: return
	
	var final_vol = volume_db
	if volume_db == 0.0:
		match sfx_key:
			"click": final_vol = -12.0
			"phone": final_vol = -14.0
			"phone_close": final_vol = -14.0
			"door": final_vol = -3.0
			"note": final_vol = -4.0
			"measure": final_vol = -5.0
			"jump": final_vol = -2.0
			"win": final_vol = -2.0
			"medium": final_vol = -2.0
			"game_over": final_vol = -2.0
	
	final_vol += linear_to_db(sfx_volume_pct / 100.0)
		
	var player = AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = final_vol
	player.pitch_scale = pitch_scale
	player.bus = "Master"
	add_child(player)
	player.play()
	
	player.finished.connect(func():
		player.queue_free()
	)
