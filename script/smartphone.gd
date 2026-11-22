extends CanvasLayer

# ================= PENGATURAN UKURAN FONT & TEKS =================
const UKURAN_FONT_FORM: int = 11
const UKURAN_FONT_LABEL: int = 11
const UKURAN_FONT_DESC: int = 9

# Pengaturan teks [F] METERAN
const WARNA_METERAN_AKTIF = Color(0.15, 0.85, 0.25, 1.0)
const WARNA_METERAN_MATI = Color(0.0, 0.0, 0.0, 1.0)
const GESER_X: float = 0.0
const GESER_Y: float = 44.0
# =================================================================

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

# Layar-Layar di dalam HP
@onready var phone_frame: TextureRect = $PhoneContainer/PhoneFrame
@onready var main_menu: VBoxContainer = $PhoneContainer/PhoneFrame.get_node_or_null("MainMenu")
@onready var play_menu: VBoxContainer = $PhoneContainer/PhoneFrame.get_node_or_null("PlayMenu")
@onready var new_game_screen: Control = $PhoneContainer/PhoneFrame.get_node_or_null("NewGameScreen")
@onready var level_select_screen: Control = $PhoneContainer/PhoneFrame.get_node_or_null("LevelSelectScreen")
@onready var notes_screen: Control = $PhoneContainer/PhoneFrame.get_node_or_null("NotesScreen")
@onready var result_screen: Control = $PhoneContainer/PhoneFrame.get_node_or_null("ResultScreen")

# Tombol Menu Utama Awal
@onready var btn_play: TextureButton = $PhoneContainer/PhoneFrame.get_node_or_null("MainMenu/BtnPlay")
@onready var btn_tutorial: TextureButton = $PhoneContainer/PhoneFrame.get_node_or_null("MainMenu/BtnTutorial")
@onready var btn_settings: TextureButton = $PhoneContainer/PhoneFrame.get_node_or_null("MainMenu/BtnSettings")
@onready var btn_load_progress: TextureButton = $PhoneContainer/PhoneFrame.get_node_or_null("MainMenu/BtnLoadProgress")
@onready var btn_quit: TextureButton = $PhoneContainer/PhoneFrame.get_node_or_null("MainMenu/BtnQuit")

# Tombol di PlayMenu
@onready var btn_continue_game: TextureButton = $PhoneContainer/PhoneFrame.get_node_or_null("PlayMenu/BtnContinueGame")
@onready var btn_new_game: TextureButton = $PhoneContainer/PhoneFrame.get_node_or_null("PlayMenu/BtnNewGame")
@onready var btn_select_level: TextureButton = $PhoneContainer/PhoneFrame.get_node_or_null("PlayMenu/BtnSelectLevel")
@onready var btn_back_play: TextureButton = $PhoneContainer/PhoneFrame.get_node_or_null("PlayMenu/BtnBackPlay")

# Elemen Form NewGameScreen
@onready var form_container: VBoxContainer = $PhoneContainer/PhoneFrame.get_node_or_null("NewGameScreen/FormContainer")
@onready var input_save_name: LineEdit = $PhoneContainer/PhoneFrame.get_node_or_null("NewGameScreen/FormContainer/InputSaveName")
@onready var option_mode: OptionButton = $PhoneContainer/PhoneFrame.get_node_or_null("NewGameScreen/FormContainer/OptionMode")
@onready var btn_start_new_game: Button = $PhoneContainer/PhoneFrame.get_node_or_null("NewGameScreen/FormContainer/BtnStartNewGame")
@onready var btn_back_new_game: Button = $PhoneContainer/PhoneFrame.get_node_or_null("NewGameScreen/BtnBackNewGame")

# Elemen LevelSelectScreen
@onready var btn_level_1: TextureButton = $PhoneContainer/PhoneFrame.get_node_or_null("LevelSelectScreen/BtnLevel1")
@onready var btn_back_level_select: Button = $PhoneContainer/PhoneFrame.get_node_or_null("LevelSelectScreen/BtnBackLevelSelect")

