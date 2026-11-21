extends CanvasLayer

signal ruler_toggled(active: bool)
signal phone_pressed
signal restart_pressed
signal notes_focus_changed(is_typing: bool)

@onready var room_label: Label = %RoomLabel
@onready var quota_label: Label = %QuotaLabel
@onready var timer_label: Label = %TimerLabel
@onready var ruler_button: Button = %RulerButton
@onready var notes_button: Button = %NotesButton
@onready var phone_button: Button = %PhoneButton
@onready var ruler_hint_label: Label = %RulerHintLabel
@onready var toast_label: Label = %ToastLabel
@onready var toast_timer: Timer = %ToastTimer

@onready var phone_panel: PanelContainer = %PhonePanel
@onready var menu_header: Label = %MenuHeader
@onready var phone_menu_screen: VBoxContainer = %PhoneMenuScreen
@onready var phone_notes_screen: VBoxContainer = %PhoneNotesScreen
@onready var phone_settings_screen: VBoxContainer = %PhoneSettingsScreen
@onready var phone_result_screen: VBoxContainer = %PhoneResultScreen

@onready var mission_button: Button = %MissionButton
@onready var open_notes_button: Button = %OpenNotesButton
@onready var settings_button: Button = %SettingsButton
@onready var close_phone_button: Button = %ClosePhoneButton

@onready var notes_text_edit: TextEdit = %NotesTextEdit
@onready var notes_back_button: Button = %NotesBackButton
@onready var notes_close_button: Button = %NotesCloseButton

@onready var settings_restart_button: Button = %SettingsRestartButton
@onready var settings_back_button: Button = %SettingsBackButton

@onready var result_face_badge: PanelContainer = %ResultFaceBadge
@onready var result_emoji_label: Label = %ResultEmojiLabel
@onready var result_title_label: Label = %ResultTitleLabel
@onready var result_summary_label: Label = %ResultSummaryLabel
@onready var result_details_label: Label = %ResultDetailsLabel
@onready var restart_button: Button = %RestartButton
@onready var result_close_button: Button = %ResultCloseButton

var _last_result_won: bool = false

func _ready() -> void:
	ruler_button.toggled.connect(_on_ruler_button_toggled)
	notes_button.pressed.connect(toggle_notes)
	phone_button.pressed.connect(toggle_phone)

	mission_button.pressed.connect(_on_mission_button_pressed)
	open_notes_button.pressed.connect(_show_notes_screen)
	settings_button.pressed.connect(_show_settings_screen)
	close_phone_button.pressed.connect(close_phone)

	notes_back_button.pressed.connect(_show_menu_screen)
	notes_close_button.pressed.connect(close_phone)

	settings_restart_button.pressed.connect(_on_restart_button_pressed)
	settings_back_button.pressed.connect(_show_menu_screen)

	restart_button.pressed.connect(_on_restart_button_pressed)
	result_close_button.pressed.connect(_on_result_close_pressed)

	notes_text_edit.focus_entered.connect(_on_notes_focus_entered)
	notes_text_edit.focus_exited.connect(_on_notes_focus_exited)
	toast_timer.timeout.connect(_on_toast_timer_timeout)

func _unhandled_input(event: InputEvent) -> void:
	if phone_panel.visible and phone_result_screen.visible and _last_result_won:
		return

	if notes_text_edit.has_focus():
		if event.is_action_pressed("ui_cancel"):
			close_phone()
			get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("notebook"):
		toggle_notes()
		get_viewport().set_input_as_handled()
	elif phone_panel.visible and event.is_action_pressed("ui_cancel"):
		close_phone()
		get_viewport().set_input_as_handled()

func update_status(room: int, entries_remaining: int, max_entries: int, time_remaining: float) -> void:
	room_label.text = "Ruang 1 (Kerja)" if room == 1 else "Ruang 2 (Acuan)"
	menu_header.text = "Smartphone • Ruang %d" % room
	quota_label.text = "Kuota: %d/%d" % [entries_remaining, max_entries]
	mission_button.disabled = (room != 1)
	if room == 2:
		timer_label.visible = true
		timer_label.text = "Waktu: %.1fs" % maxf(time_remaining, 0.0)
		var warn_color := Color(1.0, 0.35, 0.35, 1.0) if time_remaining <= 5.0 else Color(1.0, 0.9, 0.45, 1.0)
		timer_label.add_theme_color_override("font_color", warn_color)
	else:
		timer_label.visible = false

