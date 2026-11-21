extends CanvasLayer

# ================= PENGATURAN TEKS [F] METERAN =================
# 1. Warna (Bisa ganti angka R, G, B antara 0.0 sampai 1.0, atau pakai Color.RED, Color.YELLOW, dll.)
const WARNA_METERAN_AKTIF = Color(0.30, 0.4, 0.25, 1.0)   # Warna saat F aktif (Hijau)
const WARNA_METERAN_MATI = Color(0.0, 0.0, 0.0, 1.0)       # Warna saat F mati (Hitam)

# 2. Posisi (Geser piksel):
const GESER_X: float = 0.0    # Tambah angka untuk geser KANAN, kurangi untuk KIRI
const GESER_Y: float = 30.0   # Tambah angka untuk geser BAWAH, kurangi untuk ATAS
# ===============================================================

# Asset Emoji
const EMOJI_HAPPY = preload("res://asset/free-emojis-pixelart/emojis-x2-64x64/E1.png")
const EMOJI_NEUTRAL = preload("res://asset/free-emojis-pixelart/emojis-x2-64x64/E50.png")
const EMOJI_SAD = preload("res://asset/free-emojis-pixelart/emojis-x2-64x64/E29.png")

# Node Utama
@onready var dim_overlay: ColorRect = $DimOverlay
@onready var phone_container: Control = $PhoneContainer
@onready var hud_phone_button: TextureButton = $HUDPhoneButton
@onready var interact_label: Label = $HUDPhoneButton/InteractLabel
@onready var timer_label: Label = $TimerLabel
@onready var info_label: Label = $HUDPhoneButton.get_node_or_null("info")

# Layar di dalam HP
@onready var main_menu: VBoxContainer = $PhoneContainer/PhoneFrame/MainMenu
@onready var notes_screen: Control = $PhoneContainer/PhoneFrame/NotesScreen
@onready var result_screen: Control = $PhoneContainer/PhoneFrame/ResultScreen

# Tombol Menu Utama
@onready var btn_finish: TextureButton = $PhoneContainer/PhoneFrame/MainMenu/BtnFinish
@onready var btn_notes: TextureButton = $PhoneContainer/PhoneFrame/MainMenu/BtnNotes
@onready var btn_settings: TextureButton = $PhoneContainer/PhoneFrame/MainMenu/BtnSettings

# Elemen Catatan
@onready var btn_back_notes: Button = $PhoneContainer/PhoneFrame/NotesScreen/BtnBackNotes
@onready var notes_text_edit: TextEdit = $PhoneContainer/PhoneFrame/NotesScreen/NotesTextEdit

# Elemen Hasil Evaluasi
@onready var emoji_rect: TextureRect = $PhoneContainer/PhoneFrame/ResultScreen/EmojiRect
@onready var result_label: Label = $PhoneContainer/PhoneFrame/ResultScreen/ResultLabel
@onready var btn_close_result: Button = $PhoneContainer/PhoneFrame/ResultScreen/BtnCloseResult

var meteran_label: Label = null
var is_open: bool = false
var waktu_sisa: float = 120.0
var timer_berjalan: bool = false

var status_evaluasi: String = ""
var sudah_selesai_evaluasi: bool = false

func _ready() -> void:
	hud_phone_button.pressed.connect(_on_hud_phone_button_pressed)
	btn_finish.pressed.connect(_on_btn_finish_pressed)
	btn_notes.pressed.connect(_on_btn_notes_pressed)
	btn_settings.pressed.connect(_on_btn_settings_pressed)
	btn_back_notes.pressed.connect(_on_btn_back_notes_pressed)
	btn_close_result.pressed.connect(_on_btn_close_result_pressed)
	
	setup_meteran_label()
	close_phone()
	tampilkan_interaksi("")
	reset_dan_hentikan_timer()

func setup_meteran_label() -> void:
	if not info_label:
		return
	info_label.text = "[M] SELESAI\n[N] NOTE"
	
	meteran_label = Label.new()
	meteran_label.name = "MeteranInfoLabel"
	meteran_label.text = "[F] METERAN"
	# Atur posisi berdasarkan offset info_label + geseran kamu
	meteran_label.position = Vector2(info_label.offset_left + GESER_X, info_label.offset_top + GESER_Y)
	meteran_label.add_theme_font_size_override("font_size", 8)
	meteran_label.add_theme_color_override("font_color", WARNA_METERAN_MATI)
	
	if info_label.has_theme_font_override("font"):
		meteran_label.add_theme_font_override("font", info_label.get_theme_font("font"))
		
	info_label.get_parent().add_child(meteran_label)

func set_meteran_aktif(aktif: bool) -> void:
	if meteran_label:
		if aktif:
			meteran_label.add_theme_color_override("font_color", WARNA_METERAN_AKTIF)
		else:
			meteran_label.add_theme_color_override("font_color", WARNA_METERAN_MATI)

func _process(delta: float) -> void:
	if timer_berjalan and not is_open:
		waktu_sisa -= delta
		if waktu_sisa <= 0.0:
			waktu_sisa = 0.0
			timer_berjalan = false
			kembalikan_ke_ruang1()
			buka_selesai_langsung()
		update_timer_display()

func update_timer_display() -> void:
	if timer_label:
		var menit: int = int(waktu_sisa) / 60
		var detik: int = int(waktu_sisa) % 60
		timer_label.text = "%02d:%02d" % [menit, detik]
		
		if waktu_sisa <= 30.0 and timer_berjalan:
			timer_label.add_theme_color_override("font_color", Color(0.9, 0.2, 0.2, 1.0))
		else:
			timer_label.add_theme_color_override("font_color", Color(0.0, 0.0, 0.0, 1.0))

