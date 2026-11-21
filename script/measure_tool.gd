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

func _unhandled_input(event: InputEvent) -> void:
	# 1. Tekan F untuk buka / tutup meteran
	if event.is_action_pressed("measure"):
		toggle_tool()

	if not is_active:
		return

	# 2. Klik Kanan: Gulung / reset meteran
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		reset_measurement()

	# 3. Klik Kiri: Tancapkan atau Kunci meteran
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		handle_click()

func toggle_tool() -> void:
	is_active = !is_active
	if not is_active:
		reset_measurement()
	print("Meteran: ", "AKTIF" if is_active else "NONAKTIF")

func handle_click() -> void:
	if not player:
		return
		
	var mouse_pos = get_global_mouse_position()
	
	if not is_anchored:
		# KLIK 1: Tancapkan titik awal (harus dekat pemain)
		if player.global_position.distance_to(mouse_pos) > MAX_INTERACT_DISTANCE:
			print("Terlalu jauh! Dekati dulu titik awal yang ingin diukur.")
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
	elif not is_locked:
		# KLIK 2: Kunci pengukuran di posisi saat ini
		is_locked = true
		print("Pengukuran terkunci di jarak: ", label.text)
	else:
		# Klik lagi setelah terkunci: Reset untuk mengukur baru
		reset_measurement()

func _process(_delta: float) -> void:
	if is_active and is_anchored and not is_locked and player:
		# Ujung meteran ditarik mengikuti pemain (dengan sedikit kelonggaran mouse dekat pemain)
		var mouse_pos = get_global_mouse_position()
		var pull_pos = player.global_position
		
		# Jika mouse berada dekat dengan pemain, gunakan posisi mouse agar presisi menunjuk objek
		if player.global_position.distance_to(mouse_pos) <= MAX_INTERACT_DISTANCE:
			pull_pos = mouse_pos
			
		var dx = abs(pull_pos.x - anchor_point.x)
		var dy = abs(pull_pos.y - anchor_point.y)
		
		# Kunci hanya lurus horizontal (Sumbu X) atau lurus vertikal (Sumbu Y)
		if dx >= dy:
			current_end_point = Vector2(pull_pos.x, anchor_point.y)
			label.text = "%.0f cm" % dx
		else:
			current_end_point = Vector2(anchor_point.x, pull_pos.y)
			label.text = "%.0f cm" % dy
			
		line.set_point_position(1, current_end_point)
		
		# Letakkan label di tengah garis ukur
		var mid_point = (anchor_point + current_end_point) / 2.0
		# Pusatkan label (ukuran label offset_right 40, offset_bottom 14 -> offset tengah (-20, -12))
		label.global_position = mid_point + Vector2(-20, -10)

func reset_measurement() -> void:
	is_anchored = false
	is_locked = false
	line.clear_points()
	line.visible = false
	label.visible = false