# Elemen Catatan & Hasil
@onready var btn_back_notes: Button = $PhoneContainer/PhoneFrame.get_node_or_null("NotesScreen/BtnBackNotes")
@onready var notes_text_edit: TextEdit = $PhoneContainer/PhoneFrame.get_node_or_null("NotesScreen/NotesTextEdit")
@onready var emoji_rect: TextureRect = $PhoneContainer/PhoneFrame.get_node_or_null("ResultScreen/EmojiRect")
@onready var result_label: Label = $PhoneContainer/PhoneFrame.get_node_or_null("ResultScreen/ResultLabel")
@onready var btn_close_result: Button = $PhoneContainer/PhoneFrame.get_node_or_null("ResultScreen/BtnCloseResult")

# Menu Dalam Game (In-Game Menu)
var in_game_menu: VBoxContainer = null
var btn_ig_resume: TextureButton = null
var btn_ig_notes: TextureButton = null
var btn_ig_finish: TextureButton = null
var btn_ig_main_menu: TextureButton = null

var label_mode_desc: Label = null
var meteran_label: Label = null
var is_open: bool = false
var is_game_started: bool = false
var waktu_sisa: float = 120.0
var timer_berjalan: bool = false
var status_evaluasi: String = ""
var sudah_selesai_evaluasi: bool = false
var _is_transitioning_level: bool = false
var _level_unlocked_for_result: bool = false
var level_buttons: Dictionary[int, TextureButton] = {}

func _ready() -> void:
	perbaiki_teks_tombol_otomatis()
	setup_in_game_menu_otomatis()
	setup_level_select_otomatis()
	hubungkan_semua_tombol()
	setup_pilihan_mode_rapi()
	setup_meteran_label()
	
	# CEK APAKAH PEMAIN SEDANG MENGULANG LEVEL (REPLAY):
	var gm = get_node_or_null("/root/GameManager")
	if gm and gm.is_replaying:
		gm.is_replaying = false
		mulai_permainan()
		return
		
	# KONDISI AWAL GAME BARU DIBUKA:
	is_game_started = false
	set_hud_visibilitas(false)
	tampilkan_interaksi("")
	
	open_phone()
	show_screen("main")

func perbaiki_teks_tombol_otomatis() -> void:
	set_btn_label(btn_continue_game, "Lanjutkan")
	set_btn_label(btn_new_game, "Mulai Baru")
	set_btn_label(btn_select_level, "Pilih Level")
	set_btn_label(btn_back_play, "Kembali")

func set_btn_label(btn: Control, teks: String) -> void:
	if btn:
		for child in btn.get_children():
			if child is Label:
				child.text = teks
				return

func setup_in_game_menu_otomatis() -> void:
	if not phone_frame or in_game_menu:
		return
		
	in_game_menu = VBoxContainer.new()
	in_game_menu.name = "InGameMenu"
	in_game_menu.layout_mode = 1
	in_game_menu.anchors_preset = Control.PRESET_CENTER
	in_game_menu.offset_left = -71.0
	in_game_menu.offset_top = -100.0
	in_game_menu.offset_right = 69.0
	in_game_menu.offset_bottom = 50.0
	in_game_menu.grow_horizontal = Control.GROW_DIRECTION_BOTH
	in_game_menu.grow_vertical = Control.GROW_DIRECTION_BOTH
	in_game_menu.add_theme_constant_override("separation", 10)
	
	btn_ig_resume = btn_play.duplicate() as TextureButton
	set_btn_label(btn_ig_resume, "Lanjut Main")
	btn_ig_resume.pressed.connect(close_phone)
	in_game_menu.add_child(btn_ig_resume)
	
	btn_ig_notes = btn_play.duplicate() as TextureButton
	set_btn_label(btn_ig_notes, "Catatan [N]")
	btn_ig_notes.pressed.connect(buka_catatan_langsung)
	in_game_menu.add_child(btn_ig_notes)
	
	btn_ig_finish = btn_play.duplicate() as TextureButton
	set_btn_label(btn_ig_finish, "Selesai Misi [M]")
	btn_ig_finish.pressed.connect(buka_selesai_langsung)
	in_game_menu.add_child(btn_ig_finish)
	
	btn_ig_main_menu = btn_play.duplicate() as TextureButton
	set_btn_label(btn_ig_main_menu, "Menu Utama")
	btn_ig_main_menu.pressed.connect(kembali_ke_judul)
	in_game_menu.add_child(btn_ig_main_menu)
	
	phone_frame.add_child(in_game_menu)
	in_game_menu.visible = false

