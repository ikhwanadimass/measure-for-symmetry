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
@onready var load_game_screen: Control = $PhoneContainer/PhoneFrame.get_node_or_null("LoadGameScreen")
@onready var level_select_screen: Control = $PhoneContainer/PhoneFrame.get_node_or_null("LevelSelectScreen")
@onready var notes_screen: Control = $PhoneContainer/PhoneFrame.get_node_or_null("NotesScreen")
@onready var result_screen: Control = $PhoneContainer/PhoneFrame.get_node_or_null("ResultScreen")

# Layar Pengaturan di dalam HP (dari smartphone.tscn)
@onready var settings_screen: Control = $PhoneContainer/PhoneFrame.get_node_or_null("SettingsScreen")
@onready var label_bgm_val: Label = $PhoneContainer/PhoneFrame.get_node_or_null("SettingsScreen/SettingsContainer/LabelBGM")
@onready var slider_bgm: HSlider = $PhoneContainer/PhoneFrame.get_node_or_null("SettingsScreen/SettingsContainer/SliderBGM")
@onready var label_sfx_val: Label = $PhoneContainer/PhoneFrame.get_node_or_null("SettingsScreen/SettingsContainer/LabelSFX")
@onready var slider_sfx: HSlider = $PhoneContainer/PhoneFrame.get_node_or_null("SettingsScreen/SettingsContainer/SliderSFX")
@onready var btn_fullscreen: Button = $PhoneContainer/PhoneFrame.get_node_or_null("SettingsScreen/SettingsContainer/BtnFullscreen")
@onready var btn_back_settings: Button = $PhoneContainer/PhoneFrame.get_node_or_null("SettingsScreen/BtnBackSettings")

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

# Elemen LoadGameScreen (Dinamis Profil Save)
@onready var save_list_container: VBoxContainer = $PhoneContainer/PhoneFrame.get_node_or_null("LoadGameScreen/SaveScroll/SaveListContainer")
@onready var label_no_save: Label = $PhoneContainer/PhoneFrame.get_node_or_null("LoadGameScreen/LabelNoSave")
@onready var btn_back_load: Button = $PhoneContainer/PhoneFrame.get_node_or_null("LoadGameScreen/BtnBackLoad")

# Elemen LevelSelectScreen
@onready var btn_back_level_select: Button = $PhoneContainer/PhoneFrame.get_node_or_null("LevelSelectScreen/BtnBackLevelSelect")

# Elemen Catatan & Hasil
@onready var btn_back_notes: Button = $PhoneContainer/PhoneFrame.get_node_or_null("NotesScreen/BtnBackNotes")
@onready var notes_text_edit: TextEdit = $PhoneContainer/PhoneFrame.get_node_or_null("NotesScreen/NotesTextEdit")
@onready var emoji_rect: TextureRect = $PhoneContainer/PhoneFrame.get_node_or_null("ResultScreen/EmojiRect")
@onready var result_label: Label = $PhoneContainer/PhoneFrame.get_node_or_null("ResultScreen/ResultLabel")
@onready var btn_close_result: Button = $PhoneContainer/PhoneFrame.get_node_or_null("ResultScreen/BtnCloseResult")
@onready var btn_result_main_menu: Button = $PhoneContainer/PhoneFrame.get_node_or_null("ResultScreen/BtnResultMainMenu")

# Menu Dalam Game (In-Game Menu)
var in_game_menu: VBoxContainer = null
var btn_ig_resume: TextureButton = null
var btn_ig_notes: TextureButton = null
var btn_ig_settings: TextureButton = null
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
var level_buttons: Dictionary = {}
var is_handling_result: bool = false

func is_in_tutorial() -> bool:
	if owner and owner.name == "LevelTutorial":
		return true
	if get_parent() and get_parent().name == "LevelTutorial":
		return true
	if get_tree() and get_tree().current_scene and get_tree().current_scene.name == "LevelTutorial":
		return true
	return false

