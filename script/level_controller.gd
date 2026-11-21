extends Node2D

@export var max_room2_entries: int = 3
@export var room2_time_limit: float = 25.0
@export var center_x: float = 0.0
@export var floor_y: float = 0.0
@export var pixels_per_meter: float = 40.0
@export var room1_spawn_x: float = -40.0
@export var room2_spawn_x: float = 40.0

@onready var player: CharacterBody2D = $Player
@onready var door_portal: Area2D = $DoorPortal
@onready var measure_tool: Node2D = $MeasureTool
@onready var symmetry_checker: Node = $SymmetryChecker
@onready var hud: CanvasLayer = $HUD

var entries_remaining: int = 3
var current_room: int = 1
var time_remaining: float = 0.0
var is_level_ended: bool = false

func _ready() -> void:
	entries_remaining = max_room2_entries
	current_room = 1
	time_remaining = room2_time_limit
	is_level_ended = false

	door_portal.portal_requested.connect(_on_portal_requested)
	measure_tool.active_changed.connect(_on_measure_tool_active_changed)
	measure_tool.hint_requested.connect(_on_measure_tool_hint_requested)
	measure_tool.step_changed.connect(hud.set_ruler_hint)
	hud.ruler_toggled.connect(_on_hud_ruler_toggled)
	hud.phone_pressed.connect(_on_phone_pressed)
	hud.restart_pressed.connect(_on_restart_pressed)
	hud.notes_focus_changed.connect(_on_hud_notes_focus_changed)
	for item: InteractiveItem in _get_interactive_items():
		item.drag_rejected.connect(hud.show_toast)

	measure_tool.set_room_context(current_room, center_x, floor_y, pixels_per_meter)
	door_portal.update_prompt(current_room, entries_remaining)
	hud.update_status(current_room, entries_remaining, max_room2_entries, time_remaining)
	_refresh_input_locks()

func _process(delta: float) -> void:
	if current_room == 2 and not is_level_ended:
		time_remaining -= delta
		if time_remaining <= 0.0:
			force_expire_room2_timer()
			return
		hud.update_status(current_room, entries_remaining, max_room2_entries, time_remaining)

func force_expire_room2_timer() -> void:
	if current_room != 2:
		return
	time_remaining = 0.0
	_enter_room(1)
	hud.show_toast("Waktu di Ruang 2 habis! Kembali ke Ruang 1.")

func _on_portal_requested(from_room: int) -> void:
	if is_level_ended:
		return
	if from_room == 1:
		if entries_remaining <= 0:
			hud.show_toast("Kuota masuk Ruang 2 sudah habis!")
			door_portal.update_prompt(current_room, entries_remaining)
			return
		entries_remaining -= 1
		time_remaining = room2_time_limit
		_enter_room(2)
	else:
		_enter_room(1)

func _enter_room(target_room: int) -> void:
	current_room = target_room
	_cancel_all_item_drags()
	measure_tool.reset_measurement()
	measure_tool.set_room_context(current_room, center_x, floor_y, pixels_per_meter)
	var spawn_x: float = room2_spawn_x if current_room == 2 else room1_spawn_x
	door_portal.teleport_player_to(player, current_room, spawn_x)
	door_portal.update_prompt(current_room, entries_remaining)
	hud.update_status(current_room, entries_remaining, max_room2_entries, time_remaining)

func _cancel_all_item_drags() -> void:
	for item: InteractiveItem in _get_interactive_items():
		item.cancel_drag()

func _get_interactive_items() -> Array[InteractiveItem]:
	var items: Array[InteractiveItem] = []
	for node: Node in find_children("*", "InteractiveItem", true, false):
		var item := node as InteractiveItem
		if item != null:
			items.append(item)
	return items

func _on_hud_ruler_toggled(active: bool) -> void:
	if is_level_ended:
		hud.set_ruler_active(false)
		return
	measure_tool.set_active(active)

func _on_measure_tool_active_changed(active: bool) -> void:
	hud.set_ruler_active(active)
	_refresh_input_locks()

func _on_measure_tool_hint_requested(message: String) -> void:
	hud.show_toast(message)

func _on_hud_notes_focus_changed(_is_typing: bool) -> void:
	_refresh_input_locks()

func _refresh_input_locks() -> void:
	var ui_blocked: bool = is_level_ended or hud.is_blocking_world_input()
	player.input_locked = ui_blocked
	door_portal.set_input_blocked(ui_blocked)
	measure_tool.set_input_blocked(ui_blocked)
	var item_blocked: bool = ui_blocked or measure_tool.is_active
	for item: InteractiveItem in _get_interactive_items():
		item.interaction_blocked = item_blocked

func _on_phone_pressed() -> void:
	if is_level_ended:
		return
	if current_room != 1:
		hud.show_toast("Kembali ke Ruang 1 dulu sebelum menyelesaikan misi!")
		return
	var result: Dictionary = symmetry_checker.evaluate_symmetry(center_x, pixels_per_meter)
	is_level_ended = bool(result.get("won", false))
	measure_tool.set_active(false)
	_cancel_all_item_drags()
	hud.show_result(result)
	_refresh_input_locks()

func _on_restart_pressed() -> void:
	get_tree().reload_current_scene()