func kembali_ke_judul() -> void:
	is_game_started = false
	set_hud_visibilitas(false)
	show_screen("main")

func set_hud_visibilitas(tampil: bool) -> void:
	if hud_phone_button:
		hud_phone_button.visible = tampil
	if timer_label:
		timer_label.visible = tampil

func setup_pilihan_mode_rapi() -> void:
	if form_container:
		form_container.offset_left = -37.0
		form_container.offset_right = 77.0
		form_container.offset_top = -50.0
		form_container.offset_bottom = 85.0
		form_container.add_theme_constant_override("separation", 5)
		
		for child in form_container.get_children():
			if child is Label and child != label_mode_desc:
				child.add_theme_font_size_override("font_size", UKURAN_FONT_LABEL)
				child.add_theme_color_override("font_color", Color(0, 0, 0, 1))

	if input_save_name:
		input_save_name.add_theme_font_size_override("font_size", UKURAN_FONT_FORM)
		input_save_name.custom_minimum_size = Vector2(114, 24)
		
	if option_mode:
		option_mode.clear()
		option_mode.add_theme_font_size_override("font_size", UKURAN_FONT_FORM)
		option_mode.custom_minimum_size = Vector2(114, 26)
		option_mode.add_item("Ringan", 0)
		option_mode.add_item("Biasa", 1)
		option_mode.add_item("Hard", 2)
		option_mode.add_item("Bebas", 3)
		option_mode.selected = 1
		if not option_mode.item_selected.is_connected(_on_mode_item_selected):
			option_mode.item_selected.connect(_on_mode_item_selected)

	if form_container and not label_mode_desc:
		label_mode_desc = Label.new()
		label_mode_desc.name = "ModeDescLabel"
		label_mode_desc.add_theme_font_size_override("font_size", UKURAN_FONT_DESC)
		label_mode_desc.add_theme_color_override("font_color", Color(0.25, 0.25, 0.25, 1.0))
		label_mode_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		form_container.add_child(label_mode_desc)
		form_container.move_child(label_mode_desc, option_mode.get_index() + 1)
		_update_mode_desc(1)
		
	if btn_start_new_game:
		btn_start_new_game.add_theme_font_size_override("font_size", UKURAN_FONT_FORM)
		btn_start_new_game.custom_minimum_size = Vector2(114, 26)

func _on_mode_item_selected(index: int) -> void:
	_update_mode_desc(index)

func _update_mode_desc(index: int) -> void:
	if not label_mode_desc: return
	match index:
		0: label_mode_desc.text = "3 Menit | 5x Masuk"
		1: label_mode_desc.text = "2 Menit | 3x Masuk"
		2: label_mode_desc.text = "1 Menit | 2x Masuk"
		3: label_mode_desc.text = "Tanpa Batas Waktu & Masuk"