func _ready() -> void:
	perbaiki_teks_tombol_otomatis()
	setup_in_game_menu_otomatis()
	setup_settings_screen()
	hubungkan_semua_tombol()
	hubungkan_tombol_level_tscn()
	setup_pilihan_mode_rapi()
	setup_meteran_label()
	
	# 1. Jika di level tutorial, langsung mulai:
	if is_in_tutorial():
		is_game_started = true
		set_hud_visibilitas(true)
		close_phone()
		reset_dan_hentikan_timer()
		return

	# 2. Jika pemain sedang mengulang level atau masuk dari level select:
	var gm = get_node_or_null("/root/GameManager")
	if gm and gm.is_replaying:
		gm.is_replaying = false
		mulai_permainan()
		return
		
	# 3. Kondisi saat game pertama kali dibuka (Menu Utama):
	is_game_started = false
	set_hud_visibilitas(false)
	show_screen("main")
	open_phone()

func set_btn_label(button: Control, teks: String) -> void:
	if not button: return
	var lbl = button.get_node_or_null("Label") as Label
	if not lbl:
		for child in button.get_children():
			if child is Label:
				lbl = child
				break
	if not lbl:
		lbl = Label.new()
		lbl.name = "Label"
		button.add_child(lbl)
		lbl.anchors_preset = Control.PRESET_FULL_RECT
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	lbl.text = teks
	lbl.add_theme_color_override("font_color", Color(0, 0, 0, 1))

func perbaiki_teks_tombol_otomatis() -> void:
	set_btn_label(btn_play, "Main")
	set_btn_label(btn_tutorial, "Tutorial")
	set_btn_label(btn_settings, "Pengaturan")
	set_btn_label(btn_load_progress, "Muat Game")
	set_btn_label(btn_quit, "Keluar")
	
	set_btn_label(btn_continue_game, "Lanjutkan")
	set_btn_label(btn_new_game, "Game Baru")
	set_btn_label(btn_select_level, "Pilih Level")
	set_btn_label(btn_back_play, "Kembali")

func setup_in_game_menu_otomatis() -> void:
	if not phone_frame or not btn_play: return
	
	in_game_menu = VBoxContainer.new()
	in_game_menu.name = "InGameMenu"
	in_game_menu.layout_mode = 1
	in_game_menu.anchors_preset = Control.PRESET_CENTER
	in_game_menu.anchor_left = 0.5
	in_game_menu.anchor_top = 0.5
	in_game_menu.anchor_right = 0.5
	in_game_menu.anchor_bottom = 0.5
	in_game_menu.offset_left = -60.0
	in_game_menu.offset_top = -80.0
	in_game_menu.offset_right = 60.0
	in_game_menu.offset_bottom = 80.0
	in_game_menu.grow_horizontal = Control.GROW_DIRECTION_BOTH
	in_game_menu.grow_vertical = Control.GROW_DIRECTION_BOTH
	in_game_menu.alignment = BoxContainer.ALIGNMENT_CENTER
	in_game_menu.add_theme_constant_override("separation", 8)
	
	btn_ig_resume = btn_play.duplicate() as TextureButton
	btn_ig_resume.name = "BtnResume"
	set_btn_label(btn_ig_resume, "Lanjut")
	btn_ig_resume.pressed.connect(close_phone)
	in_game_menu.add_child(btn_ig_resume)
	
	btn_ig_notes = btn_play.duplicate() as TextureButton
	btn_ig_notes.name = "BtnNotes"
	set_btn_label(btn_ig_notes, "Catatan")
	btn_ig_notes.pressed.connect(_on_btn_notes_pressed)
	in_game_menu.add_child(btn_ig_notes)

	btn_ig_settings = btn_play.duplicate() as TextureButton
	btn_ig_settings.name = "BtnSettings"
	set_btn_label(btn_ig_settings, "Pengaturan")
	btn_ig_settings.pressed.connect(_on_btn_settings_pressed)
	in_game_menu.add_child(btn_ig_settings)
	
	btn_ig_finish = btn_play.duplicate() as TextureButton
	btn_ig_finish.name = "BtnFinish"
	set_btn_label(btn_ig_finish, "Selesai")
	btn_ig_finish.pressed.connect(buka_selesai_langsung)
	in_game_menu.add_child(btn_ig_finish)
	
	btn_ig_main_menu = btn_play.duplicate() as TextureButton
	btn_ig_main_menu.name = "BtnMainMenu"
	set_btn_label(btn_ig_main_menu, "Menu Utama")
	btn_ig_main_menu.pressed.connect(_on_btn_main_menu_pressed)
	in_game_menu.add_child(btn_ig_main_menu)
	
	phone_frame.add_child(in_game_menu)
	in_game_menu.visible = false