func mulai_timer_ruang2() -> void:
	waktu_sisa = 120.0
	timer_berjalan = true
	update_timer_display()

func reset_dan_hentikan_timer() -> void:
	waktu_sisa = 120.0
	timer_berjalan = false
	update_timer_display()

func kembalikan_ke_ruang1() -> void:
	var current_scene = get_tree().current_scene
	var player = current_scene.find_child("Player", true, false)
	if player:
		player.global_position.x = -40.0
		var camera = player.get_node_or_null("Camera2D") as Camera2D
		if camera:
			camera.limit_left = -204
			camera.limit_right = -4

func _input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
		
	# 1. PENGAMAN NOTEPAD:
	if notes_screen.visible and notes_text_edit.has_focus():
		if event.keycode == KEY_TAB or event.keycode == KEY_ESCAPE:
			toggle_phone()
			get_viewport().set_input_as_handled()
		return

	# 2. SHORTCUT ENTER / SPACE DI LAYAR HASIL:
	if is_open and result_screen.visible:
		if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER or event.keycode == KEY_SPACE:
			_on_btn_close_result_pressed()
			get_viewport().set_input_as_handled()
			return

	# 3. SHORTCUT UTAMA:
	if event.keycode == KEY_TAB:
		toggle_phone()
		get_viewport().set_input_as_handled()
		return
	elif event.keycode == KEY_ESCAPE and is_open:
		close_phone()
		get_viewport().set_input_as_handled()
		return
	elif event.keycode == KEY_N:
		buka_catatan_langsung()
		get_viewport().set_input_as_handled()
		return
	elif event.keycode == KEY_M:
		buka_selesai_langsung()
		get_viewport().set_input_as_handled()
		return

	# 4. Navigasi W dan S:
	if is_open and main_menu.visible:
		if event.keycode == KEY_W:
			var focused = get_viewport().gui_get_focus_owner()
			if focused and focused is Control:
				var prev_btn = focused.find_prev_valid_focus()
				if prev_btn:
					prev_btn.grab_focus()
			else:
				btn_finish.grab_focus()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_S:
			var focused = get_viewport().gui_get_focus_owner()
			if focused and focused is Control:
				var next_btn = focused.find_next_valid_focus()
				if next_btn:
					next_btn.grab_focus()
			else:
				btn_finish.grab_focus()
			get_viewport().set_input_as_handled()

func toggle_phone() -> void:
	if is_open:
		close_phone()
	else:
		open_phone()

func open_phone() -> void:
	is_open = true
	dim_overlay.visible = true
	phone_container.visible = true
	get_tree().paused = true
	show_screen("main")
	btn_finish.grab_focus()

func close_phone() -> void:
	is_open = false
	dim_overlay.visible = false
	phone_container.visible = false
	get_tree().paused = false

func show_screen(screen_name: String) -> void:
	main_menu.visible = (screen_name == "main")
	notes_screen.visible = (screen_name == "notes")
	result_screen.visible = (screen_name == "result")

func buka_catatan_langsung() -> void:
	if not is_open:
		is_open = true
		dim_overlay.visible = true
		phone_container.visible = true
		get_tree().paused = true
	show_screen("notes")
	notes_text_edit.grab_focus()

func buka_selesai_langsung() -> void:
	if not is_open:
		is_open = true
		dim_overlay.visible = true
		phone_container.visible = true
		get_tree().paused = true
	_on_btn_finish_pressed()

func _on_hud_phone_button_pressed() -> void:
	toggle_phone()

func _on_btn_notes_pressed() -> void:
	buka_catatan_langsung()

func _on_btn_back_notes_pressed() -> void:
	show_screen("main")
	btn_notes.grab_focus()

func _on_btn_settings_pressed() -> void:
	print("Pengaturan diklik")

func _on_btn_close_result_pressed() -> void:
	if status_evaluasi == "game_over":
		get_tree().paused = false
		get_tree().call_deferred("reload_current_scene")
	else:
		close_phone()

func _on_btn_finish_pressed() -> void:
	if sudah_selesai_evaluasi:
		show_screen("result")
		return

	var current_scene = get_tree().current_scene
	var checker = current_scene.find_child("SymmetryChecker", true, false)
	
	if checker and checker.has_method("hitung_evaluasi"):
		var hasil = checker.hitung_evaluasi()
		tampilkan_hasil(hasil)
	else:
		tampilkan_hasil({
			"grade": "happy",
			"status": "success",
			"text": "BERHASIL!\n(1/1)"
		})

func tampilkan_hasil(hasil: Dictionary) -> void:
	sudah_selesai_evaluasi = true
	status_evaluasi = hasil.get("status", "game_over")
	var grade = hasil.get("grade", "happy")
	
	match grade:
		"happy":
			emoji_rect.texture = EMOJI_HAPPY
			btn_close_result.text = "[Enter] Lanjut"
		"neutral":
			emoji_rect.texture = EMOJI_NEUTRAL
			btn_close_result.text = "[Enter] Lanjut"
		"sad":
			emoji_rect.texture = EMOJI_SAD
			btn_close_result.text = "[Enter] Ulangi"
			
	result_label.text = hasil.get("text", "Evaluasi Selesai")
	show_screen("result")

func tampilkan_interaksi(pesan: String) -> void:
	if interact_label:
		if pesan == "":
			interact_label.text = ""
			interact_label.visible = false
		else:
			interact_label.text = pesan
			interact_label.visible = true