func hubungkan_semua_tombol() -> void:
	if hud_phone_button: hud_phone_button.pressed.connect(_on_hud_phone_button_pressed)
	if btn_play: btn_play.pressed.connect(_on_btn_play_pressed)
	if btn_tutorial: btn_tutorial.pressed.connect(_on_btn_tutorial_pressed)
	if btn_settings: btn_settings.pressed.connect(_on_btn_settings_pressed)
	if btn_load_progress: btn_load_progress.pressed.connect(_on_btn_load_progress_pressed)
	if btn_quit: btn_quit.pressed.connect(func(): get_tree().quit())
	
	if btn_continue_game: btn_continue_game.pressed.connect(_on_btn_continue_game_pressed)
	if btn_new_game: btn_new_game.pressed.connect(_on_btn_new_game_pressed)
	if btn_select_level: btn_select_level.pressed.connect(func(): show_screen("level_select"))
	if btn_back_play: btn_back_play.pressed.connect(func(): show_screen("main"))
	
	if btn_start_new_game: btn_start_new_game.pressed.connect(_on_btn_start_new_game_pressed)
	if btn_back_new_game: btn_back_new_game.pressed.connect(func(): show_screen("play_menu"))
	
	if btn_level_1: btn_level_1.pressed.connect(_on_btn_level_1_pressed)
	if btn_back_level_select: btn_back_level_select.pressed.connect(func(): show_screen("play_menu"))
	
	if btn_back_notes: btn_back_notes.pressed.connect(func(): show_screen("in_game" if is_game_started else "main"))
	if btn_close_result: btn_close_result.pressed.connect(_on_btn_close_result_pressed)

# ===== AKSI TOMBOL MENU =====
func _on_btn_play_pressed() -> void:
	show_screen("play_menu")
	var gm = get_node_or_null("/root/GameManager")
	var ada_save = gm.has_save if gm else false
	
	# Tombol Lanjutkan & Pilih Level hanya tampil jika sudah ada save:
	if btn_continue_game:
		btn_continue_game.visible = ada_save
	if btn_select_level:
		btn_select_level.visible = ada_save
	
	if ada_save and btn_continue_game:
		btn_continue_game.grab_focus()
	elif btn_new_game:
		btn_new_game.grab_focus()

func _on_btn_new_game_pressed() -> void:
	show_screen("new_game")
	if input_save_name:
		input_save_name.grab_focus()

func _masuk_level_bersih(level_num: int) -> void:
	if _is_transitioning_level:
		return
	_is_transitioning_level = true

	var gm = get_node_or_null("/root/GameManager")
	if gm and gm.has_method("load_level"):
		gm.load_level(level_num, true)
	else:
		get_tree().paused = false
		get_tree().call_deferred("reload_current_scene")

func _on_btn_start_new_game_pressed() -> void:
	var nama = input_save_name.text if input_save_name else "Player 1"
	var mode = option_mode.selected if option_mode else 1
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.buat_save_baru(nama, mode)

	_masuk_level_bersih(1)

func _on_btn_continue_game_pressed() -> void:
	var gm = get_node_or_null("/root/GameManager")
	var level_target: int = int(gm.current_level) if gm else 1
	_masuk_level_bersih(level_target)

func setup_level_select_otomatis() -> void:
	if not level_select_screen or not btn_level_1:
		return
	if not level_buttons.is_empty():
		return

	var gm = get_node_or_null("/root/GameManager")
	var max_level: int = gm.get_max_level() if (gm and gm.has_method("get_max_level")) else 5

	level_buttons[1] = btn_level_1
	set_btn_label(btn_level_1, "Level 1")

	var base_top: float = btn_level_1.offset_top
	var btn_height: float = maxf(20.0, btn_level_1.offset_bottom - btn_level_1.offset_top)
	var gap: float = 6.0
	var insert_idx: int = btn_level_1.get_index() + 1

	for lvl in range(2, max_level + 1):
		var btn_lvl := btn_level_1.duplicate() as TextureButton
		if not btn_lvl:
			continue
		btn_lvl.name = "BtnLevel%d" % lvl
		var top_y: float = base_top + float(lvl - 1) * (btn_height + gap)
		btn_lvl.offset_left = btn_level_1.offset_left
		btn_lvl.offset_right = btn_level_1.offset_right
		btn_lvl.offset_top = top_y
		btn_lvl.offset_bottom = top_y + btn_height
		set_btn_label(btn_lvl, "Level %d" % lvl)
		btn_lvl.pressed.connect(_on_btn_level_pressed.bind(lvl))
		level_select_screen.add_child(btn_lvl)
		level_select_screen.move_child(btn_lvl, insert_idx)
		insert_idx += 1
		level_buttons[lvl] = btn_lvl

	update_level_select_buttons()