func setup_settings_screen() -> void:
	if slider_bgm:
		slider_bgm.min_value = 0
		slider_bgm.max_value = 100
		slider_bgm.step = 5
		slider_bgm.value = 100
		slider_bgm.value_changed.connect(_on_bgm_slider_changed)
	if slider_sfx:
		slider_sfx.min_value = 0
		slider_sfx.max_value = 100
		slider_sfx.step = 5
		slider_sfx.value = 100
		slider_sfx.value_changed.connect(_on_sfx_slider_changed)
	if btn_fullscreen:
		var is_fs = (DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN or DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
		btn_fullscreen.text = "Layar Penuh: ON" if is_fs else "Layar Penuh: OFF"
		btn_fullscreen.pressed.connect(_toggle_fullscreen)
	if btn_back_settings:
		btn_back_settings.pressed.connect(_on_btn_back_settings_pressed)

func _on_bgm_slider_changed(val: float) -> void:
	if label_bgm_val: label_bgm_val.text = "Volume Musik: %d%%" % int(val)
	var am = get_node_or_null("/root/AudioManager")
	if am and am.has_method("set_bgm_volume"):
		am.set_bgm_volume(val)

func _on_sfx_slider_changed(val: float) -> void:
	if label_sfx_val: label_sfx_val.text = "Volume SFX: %d%%" % int(val)
	var am = get_node_or_null("/root/AudioManager")
	if am and am.has_method("set_sfx_volume"):
		am.set_sfx_volume(val)

func _toggle_fullscreen() -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am: am.play_sfx("click")
	
	var is_fs = (DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN or DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	if is_fs:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		if btn_fullscreen: btn_fullscreen.text = "Layar Penuh: OFF"
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		if btn_fullscreen: btn_fullscreen.text = "Layar Penuh: ON"

func _on_btn_back_settings_pressed() -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am: am.play_sfx("click")
	if is_game_started:
		show_screen("in_game")
	else:
		show_screen("main")

func setup_pilihan_mode_rapi() -> void:
	if not option_mode: return
		
	option_mode.clear()
	option_mode.add_item("Mode Santai", 0)
	option_mode.add_item("Mode Normal", 1)
	option_mode.add_item("Mode Sulit", 2)
	option_mode.add_item("Mode Bebas", 3)
	
	# Mengaktifkan deskripsi mode secara rapi (font 9px agar pas di kertas)
	if form_container:
		label_mode_desc = form_container.get_node_or_null("LabelModeDesc")
		if not label_mode_desc:
			label_mode_desc = Label.new()
			label_mode_desc.name = "LabelModeDesc"
			label_mode_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label_mode_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			label_mode_desc.add_theme_color_override("font_color", Color(0.2, 0.2, 0.2, 1.0))
			label_mode_desc.add_theme_font_size_override("font_size", 9)
			form_container.add_child(label_mode_desc)
			if btn_start_new_game:
				form_container.move_child(label_mode_desc, btn_start_new_game.get_index())
			
	if not option_mode.item_selected.is_connected(_on_mode_item_selected):
		option_mode.item_selected.connect(_on_mode_item_selected)
	option_mode.selected = 1
	_on_mode_item_selected(1)

func _on_mode_item_selected(index: int) -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am: am.play_sfx("click")
	
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.current_mode = index
	
	var deskripsi: String = ""
	match index:
		0: deskripsi = "Pintu: 5x | Waktu: 3 Menit\nCocok untuk pemula."
		1: deskripsi = "Pintu: 3x | Waktu: 2 Menit\nPengalaman standar."
		2: deskripsi = "Pintu: 1x | Waktu: 1 Menit\nTantangan maksimal!"
		3: deskripsi = "Pintu: Bebas | Waktu: Bebas\nEksplorasi tanpa batas."
			
	if label_mode_desc:
		label_mode_desc.text = deskripsi

func hubungkan_semua_tombol() -> void:
	if hud_phone_button: hud_phone_button.pressed.connect(toggle_phone)
	if btn_play: btn_play.pressed.connect(_on_btn_play_pressed)
	if btn_tutorial: btn_tutorial.pressed.connect(_on_btn_tutorial_pressed)
	if btn_settings: btn_settings.pressed.connect(_on_btn_settings_pressed)
	if btn_load_progress: btn_load_progress.pressed.connect(_on_btn_load_progress_pressed)
	if btn_quit: btn_quit.pressed.connect(func(): get_tree().quit())
	
	if btn_continue_game: btn_continue_game.pressed.connect(_on_btn_continue_game_pressed)
	if btn_new_game: btn_new_game.pressed.connect(_on_btn_new_game_pressed)
	if btn_select_level: btn_select_level.pressed.connect(_on_btn_select_level_pressed)
	if btn_back_play: btn_back_play.pressed.connect(_on_btn_back_play_pressed)
	
	if btn_start_new_game: btn_start_new_game.pressed.connect(_on_btn_start_new_game_pressed)
	if btn_back_new_game: btn_back_new_game.pressed.connect(func(): 
		var am = get_node_or_null("/root/AudioManager")
		if am: am.play_sfx("click")
		show_screen("play_menu")
	)
	
	# Layar Muat Game (Dinamis)
	if btn_back_load: btn_back_load.pressed.connect(func():
		var am = get_node_or_null("/root/AudioManager")
		if am: am.play_sfx("click")
		show_screen("main")
	)

	if btn_back_level_select: btn_back_level_select.pressed.connect(func(): 
		var am = get_node_or_null("/root/AudioManager")
		if am: am.play_sfx("click")
		show_screen("play_menu")
	)
	
	if btn_back_notes: btn_back_notes.pressed.connect(_on_btn_back_notes_pressed)
	if btn_close_result: btn_close_result.pressed.connect(_on_btn_close_result_pressed)
	if btn_result_main_menu: btn_result_main_menu.pressed.connect(_on_btn_result_main_menu_pressed)

# ================= HUBUNGKAN TOMBOL LEVEL DARI TSCN =================
func hubungkan_tombol_level_tscn() -> void:
	level_buttons.clear()
	if not level_select_screen:
		return
		
	var buttons = level_select_screen.find_children("BtnLevel*", "BaseButton", true, false)
	for btn in buttons:
		var nomor_str = btn.name.replace("BtnLevel", "").strip_edges()
		if nomor_str.is_valid_int():
			var lvl_num = nomor_str.to_int()
			level_buttons[lvl_num] = btn
			
			if not btn.pressed.is_connected(_on_level_btn_clicked.bind(lvl_num)):
				btn.pressed.connect(_on_level_btn_clicked.bind(lvl_num))

func _on_level_btn_clicked(nomor_level: int) -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am:
		am.play_sfx("click")
	_masuk_level_bersih(nomor_level)

func update_level_select_buttons() -> void:
	hubungkan_tombol_level_tscn()
	
	var gm = get_node_or_null("/root/GameManager")
	var unlocked_level: int = int(gm.unlocked_level) if gm else 1

	for lvl in level_buttons.keys():
		var btn = level_buttons[lvl]
		if not is_instance_valid(btn):
			continue

		var is_unlocked: bool = (lvl <= unlocked_level)
		btn.disabled = not is_unlocked
		btn.mouse_filter = Control.MOUSE_FILTER_STOP if is_unlocked else Control.MOUSE_FILTER_IGNORE
		btn.modulate = Color(1, 1, 1, 1) if is_unlocked else Color(0.4, 0.4, 0.4, 0.6)
# ====================================================================

# ================= SISTEM DAFTAR SAVE DINAMIS (MUAT GAME) ===========
func _on_btn_load_progress_pressed() -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am: am.play_sfx("click")
	update_load_screen_ui()
	show_screen("load_game")

func update_load_screen_ui() -> void:
	if not save_list_container: return
	
	# Hapus daftar item sebelumnya
	for child in save_list_container.get_children():
		child.queue_free()
		
	var gm = get_node_or_null("/root/GameManager")
	var saves = gm.saves_list if gm else []
	
	# Jika belum ada save, tampilkan label keterangan
	if saves.is_empty():
		if label_no_save: label_no_save.visible = true
		return
		
	if label_no_save: label_no_save.visible = false
	
	# Render setiap save yang pernah dibuat
	for s in saves:
		var s_id: String = str(s.get("id", ""))
		var s_name: String = str(s.get("save_name", "Player"))
		var s_lvl: int = int(s.get("unlocked_level", 1))
		var s_mode: int = int(s.get("current_mode", 1))
		var mode_name = "Biasa"
		if gm and gm.mode_data.has(s_mode):
			mode_name = gm.mode_data[s_mode].get("name", "Biasa").replace("Mode ", "")
			
		var row = HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_theme_constant_override("separation", 3)
		
		# Tombol Profil Save
		var btn = Button.new()
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.add_theme_font_size_override("font_size", 9)
		btn.add_theme_color_override("font_color", Color(0, 0, 0, 1))
		
		var active_mark = " ★" if (gm and gm.active_save_id == s_id) else ""
		btn.text = "%s (Lv %d - %s)%s" % [s_name, s_lvl, mode_name, active_mark]
		
		var target_id = s_id
		btn.pressed.connect(func():
			var am = get_node_or_null("/root/AudioManager")
			if am: am.play_sfx("click")
			if gm:
				gm.load_save_by_id(target_id)
			show_screen("play_menu")
			if btn_continue_game: btn_continue_game.visible = true
		)
		row.add_child(btn)
		
		# Tombol Hapus (X)
		var del_btn = Button.new()
		del_btn.custom_minimum_size = Vector2(18, 0)
		del_btn.text = "X"
		del_btn.add_theme_font_size_override("font_size", 9)
		del_btn.add_theme_color_override("font_color", Color(0.8, 0.2, 0.2, 1))
		del_btn.pressed.connect(func():
			var am = get_node_or_null("/root/AudioManager")
			if am: am.play_sfx("click")
			if gm:
				gm.delete_save_by_id(target_id)
			update_load_screen_ui()
		)
		row.add_child(del_btn)
		
		save_list_container.add_child(row)
# ====================================================================

func _on_btn_play_pressed() -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am: am.play_sfx("click")
	
	var gm = get_node_or_null("/root/GameManager")
	var ada_save: bool = (gm != null) and (gm.has_save or not gm.saves_list.is_empty())
	
	# Tombol Lanjutkan & Pilih Level hanya muncul jika sudah punya save data
	if btn_continue_game:
		btn_continue_game.visible = ada_save
	if btn_select_level:
		btn_select_level.visible = ada_save
	
	show_screen("play_menu")

func _on_btn_continue_game_pressed() -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am: am.play_sfx("click")
	var gm = get_node_or_null("/root/GameManager")
	if gm and gm.has_save:
		gm.load_from_disk()
	mulai_permainan()

func _on_btn_new_game_pressed() -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am: am.play_sfx("click")
	show_screen("new_game")
	if input_save_name:
		var gm = get_node_or_null("/root/GameManager")
		var count = (gm.saves_list.size() + 1) if gm else 1
		input_save_name.text = "Player %d" % count
		input_save_name.grab_focus()

func _on_btn_select_level_pressed() -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am: am.play_sfx("click")
	update_level_select_buttons()
	show_screen("level_select")

func _on_btn_back_play_pressed() -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am: am.play_sfx("click")
	show_screen("main")

func _on_btn_start_new_game_pressed() -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am: am.play_sfx("click")
	var nama = input_save_name.text.strip_edges() if input_save_name else "Player"
	if nama.is_empty(): nama = "Player"
	
	var gm = get_node_or_null("/root/GameManager")
	var mode_pilihan = option_mode.selected if option_mode else 1
	if gm:
		gm.buat_save_baru(nama, mode_pilihan)
	mulai_permainan()

func _masuk_level_bersih(nomor_level: int) -> void:
	if _is_transitioning_level:
		return
	_is_transitioning_level = true

	close_phone()

	var gm = get_node_or_null("/root/GameManager")
	if gm and gm.has_method("load_level"):
		gm.load_level(nomor_level, true)
	else:
		if gm:
			gm.current_level = nomor_level
			gm.is_replaying = true

		var target_scene: String = "res://scene/level/Level%02d.tscn" % nomor_level
		if not ResourceLoader.exists(target_scene):
			target_scene = "res://scene/Level01.tscn"

		var tree := get_tree()
		if tree:
			tree.paused = false
			tree.change_scene_to_file(target_scene)

	call_deferred("_selesai_transisi_level")

func _selesai_transisi_level() -> void:
	_is_transitioning_level = false

func _on_btn_notes_pressed() -> void:
	buka_catatan_langsung()

func _on_btn_back_notes_pressed() -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am: am.play_sfx("click")
	if is_game_started: show_screen("in_game")
	else: show_screen("main")

func _on_btn_main_menu_pressed() -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am:
		am.play_sfx("click")
		am.play_bgm("home")
		
	is_game_started = false
	timer_berjalan = false
	set_hud_visibilitas(false)
	
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.is_replaying = false
		
	var tree := get_tree()
	if tree:
		tree.paused = false
		# Jika sedang di LevelTutorial atau level lain, kembali ke Level 01 sebagai home scene
		if tree.current_scene and tree.current_scene.scene_file_path != "res://scene/level/Level01.tscn":
			tree.change_scene_to_file("res://scene/level/Level01.tscn")
			return
			
	show_screen("main")

func _on_btn_result_main_menu_pressed() -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am:
		am.play_sfx("click")
		am.play_bgm("home")
		
	is_game_started = false
	timer_berjalan = false
	set_hud_visibilitas(false)
	
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.is_replaying = false
		
	var tree := get_tree()
	if tree:
		tree.paused = false
		if tree.current_scene and tree.current_scene.scene_file_path != "res://scene/level/Level01.tscn":
			tree.change_scene_to_file("res://scene/level/Level01.tscn")
			return
			
	show_screen("main")

func mulai_permainan() -> void:
	is_game_started = true
	var am = get_node_or_null("/root/AudioManager")
	if am: am.play_bgm("game")
	set_hud_visibilitas(true)
	close_phone()
	reset_dan_hentikan_timer()

func _on_btn_tutorial_pressed() -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am:
		am.play_sfx("click")
		am.play_bgm("game")
	var tree := get_tree()
	if tree:
		tree.paused = false
		tree.change_scene_to_file("res://scene/LevelTutorial.tscn")

func _on_btn_settings_pressed() -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am: am.play_sfx("click")
	show_screen("settings")

func show_screen(screen_name: String) -> void:
	if screen_name == "play_menu":
		var gm = get_node_or_null("/root/GameManager")
		var ada_save: bool = (gm != null) and (gm.has_save or not gm.saves_list.is_empty())
		if btn_continue_game: btn_continue_game.visible = ada_save
		if btn_select_level: btn_select_level.visible = ada_save

	if main_menu: main_menu.visible = (screen_name == "main")
	if play_menu: play_menu.visible = (screen_name == "play_menu")
	if new_game_screen: new_game_screen.visible = (screen_name == "new_game")
	if load_game_screen: load_game_screen.visible = (screen_name == "load_game")
	if level_select_screen: level_select_screen.visible = (screen_name == "level_select")
	if notes_screen: notes_screen.visible = (screen_name == "notes")
	if in_game_menu: in_game_menu.visible = (screen_name == "in_game")
	if settings_screen: settings_screen.visible = (screen_name == "settings")
	if result_screen: result_screen.visible = (screen_name == "result")
	_atur_fokus_layar(screen_name)

func _atur_fokus_layar(screen_name: String) -> void:
	if not is_inside_tree():
		return
	match screen_name:
		"main": if btn_play: btn_play.grab_focus()
		"play_menu":
			if btn_continue_game and btn_continue_game.visible:
				btn_continue_game.grab_focus()
			elif btn_new_game and btn_new_game.visible:
				btn_new_game.grab_focus()
			elif btn_back_play:
				btn_back_play.grab_focus()
		"new_game":
			if input_save_name: input_save_name.grab_focus()
		"load_game":
			if save_list_container and save_list_container.get_child_count() > 0:
				var first_row = save_list_container.get_child(0)
				if first_row and first_row.get_child_count() > 0:
					first_row.get_child(0).grab_focus()
			elif btn_back_load:
				btn_back_load.grab_focus()
		"level_select":
			var gm = get_node_or_null("/root/GameManager")
			var unlocked: int = int(gm.unlocked_level) if gm else 1
			var active_lvl: int = int(gm.current_level) if gm else 1
			var preferred_lvl: int = clampi(active_lvl, 1, unlocked)
			var focus_btn: Control = level_buttons.get(preferred_lvl, null)
			if focus_btn and focus_btn.is_inside_tree() and not (focus_btn is BaseButton and focus_btn.disabled):
				focus_btn.grab_focus()
			elif btn_back_level_select and btn_back_level_select.is_inside_tree():
				btn_back_level_select.grab_focus()
		"in_game":
			if btn_ig_resume: btn_ig_resume.grab_focus()
		"settings":
			if slider_bgm: slider_bgm.grab_focus()
		"result":
			if btn_close_result: btn_close_result.grab_focus()

func toggle_phone() -> void:
	if not is_game_started: return
	if is_open: close_phone()
	else: open_phone()

func open_phone() -> void:
	is_open = true
	if dim_overlay: dim_overlay.visible = true
	if phone_container: phone_container.visible = true
	
	var tree := get_tree()
	if tree:
		tree.paused = true
	
	if is_game_started:
		show_screen("in_game")
	else:
		show_screen("main")
	
	var am = get_node_or_null("/root/AudioManager")
	if am: am.play_sfx("phone")

func close_phone() -> void:
	is_open = false
	if dim_overlay: dim_overlay.visible = false
	if phone_container: phone_container.visible = false
	
	var tree := get_tree()
	if tree:
		tree.paused = false
		
	var am = get_node_or_null("/root/AudioManager")
	if am: am.play_sfx("phone_close")

func _input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
		
	# 1. Shortcut Enter / Space di layar evaluasi
	if is_open and result_screen and result_screen.visible:
		if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER or event.keycode == KEY_SPACE:
			get_viewport().set_input_as_handled()
			_on_btn_close_result_pressed()
			return

	# 2. Tombol TAB murni untuk Buka / Tutup HP
	if event.keycode == KEY_TAB:
		if input_save_name and input_save_name.has_focus():
			return
		toggle_phone()
		get_viewport().set_input_as_handled()
		return
		
	# 3. Shortcut saat HP tertutup
	if not is_open:
		if event.keycode == KEY_N and is_game_started:
			buka_catatan_langsung()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_M and is_game_started:
			buka_selesai_langsung()
			get_viewport().set_input_as_handled()
		return

	# 4. Navigasi keyboard W / S / Panah & Slider A / D
	var is_typing = (input_save_name and input_save_name.has_focus()) or (notes_screen and notes_screen.visible and notes_text_edit and notes_text_edit.has_focus())
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
		elif event.keycode == KEY_A or event.keycode == KEY_LEFT:
			var focused = get_viewport().gui_get_focus_owner()
			if focused and focused is HSlider:
				focused.value -= focused.step
				get_viewport().set_input_as_handled()
				return
		elif event.keycode == KEY_D or event.keycode == KEY_RIGHT:
			var focused = get_viewport().gui_get_focus_owner()
			if focused and focused is HSlider:
				focused.value += focused.step
				get_viewport().set_input_as_handled()
				return

	# 5. Tombol ESC untuk kembali / tutup HP
	if event.keycode == KEY_ESCAPE and is_open:
		var am = get_node_or_null("/root/AudioManager")
		if am: am.play_sfx("click")
		if settings_screen and settings_screen.visible:
			_on_btn_back_settings_pressed()
		elif load_game_screen and load_game_screen.visible: show_screen("main")
		elif new_game_screen and new_game_screen.visible: show_screen("play_menu")
		elif level_select_screen and level_select_screen.visible: show_screen("play_menu")
		elif play_menu and play_menu.visible: show_screen("main")
		elif notes_screen and notes_screen.visible: show_screen("in_game" if is_game_started else "main")
		elif in_game_menu and in_game_menu.visible: close_phone()
		elif is_game_started: close_phone()
		get_viewport().set_input_as_handled()

func buka_catatan_langsung() -> void:
	open_phone()
	show_screen("notes")
	var am = get_node_or_null("/root/AudioManager")
	if am: am.play_sfx("note")
	if notes_text_edit: notes_text_edit.grab_focus()

func buka_selesai_langsung() -> void:
	open_phone()
	_evaluasi_misi()

func _evaluasi_misi() -> void:
	if not get_tree() or not get_tree().current_scene: return
	var checker = get_tree().current_scene.find_child("SymmetryChecker", true, false)
	if checker and checker.has_method("hitung_evaluasi"):
		var hasil: Dictionary = checker.hitung_evaluasi()
		tampilkan_hasil(hasil)

func tampilkan_hasil(hasil: Dictionary) -> void:
	sudah_selesai_evaluasi = true
	_level_unlocked_for_result = false
	is_handling_result = false
	status_evaluasi = hasil.get("status", "game_over")
	var grade = hasil.get("grade", "happy")
	
	var am = get_node_or_null("/root/AudioManager")
	
	match grade:
		"happy":
			if emoji_rect: emoji_rect.texture = EMOJI_HAPPY
			if btn_close_result: btn_close_result.text = "[Enter] Lanjut"
			if btn_result_main_menu: btn_result_main_menu.visible = false
			if am: am.play_sfx("win")
		"neutral":
			if emoji_rect: emoji_rect.texture = EMOJI_NEUTRAL
			if btn_close_result: btn_close_result.text = "[Enter] Lanjut"
			if btn_result_main_menu: btn_result_main_menu.visible = false
			if am: am.play_sfx("medium")
		"sad":
			if emoji_rect: emoji_rect.texture = EMOJI_SAD
			if btn_close_result: btn_close_result.text = "[Enter] Ulangi"
			if btn_result_main_menu: btn_result_main_menu.visible = true
			if am: am.play_sfx("game_over")
			
	if result_label:
		result_label.text = hasil.get("text", "Evaluasi Selesai")
		
	show_screen("result")
	
	if btn_close_result:
		btn_close_result.grab_focus()

func _on_btn_close_result_pressed() -> void:
	if is_handling_result or _is_transitioning_level:
		return

	var am = get_node_or_null("/root/AudioManager")
	if am: am.play_sfx("click")

	if is_in_tutorial():
		is_handling_result = true
		close_phone()
		var tree := get_tree()
		if tree:
			tree.paused = false
			if status_evaluasi == "game_over":
				tree.change_scene_to_file("res://scene/LevelTutorial.tscn")
			else:
				tree.change_scene_to_file("res://scene/level/Level01.tscn")
		return

	var gm = get_node_or_null("/root/GameManager")
	if status_evaluasi == "game_over":
		is_handling_result = true
		_is_transitioning_level = true
		if gm and gm.has_method("retry_current_level"):
			gm.retry_current_level()
		else:
			if gm:
				gm.is_replaying = true
			var tree := get_tree()
			if tree:
				tree.paused = false
				tree.call_deferred("reload_current_scene")
	else:
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
			is_handling_result = true
			_masuk_level_bersih(next_level)
		else:
			update_level_select_buttons()
			show_screen("level_select")

func mulai_timer_ruang2() -> void:
	if is_in_tutorial():
		timer_berjalan = false
		if timer_label: timer_label.visible = false
		return
		
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
	if is_in_tutorial():
		timer_berjalan = false
		if timer_label: timer_label.visible = false
		return
		
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
	if not timer_label: return
	if is_in_tutorial():
		timer_label.visible = false
		return
		
	var menit: int = int(waktu_sisa) / 60
	var detik: int = int(waktu_sisa) % 60
	timer_label.text = "%02d:%02d" % [menit, detik]
	
	if waktu_sisa <= 30.0 and timer_berjalan:
		timer_label.add_theme_color_override("font_color", Color(0.9, 0.2, 0.2, 1.0))
	else:
		timer_label.add_theme_color_override("font_color", Color(0.0, 0.0, 0.0, 1.0))

func kembalikan_ke_ruang1() -> void:
	if not get_tree() or not get_tree().current_scene: return
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
	
	set_status_meteran(false)
	hud_phone_button.add_child(meteran_label)

func set_status_meteran(aktif: bool) -> void:
	if meteran_label:
		meteran_label.add_theme_color_override("font_color", WARNA_METERAN_AKTIF if aktif else WARNA_METERAN_MATI)

func tampilkan_interaksi(pesan: String) -> void:
	if interact_label:
		interact_label.text = pesan

func set_hud_visibilitas(tampil: bool) -> void:
	if hud_phone_button:
		hud_phone_button.visible = tampil
	if timer_label:
		timer_label.visible = tampil and not is_in_tutorial()
