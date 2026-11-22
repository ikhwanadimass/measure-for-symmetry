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
	setup_level_select_otomatis()
	hubungkan_semua_tombol()
	setup_pilihan_mode_rapi()
	setup_meteran_label()
	
	var am = get_node_or_null("/root/AudioManager")
	
	if is_in_tutorial():
		if am: am.play_bgm("game")
		mulai_permainan()
		if timer_label: timer_label.visible = false
		return
		
	var gm = get_node_or_null("/root/GameManager")
	if gm and gm.is_replaying:
		gm.is_replaying = false
		if am: am.play_bgm("game")
		mulai_permainan()
		return
		
	if am: am.play_bgm("home")
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
	if not phone_frame or in_game_menu: return
		
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
	btn_ig_resume.name = "BtnResume"
	set_btn_label(btn_ig_resume, "Lanjut")
	btn_ig_resume.pressed.connect(close_phone)
	in_game_menu.add_child(btn_ig_resume)
	
	btn_ig_notes = btn_play.duplicate() as TextureButton
	btn_ig_notes.name = "BtnNotes"
	set_btn_label(btn_ig_notes, "Catatan")
	btn_ig_notes.pressed.connect(_on_btn_notes_pressed)
	in_game_menu.add_child(btn_ig_notes)
	
	btn_ig_finish = btn_play.duplicate() as TextureButton
	btn_ig_finish.name = "BtnFinish"
	set_btn_label(btn_ig_finish, "Selesai")
	btn_ig_finish.pressed.connect(evaluasi_misi)
	in_game_menu.add_child(btn_ig_finish)
	
	btn_ig_main_menu = btn_play.duplicate() as TextureButton
	btn_ig_main_menu.name = "BtnMainMenu"
	set_btn_label(btn_ig_main_menu, "Menu Utama")
	btn_ig_main_menu.pressed.connect(_on_btn_main_menu_pressed)
	in_game_menu.add_child(btn_ig_main_menu)
	
	phone_frame.add_child(in_game_menu)
	in_game_menu.visible = false

func setup_pilihan_mode_rapi() -> void:
	if not option_mode or not form_container: return
		
	option_mode.clear()
	option_mode.add_item("Mode Santai", 0)
	option_mode.add_item("Mode Normal", 1)
	option_mode.add_item("Mode Sulit", 2)
	option_mode.add_item("Mode Bebas", 3)
	
	option_mode.add_theme_font_size_override("font_size", UKURAN_FONT_FORM)
	if input_save_name: input_save_name.add_theme_font_size_override("font_size", UKURAN_FONT_FORM)
	if btn_start_new_game: btn_start_new_game.add_theme_font_size_override("font_size", UKURAN_FONT_FORM)
	if btn_back_new_game: btn_back_new_game.add_theme_font_size_override("font_size", UKURAN_FONT_FORM)
		
	if not label_mode_desc:
		label_mode_desc = Label.new()
		label_mode_desc.name = "LabelModeDesc"
		label_mode_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label_mode_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label_mode_desc.add_theme_color_override("font_color", Color(0.15, 0.15, 0.15, 1.0))
		label_mode_desc.add_theme_font_size_override("font_size", UKURAN_FONT_DESC)
		form_container.add_child(label_mode_desc)
		if btn_start_new_game:
			form_container.move_child(label_mode_desc, btn_start_new_game.get_index())
			
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
	
	if btn_level_1: btn_level_1.pressed.connect(_on_btn_level_1_pressed)
	if btn_back_level_select: btn_back_level_select.pressed.connect(func(): 
		var am = get_node_or_null("/root/AudioManager")
		if am: am.play_sfx("click")
		show_screen("play_menu")
	)
	
	if btn_back_notes: btn_back_notes.pressed.connect(_on_btn_back_notes_pressed)
	if btn_close_result: btn_close_result.pressed.connect(_on_btn_close_result_pressed)

func _on_btn_play_pressed() -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am: am.play_sfx("click")
	var gm = get_node_or_null("/root/GameManager")
	var ada_save: bool = gm.has_save if gm else false

	# Tombol Lanjutkan & Pilih Level hanya tampil jika sudah ada save:
	if btn_continue_game:
		btn_continue_game.visible = ada_save
	if btn_select_level:
		btn_select_level.visible = ada_save

	show_screen("play_menu")

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

func _on_btn_continue_game_pressed() -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am: am.play_sfx("click")
	var gm = get_node_or_null("/root/GameManager")
	if gm and gm.has_save:
		gm.load_from_disk()
	var level_target: int = int(gm.current_level) if gm else 1
	_masuk_level_bersih(level_target)