func update_level_select_buttons() -> void:
	var gm = get_node_or_null("/root/GameManager")
	var unlocked: int = int(gm.unlocked_level) if gm else 1
	for lvl: int in level_buttons:
		var btn: TextureButton = level_buttons[lvl]
		if not is_instance_valid(btn):
			continue
		var is_unlocked: bool = lvl <= unlocked
		btn.disabled = not is_unlocked
		btn.focus_mode = Control.FOCUS_ALL if is_unlocked else Control.FOCUS_NONE
		btn.modulate = Color(1.0, 1.0, 1.0, 1.0) if is_unlocked else Color(0.55, 0.55, 0.55, 0.75)
		set_btn_label(btn, ("Level %d" % lvl) if is_unlocked else ("Level %d [X]" % lvl))

func _on_btn_level_pressed(level_num: int) -> void:
	var gm = get_node_or_null("/root/GameManager")
	var unlocked: int = int(gm.unlocked_level) if gm else 1
	if level_num > unlocked:
		return
	_masuk_level_bersih(level_num)

func _on_btn_level_1_pressed() -> void:
	_on_btn_level_pressed(1)

func mulai_permainan() -> void:
	is_game_started = true
	set_hud_visibilitas(true)
	close_phone()
	reset_dan_hentikan_timer()

func _on_btn_tutorial_pressed() -> void:
	print("Tutorial: Amati Ruang 1 dengan meteran [F], lalu tata Ruang 2 secara simetris!")

func _on_btn_settings_pressed() -> void:
	print("Pengaturan diklik")

func _on_btn_load_progress_pressed() -> void:
	print("Load Progress diklik")

# ===== PENGELOLA LAYAR & FOKUS KEYBOARD =====
func show_screen(screen_name: String) -> void:
	if main_menu: main_menu.visible = (screen_name == "main")
	if play_menu: play_menu.visible = (screen_name == "play_menu")
	if new_game_screen: new_game_screen.visible = (screen_name == "new_game")
	if level_select_screen:
		level_select_screen.visible = (screen_name == "level_select")
		if screen_name == "level_select":
			update_level_select_buttons()
	if notes_screen: notes_screen.visible = (screen_name == "notes")
	if result_screen: result_screen.visible = (screen_name == "result")
	if in_game_menu: in_game_menu.visible = (screen_name == "in_game")
	
	call_deferred("_atur_fokus_layar", screen_name)

func _atur_fokus_layar(screen_name: String) -> void:
	if not is_inside_tree():
		return
	match screen_name:
		"main":
			if btn_play: btn_play.grab_focus()
		"play_menu":
			if btn_continue_game and btn_continue_game.visible:
				btn_continue_game.grab_focus()
			elif btn_new_game:
				btn_new_game.grab_focus()
		"new_game":
			if input_save_name: input_save_name.grab_focus()
		"level_select":
			var gm = get_node_or_null("/root/GameManager")
			var unlocked: int = int(gm.unlocked_level) if gm else 1
			var active_lvl: int = int(gm.current_level) if gm else 1
			var preferred_lvl: int = clampi(active_lvl, 1, unlocked)
			var focus_btn: TextureButton = level_buttons.get(preferred_lvl, btn_level_1) as TextureButton
			if focus_btn and focus_btn.is_inside_tree() and not focus_btn.disabled:
				focus_btn.grab_focus()
			elif btn_level_1 and btn_level_1.is_inside_tree():
				btn_level_1.grab_focus()
		"in_game":
			if btn_ig_resume: btn_ig_resume.grab_focus()
		"result":
			if btn_close_result: btn_close_result.grab_focus()

