extends Node2D

const MAX_INTERACT_DISTANCE: float = 35.0 

@onready var line: Line2D = $Line2D
@onready var label: Label = $DistanceLabel

var player: CharacterBody2D = null
var is_active: bool = false
var anchor_point: Vector2 = Vector2.ZERO
var current_end_point: Vector2 = Vector2.ZERO
var is_anchored: bool = false
var is_locked: bool = false

func _ready() -> void:
	line.visible = false
	label.visible = false
	player = get_parent().get_node_or_null("Player")
	update_hud_status()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("measure"):
		toggle_tool()

	if not is_active:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		reset_measurement()

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		handle_click()

func toggle_tool() -> void:
	is_active = !is_active
	var am = get_node_or_null("/root/AudioManager")
	if am: am.play_sfx("measure", -4.0)
	
	if not is_active:
		reset_measurement()
	update_hud_status()

func update_hud_status() -> void:
	var phone = get_tree().current_scene.find_child("Smartphone", true, false)
	if phone and phone.has_method("set_status_meteran"):
		phone.set_status_meteran(is_active)

func handle_click() -> void:
	if not player: return
	var mouse_pos = get_global_mouse_position()
	
	if not is_anchored:
		if player.global_position.distance_to(mouse_pos) > MAX_INTERACT_DISTANCE:
			return
			
		anchor_point = mouse_pos
		current_end_point = anchor_point
		is_anchored = true
		is_locked = false
		line.visible = true
		label.visible = true
		line.clear_points()
		line.add_point(anchor_point)
		line.add_point(anchor_point)
		# Suara klik ditiadakan agar hening saat menancapkan meteran
	elif not is_locked:
		is_locked = true
		# Suara klik ditiadakan saat mengunci meteran

func _process(_delta: float) -> void:
	if is_active and is_anchored and not is_locked and player:
		var mouse_pos = get_global_mouse_position()
		var pull_pos = player.global_position
		
		if player.global_position.distance_to(mouse_pos) <= MAX_INTERACT_DISTANCE:
			pull_pos = mouse_pos
			
		var dx = abs(pull_pos.x - anchor_point.x)
		var dy = abs(pull_pos.y - anchor_point.y)
		
		if dx >= dy:
			current_end_point = Vector2(pull_pos.x, anchor_point.y)
			label.text = "%.0f cm" % dx
		else:
			current_end_point = Vector2(anchor_point.x, pull_pos.y)
			label.text = "%.0f cm" % dy
			
		line.set_point_position(1, current_end_point)
		
		var mid_point = (anchor_point + current_end_point) / 2.0
		label.global_position = mid_point + Vector2(-20, -10)

func reset_measurement() -> void:
	if is_anchored:
		var am = get_node_or_null("/root/AudioManager")
		if am: am.play_sfx("measure", -6.0)
	is_anchored = false
	is_locked = false
	line.visible = false
	label.visible = false