func _on_btn_new_game_pressed() -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am: am.play_sfx("click")
	show_screen("new_game")
	if input_save_name:
		if input_save_name.text.strip_edges().is_empty():
			input_save_name.text = "Player"
		input_save_name.grab_focus()

func _on_btn_select_level_pressed() -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am: am.play_sfx("click")
	show_screen("level_select")

func _on_btn_back_play_pressed() -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am: am.play_sfx("click")
	show_screen("main")

func _on_btn_start_new_game_pressed() -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am: am.play_sfx("click")
	var nama = input_save_name.text.strip_edges() if input_save_name else "Player 1"
	if nama.is_empty():
		nama = "Player 1"
	var mode = option_mode.selected if option_mode else 1
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.buat_save_baru(nama, mode)

	_masuk_level_bersih(1)

func _style_level_button_label(btn: Control) -> void:
	if not btn:
		return
	for child in btn.get_children():
		if child is Label:
			var lbl := child as Label
			lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			lbl.add_theme_font_size_override("font_size", UKURAN_FONT_LABEL)
			return

func setup_level_select_otomatis() -> void:
	if not level_select_screen or not btn_level_1:
		return
	if not level_buttons.is_empty():
		return

	var gm = get_node_or_null("/root/GameManager")
	var max_level: int = gm.get_max_level() if (gm and gm.has_method("get_max_level")) else 10

	var use_grid: bool = max_level > 5
	var base_left: float = btn_level_1.offset_left
	var base_top: float = btn_level_1.offset_top
	var full_width: float = maxf(60.0, btn_level_1.offset_right - btn_level_1.offset_left)
	var btn_height: float = maxf(20.0, btn_level_1.offset_bottom - btn_level_1.offset_top)
	var col_gap: float = 6.0
	var row_gap: float = 6.0
	var col_width: float = (full_width - col_gap) * 0.5 if use_grid else full_width

	level_buttons[1] = btn_level_1
	btn_level_1.ignore_texture_size = true
	btn_level_1.stretch_mode = TextureButton.STRETCH_SCALE
	btn_level_1.offset_left = base_left
	btn_level_1.offset_right = base_left + col_width
	btn_level_1.offset_top = base_top
	btn_level_1.offset_bottom = base_top + btn_height
	_style_level_button_label(btn_level_1)
	set_btn_label(btn_level_1, "Lv 1" if use_grid else "Level 1")

	var insert_idx: int = btn_level_1.get_index() + 1

	for lvl in range(2, max_level + 1):
		var btn_lvl := btn_level_1.duplicate() as TextureButton
		if not btn_lvl:
			continue
		btn_lvl.name = "BtnLevel%d" % lvl
		btn_lvl.ignore_texture_size = true
		btn_lvl.stretch_mode = TextureButton.STRETCH_SCALE

		var col: int = (lvl - 1) % 2 if use_grid else 0
		@warning_ignore("integer_division")
		var row: int = ((lvl - 1) / 2) if use_grid else (lvl - 1)
		var left_x: float = base_left + float(col) * (col_width + col_gap)
		var top_y: float = base_top + float(row) * (btn_height + row_gap)
		btn_lvl.offset_left = left_x
		btn_lvl.offset_right = left_x + col_width
		btn_lvl.offset_top = top_y
		btn_lvl.offset_bottom = top_y + btn_height
		_style_level_button_label(btn_lvl)
		set_btn_label(btn_lvl, ("Lv %d" % lvl) if use_grid else ("Level %d" % lvl))
		btn_lvl.pressed.connect(_on_btn_level_pressed.bind(lvl))
		level_select_screen.add_child(btn_lvl)
		level_select_screen.move_child(btn_lvl, insert_idx)
		insert_idx += 1
		level_buttons[lvl] = btn_lvl

	update_level_select_buttons()

func update_level_select_buttons() -> void:
	var gm = get_node_or_null("/root/GameManager")
	var unlocked: int = int(gm.unlocked_level) if gm else 1
	var use_grid: bool = level_buttons.size() > 5
	for lvl: int in level_buttons:
		var btn: TextureButton = level_buttons[lvl]
		if not is_instance_valid(btn):
			continue
		var is_unlocked: bool = lvl <= unlocked
		btn.disabled = not is_unlocked
		btn.focus_mode = Control.FOCUS_ALL if is_unlocked else Control.FOCUS_NONE
		btn.modulate = Color(1.0, 1.0, 1.0, 1.0) if is_unlocked else Color(0.55, 0.55, 0.55, 0.75)
		var prefix: String = "Lv" if use_grid else "Level"
		set_btn_label(btn, ("%s %d" % [prefix, lvl]) if is_unlocked else ("%s %d [X]" % [prefix, lvl]))