func toggle_phone() -> void:
	if not is_game_started:
		return
	if is_open:
		close_phone()
	else:
		open_phone()

func open_phone() -> void:
	is_open = true
	dim_overlay.visible = true
	phone_container.visible = true
	get_tree().paused = true
	
	if is_game_started:
		show_screen("in_game")
	else:
		show_screen("main")

func close_phone() -> void:
	is_open = false
	dim_overlay.visible = false
	phone_container.visible = false
	get_tree().paused = false

# ===== NAVIGASI KEYBOARD W / S / PANAH / ENTER =====
func _input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
		
	# 1. SHORTCUT ENTER / SPACE DI LAYAR HASIL EVALUASI
	if is_open and result_screen and result_screen.visible:
		if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER or event.keycode == KEY_SPACE:
			_on_btn_close_result_pressed()
			get_viewport().set_input_as_handled()
			return

	# 2. Tombol TAB (Buka/Tutup HP saat main)
	if event.keycode == KEY_TAB:
		if is_game_started:
			toggle_phone()
			get_viewport().set_input_as_handled()
		return
		
	# 3. Shortcut Cepat saat HP tertutup
	if not is_open:
		if event.keycode == KEY_N and is_game_started:
			buka_catatan_langsung()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_M and is_game_started:
			buka_selesai_langsung()
			get_viewport().set_input_as_handled()
		return

	# 4. Navigasi W / S / Panah Atas / Bawah
	var is_typing = (input_save_name and input_save_name.has_focus()) or (notes_screen and notes_screen.visible and notes_text_edit.has_focus())
	
	if is_open and not is_typing:
		if event.keycode == KEY_W or event.keycode == KEY_UP:
			var focused = get_viewport().gui_get_focus_owner()
			if focused and focused is Control:
				var prev_btn = focused.find_prev_valid_focus()
				if prev_btn: prev_btn.grab_focus()
			get_viewport().set_input_as_handled()
			return
		elif event.keycode == KEY_S or event.keycode == KEY_DOWN:
			var focused = get_viewport().gui_get_focus_owner()
			if focused and focused is Control:
				var next_btn = focused.find_next_valid_focus()
				if next_btn: next_btn.grab_focus()
			get_viewport().set_input_as_handled()
			return

	# 5. Tombol ESC untuk Kembali
	if event.keycode == KEY_ESCAPE and is_open:
		if new_game_screen and new_game_screen.visible:
			show_screen("play_menu")
		elif level_select_screen and level_select_screen.visible:
			show_screen("play_menu")
		elif play_menu and play_menu.visible:
			show_screen("main")
		elif notes_screen and notes_screen.visible:
			show_screen("in_game" if is_game_started else "main")
		elif in_game_menu and in_game_menu.visible:
			close_phone()
		elif is_game_started:
			close_phone()
		get_viewport().set_input_as_handled()

func buka_catatan_langsung() -> void:
	open_phone()
	show_screen("notes")
	if notes_text_edit: notes_text_edit.grab_focus()

func buka_selesai_langsung() -> void:
	open_phone()
	_evaluasi_misi()

func _evaluasi_misi() -> void:
	var checker = get_tree().current_scene.find_child("SymmetryChecker", true, false)
	if checker and checker.has_method("hitung_evaluasi"):
		var hasil = checker.hitung_evaluasi()
		tampilkan_hasil(hasil)

func tampilkan_hasil(hasil: Dictionary) -> void:
	sudah_selesai_evaluasi = true
	_level_unlocked_for_result = false
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
	
	if btn_close_result:
		btn_close_result.grab_focus()