func set_ruler_active(active: bool) -> void:
	ruler_button.set_pressed_no_signal(active)

func set_ruler_hint(message: String) -> void:
	ruler_hint_label.text = message
	ruler_hint_label.visible = not message.is_empty()

func toggle_phone() -> void:
	if phone_panel.visible and phone_result_screen.visible and _last_result_won:
		return
	if phone_panel.visible:
		close_phone()
	else:
		phone_panel.visible = true
		_show_menu_screen()
		notes_focus_changed.emit(true)

func toggle_notes() -> void:
	if phone_panel.visible and phone_result_screen.visible and _last_result_won:
		return
	if phone_panel.visible and phone_notes_screen.visible:
		close_phone()
	else:
		phone_panel.visible = true
		_show_notes_screen()

func close_phone() -> void:
	notes_text_edit.release_focus()
	phone_panel.visible = false
	_hide_all_phone_screens()
	notes_focus_changed.emit(false)

func _hide_all_phone_screens() -> void:
	phone_menu_screen.visible = false
	phone_notes_screen.visible = false
	phone_settings_screen.visible = false
	phone_result_screen.visible = false

func _show_menu_screen() -> void:
	notes_text_edit.release_focus()
	_hide_all_phone_screens()
	phone_menu_screen.visible = true
	notes_focus_changed.emit(true)

func _show_notes_screen() -> void:
	_hide_all_phone_screens()
	phone_notes_screen.visible = true
	notes_text_edit.grab_focus()
	notes_focus_changed.emit(true)

func _show_settings_screen() -> void:
	notes_text_edit.release_focus()
	_hide_all_phone_screens()
	phone_settings_screen.visible = true
	notes_focus_changed.emit(true)

func show_result(result: Dictionary) -> void:
	notes_text_edit.release_focus()
	phone_panel.visible = true
	_hide_all_phone_screens()
	phone_result_screen.visible = true

	var won: bool = bool(result.get("won", false))
	_last_result_won = won
	var matched: int = int(result.get("matched_count", 0))
	var total: int = int(result.get("total_count", 0))

	var badge_style := result_face_badge.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	result_close_button.visible = not won
	if won:
		result_emoji_label.text = ":D"
		badge_style.bg_color = Color(0.95, 0.85, 0.3, 1.0)
		result_title_label.text = "Klien Senang!"
		result_title_label.add_theme_color_override("font_color", Color(0.1, 0.55, 0.22, 1.0))
	else:
		result_emoji_label.text = ">:("
		badge_style.bg_color = Color(0.92, 0.28, 0.28, 1.0)
		result_title_label.text = "Klien Marah!"
		result_title_label.add_theme_color_override("font_color", Color(0.75, 0.12, 0.12, 1.0))
	result_face_badge.add_theme_stylebox_override("panel", badge_style)

	result_summary_label.text = "%d dari %d barang sudah simetris" % [matched, total]

	var lines: PackedStringArray = []
	var items: Array = result.get("items", []) as Array
	for entry in items:
		var d: Dictionary = entry as Dictionary
		var item_name: String = str(d.get("display_name", d.get("item_id", "?")))
		if bool(d.get("missing_in_room1", false)):
			lines.append("- %s: belum ada di Ruang 1" % item_name)
		elif bool(d.get("passed", false)):
			lines.append("- %s: pas (selisih %.2f m)" % [item_name, float(d.get("delta_m", 0.0))])
		else:
			lines.append("- %s: meleset %.2f m" % [item_name, float(d.get("delta_m", 0.0))])
	result_details_label.text = "\n".join(lines)
	restart_button.grab_focus()
	notes_focus_changed.emit(true)

func show_toast(message: String) -> void:
	toast_label.text = message
	toast_label.visible = true
	toast_timer.start()

func _on_toast_timer_timeout() -> void:
	toast_label.visible = false

func is_blocking_world_input() -> bool:
	return phone_panel.visible or notes_text_edit.has_focus()

func _on_ruler_button_toggled(toggled_on: bool) -> void:
	ruler_toggled.emit(toggled_on)

func _on_mission_button_pressed() -> void:
	phone_pressed.emit()

func _on_result_close_pressed() -> void:
	if _last_result_won:
		close_phone()
	else:
		_show_menu_screen()

func _on_restart_button_pressed() -> void:
	restart_pressed.emit()

func _on_notes_focus_entered() -> void:
	notes_focus_changed.emit(true)

func _on_notes_focus_exited() -> void:
	notes_focus_changed.emit(is_blocking_world_input())