func _on_btn_level_pressed(level_num: int) -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am: am.play_sfx("click")
	var gm = get_node_or_null("/root/GameManager")
	var unlocked: int = int(gm.unlocked_level) if gm else 1
	if level_num > unlocked:
		return
	_masuk_level_bersih(level_num)

func _on_btn_level_1_pressed() -> void:
	_on_btn_level_pressed(1)

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
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scene/LevelTutorial.tscn")

func _on_btn_settings_pressed() -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am: am.play_sfx("click")

func _on_btn_load_progress_pressed() -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am: am.play_sfx("click")

func show_screen(screen_name: String) -> void:
	if main_menu: main_menu.visible = (screen_name == "main")
	if play_menu: play_menu.visible = (screen_name == "play_menu")
	if new_game_screen: new_game_screen.visible = (screen_name == "new_game")
	if level_select_screen:
		level_select_screen.visible = (screen_name == "level_select")
		if screen_name == "level_select":
			update_level_select_buttons()
	if notes_screen: notes_screen.visible = (screen_name == "notes")
	if in_game_menu: in_game_menu.visible = (screen_name == "in_game")
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
	if not is_game_started: return
	if is_open: close_phone()
	else: open_phone()

func open_phone() -> void:
	is_open = true
	dim_overlay.visible = true
	phone_container.visible = true
	get_tree().paused = true
	
	var am = get_node_or_null("/root/AudioManager")
	if am: am.play_sfx("phone")
	
	if is_game_started: show_screen("in_game")
	else: show_screen("main")

func close_phone() -> void:
	is_open = false
	dim_overlay.visible = false
	phone_container.visible = false
	get_tree().paused = false
	
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
		var is_typing = (input_save_name and input_save_name.has_focus()) or (notes_screen and notes_screen.visible and notes_text_edit and notes_text_edit.has_focus())
		if not is_typing:
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

	# 4. Navigasi keyboard W / S / Panah Atas / Bawah
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

	# 5. Tombol ESC untuk kembali / tutup HP
	if event.keycode == KEY_ESCAPE and is_open:
		var am = get_node_or_null("/root/AudioManager")
		if am: am.play_sfx("click")
		if new_game_screen and new_game_screen.visible: show_screen("play_menu")
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
	evaluasi_misi()

func evaluasi_misi() -> void:
	if not get_tree() or not get_tree().current_scene: return
	var checker = get_tree().current_scene.find_child("SymmetryChecker", true, false)
	if checker and checker.has_method("hitung_evaluasi"):
		var hasil: Dictionary = checker.hitung_evaluasi()
		tampilkan_hasil(hasil)

func tampilkan_hasil(hasil: Dictionary) -> void:
	sudah_selesai_evaluasi = true
	_level_unlocked_for_result = false
	status_evaluasi = hasil.get("status", "game_over")
	is_handling_result = false
	var am = get_node_or_null("/root/AudioManager")
	
	match hasil.get("grade", "sad"):
		"happy":
			emoji_rect.texture = EMOJI_HAPPY
			btn_close_result.text = "[Enter] Lanjut"
			if am: am.play_sfx("win")
		"neutral":
			emoji_rect.texture = EMOJI_NEUTRAL
			btn_close_result.text = "[Enter] Lanjut"
			if am: am.play_sfx("medium")
		"sad":
			emoji_rect.texture = EMOJI_SAD
			btn_close_result.text = "[Enter] Ulangi"
			if am: am.play_sfx("game_over")
			
	result_label.text = hasil.get("text", "Evaluasi Selesai")
	show_screen("result")
	if btn_close_result: btn_close_result.grab_focus()

func _on_btn_close_result_pressed() -> void:
	if is_handling_result or _is_transitioning_level:
		return

	var am = get_node_or_null("/root/AudioManager")
	if am: am.play_sfx("click")

	if is_in_tutorial():
		is_handling_result = true
		close_phone()
		get_tree().paused = false
		if status_evaluasi == "game_over":
			get_tree().change_scene_to_file("res://scene/LevelTutorial.tscn")
		else:
			get_tree().change_scene_to_file("res://scene/level/Level01.tscn")
		return

	var gm = get_node_or_null("/root/GameManager")
	if status_evaluasi == "game_over":
		is_handling_result = true
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