func _on_btn_close_result_pressed() -> void:
	if _is_transitioning_level:
		return

	var gm = get_node_or_null("/root/GameManager")
	if status_evaluasi == "game_over":
		_is_transitioning_level = true
		# Ulangi Level: Muat ulang scene dan LANGSUNG main (tidak dilempar ke menu awal)
		if gm and gm.has_method("retry_current_level"):
			gm.retry_current_level()
		else:
			if gm:
				gm.is_replaying = true
			get_tree().paused = false
			get_tree().call_deferred("reload_current_scene")
	else:
		# Berhasil / Lulus: Tentukan level aktif sekarang sebelum unlock berikutnya
		var active_level: int = int(gm.current_level) if gm else 1
		var tree := get_tree()
		if tree and tree.current_scene:
			var spawner := tree.current_scene.find_child("Room2Spawner", true, false)
			if spawner and spawner.has_method("get_active_level"):
				active_level = int(spawner.call("get_active_level"))

		if gm:
			gm.current_level = active_level
		if not _level_unlocked_for_result:
			_level_unlocked_for_result = true
			if gm:
				gm.buka_level_berikutnya()

		var next_level: int = active_level + 1
		if gm and gm.has_method("has_level") and gm.has_level(next_level):
			_masuk_level_bersih(next_level)
		else:
			update_level_select_buttons()
			show_screen("level_select")

# ===== SISTEM TIMER & MODE =====
func mulai_timer_ruang2() -> void:
	var gm = get_node_or_null("/root/GameManager")
	var durasi = gm.get_mode_info()["waktu"] if gm else 120.0
	
	if durasi <= 0.0:
		timer_berjalan = false
		if timer_label: timer_label.text = "MODE BEBAS"
	else:
		waktu_sisa = durasi
		timer_berjalan = true
		update_timer_display()

func reset_dan_hentikan_timer() -> void:
	var gm = get_node_or_null("/root/GameManager")
	var durasi = gm.get_mode_info()["waktu"] if gm else 120.0
	timer_berjalan = false
	if durasi <= 0.0:
		if timer_label: timer_label.text = "MODE BEBAS"
	else:
		waktu_sisa = durasi
		update_timer_display()

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

func kembalikan_ke_ruang1() -> void:
	var player = get_tree().current_scene.find_child("Player", true, false)
	if player:
		player.global_position.x = -40.0
		var camera = player.get_node_or_null("Camera2D") as Camera2D
		if camera:
			camera.limit_left = -204
			camera.limit_right = -4

func setup_meteran_label() -> void:
	if not info_label: return
	info_label.text = "[M] SELESAI\n[N] NOTE"
	
	meteran_label = Label.new()
	meteran_label.name = "MeteranInfoLabel"
	meteran_label.text = "[F] METERAN"
	meteran_label.position = Vector2(info_label.offset_left + GESER_X, info_label.offset_top + GESER_Y)
	
	var ukuran = 15
	if info_label.has_theme_font_size_override("font_size"):
		ukuran = info_label.get_theme_font_size("font_size")
	meteran_label.add_theme_font_size_override("font_size", ukuran)
	
	if info_label.has_theme_font_override("font"):
		meteran_label.add_theme_font_override("font", info_label.get_theme_font("font"))
		
	meteran_label.add_theme_color_override("font_color", WARNA_METERAN_MATI)
	info_label.get_parent().add_child(meteran_label)

func set_meteran_aktif(aktif: bool) -> void:
	if meteran_label:
		if aktif:
			meteran_label.add_theme_color_override("font_color", WARNA_METERAN_AKTIF)
		else:
			meteran_label.add_theme_color_override("font_color", WARNA_METERAN_MATI)

func tampilkan_interaksi(pesan: String) -> void:
	if interact_label:
		if pesan == "":
			interact_label.text = ""
			interact_label.visible = false
		else:
			interact_label.text = pesan
			interact_label.visible = true

func _on_hud_phone_button_pressed() -> void:
	if is_game_started:
		toggle_phone()
