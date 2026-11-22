extends Node

enum Stage {
	MOVEMENT,       # 1. Jalan & Lompat di Ruang 1 (Ruangan bersih tanpa meja)
	GO_TO_ROOM2,    # 2. Masuk portal ke Ruang 2
	MEASURE_ROOM2,  # 3. Meja Ruang 2 muncul -> Ukur dengan meteran [F]
	BACK_TO_ROOM1,  # 4. Kembali ke Ruang 1
	ARRANGE_ROOM1,  # 5. Meja Ruang 1 & bayangan target muncul -> Seret meja sampai pas
	COMPLETE        # 6. Selesai & Evaluasi di HP
}

var current_stage: Stage = Stage.MOVEMENT

# Flag pelacak input & tahap
var has_moved: bool = false
var has_jumped: bool = false
var has_measured: bool = false
var stage_timer: float = 0.0

const TOLERANSI_SELESAI: float = 12.0

@onready var player: CharacterBody2D = get_parent().get_node_or_null("Player")
@onready var table_room1: Node2D = get_parent().get_node_or_null("Table_Room1")
@onready var table_room2: Node2D = get_parent().get_node_or_null("Table_Room2")
@onready var instruction_label: Label = get_parent().get_node_or_null("TutorialBoards/BoardInstruction/InstructionLabel")

var hud_banner: CanvasLayer = null
var hud_label: Label = null
var target_ghost_sprite: Sprite2D = null

func _ready() -> void:
	buat_hud_banner_bawah()
	buat_bayangan_target_di_ruang1()
	
	# Sembunyikan semua meja di awal (ruangan bersih)
	atur_visibilitas_meja(table_room1, false)
	atur_visibilitas_meja(table_room2, false)
	if target_ghost_sprite:
		target_ghost_sprite.visible = false
		
	perbarui_tampilan_instruksi()

func buat_hud_banner_bawah() -> void:
	hud_banner = CanvasLayer.new()
	hud_banner.layer = 10
	add_child(hud_banner)
	
	var root = Control.new()
	root.layout_mode = 1
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_banner.add_child(root)
	
	var panel = PanelContainer.new()
	panel.layout_mode = 1
	panel.anchors_preset = Control.PRESET_BOTTOM_WIDE
	panel.offset_left = 140.0
	panel.offset_right = -140.0
	panel.offset_top = -48.0
	panel.offset_bottom = -10.0
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(panel)
	
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.14, 0.42, 0.30, 0.95) # Hijau Chalkboard
	sb.corner_radius_top_left = 6
	sb.corner_radius_top_right = 6
	sb.corner_radius_bottom_left = 6
	sb.corner_radius_bottom_right = 6
	sb.border_width_top = 2
	sb.border_color = Color(0.35, 0.75, 0.55, 1.0)
	panel.add_theme_stylebox_override("panel", sb)
	
	hud_label = Label.new()
	hud_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hud_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hud_label.add_theme_font_size_override("font_size", 13)
	hud_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	hud_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(hud_label)

func get_target_x_ruang1() -> float:
	if table_room2:
		return -abs(table_room2.global_position.x)
	return -80.0

func buat_bayangan_target_di_ruang1() -> void:
	if table_room1:
		target_ghost_sprite = Sprite2D.new()
		target_ghost_sprite.name = "TargetGhostTableRoom1"
		target_ghost_sprite.texture = load("res://asset/tileseet/CartoonRooms/separate images/table_small_1.png")
		target_ghost_sprite.scale = Vector2(1.5227, 1.2794)
		target_ghost_sprite.position = Vector2(get_target_x_ruang1(), -9.0)
		target_ghost_sprite.modulate = Color(0.2, 0.8, 1.0, 0.45)
		get_parent().add_child.call_deferred(target_ghost_sprite)

func atur_visibilitas_meja(meja: Node2D, aktif: bool) -> void:
	if not meja: return
	meja.visible = aktif
	if "input_pickable" in meja:
		meja.input_pickable = aktif
	var col = meja.find_child("CollisionShape2D", true, false)
	if col:
		col.set_deferred("disabled", not aktif)

func _process(delta: float) -> void:
	match current_stage:
		Stage.MOVEMENT:
			if Input.is_action_pressed("move_left") or Input.is_action_pressed("move_right"):
				has_moved = true
			if Input.is_action_just_pressed("jump"):
				has_jumped = true
			
			if has_moved and has_jumped:
				stage_timer += delta
				if stage_timer >= 1.0:
					ganti_tahap(Stage.GO_TO_ROOM2)
					
		Stage.GO_TO_ROOM2:
			if player and player.global_position.x > 0:
				stage_timer += delta
				if stage_timer >= 0.5:
					ganti_tahap(Stage.MEASURE_ROOM2)
					
		Stage.MEASURE_ROOM2:
			if Input.is_action_just_pressed("measure"):
				has_measured = true
			if has_measured:
				stage_timer += delta
				if stage_timer >= 2.0:
					ganti_tahap(Stage.BACK_TO_ROOM1)
					
		Stage.BACK_TO_ROOM1:
			if player and player.global_position.x < 0:
				stage_timer += delta
				if stage_timer >= 0.5:
					ganti_tahap(Stage.ARRANGE_ROOM1)
					
		Stage.ARRANGE_ROOM1:
			if table_room1:
				var target_x = get_target_x_ruang1()
				var jarak_selisih = abs(table_room1.global_position.x - target_x)
				var is_dragging = table_room1.get("is_dragging") if "is_dragging" in table_room1 else false
				
				if jarak_selisih <= TOLERANSI_SELESAI and not is_dragging:
					stage_timer += delta
					if target_ghost_sprite:
						target_ghost_sprite.modulate = Color(0.2, 1.0, 0.3, 0.8)
					if stage_timer >= 0.8:
						ganti_tahap(Stage.COMPLETE)

func ganti_tahap(tahap_baru: Stage) -> void:
	current_stage = tahap_baru
	stage_timer = 0.0
	
	# Memunculkan meja sesuai tahap yang berkaitan:
	if current_stage == Stage.MEASURE_ROOM2:
		atur_visibilitas_meja(table_room2, true) # Meja patokan Ruang 2 muncul!
	elif current_stage == Stage.ARRANGE_ROOM1:
		atur_visibilitas_meja(table_room1, true) # Meja Ruang 1 muncul!
		if target_ghost_sprite:
			target_ghost_sprite.visible = true # Bayangan target biru muncul!
			
	perbarui_tampilan_instruksi()

func perbarui_tampilan_instruksi() -> void:
	var teks_papan: String = ""
	var teks_hud: String = ""
	
	match current_stage:
		Stage.MOVEMENT:
			teks_papan = "TAHAP 1: GERAK DASAR\n\nTekan [A] / [D] untuk jalan.\nTekan [W] / [Spasi] untuk lompat."
			teks_hud = "Tahap 1: Coba tekan [A] / [D] untuk berjalan dan [W] / [Spasi] untuk melompat."
		Stage.GO_TO_ROOM2:
			teks_papan = "TAHAP 2: KE RUANG 2\n\nDekati Pintu Portal lalu tekan [E] untuk melihat meja patokan di Ruang 2."
			teks_hud = "Tahap 2: Dekati Pintu Portal lalu tekan [E] untuk masuk ke Ruang 2 (Ruang Patokan)."
		Stage.MEASURE_ROOM2:
			teks_papan = "TAHAP 3: UKUR PATOKAN\n\nTekan [F] untuk meteran.\nUkur jarak meja patokan dari batas pintu tengah."
			teks_hud = "Tahap 3: Tekan [F] untuk meteran. Ukur jarak meja patokan dari pintu tengah!"
		Stage.BACK_TO_ROOM1:
			teks_papan = "TAHAP 4: KEMBALI KE RUANG 1\n\nSudah ingat jaraknya?\nLewati Pintu Portal [E] lagi untuk menata Ruang 1."
			teks_hud = "Tahap 4: Ingat jaraknya! kamu juga bisa memakai note(N) Lewati Pintu Portal [E] untuk kembali menata Ruang 1."
		Stage.ARRANGE_ROOM1:
			teks_papan = "TAHAP 5: TATA MEJA SIMETRIS\n\nDekati meja di Ruang 1.\nKlik kiri & seret meja sampai pas masuk ke bayangan target!"
			teks_hud = "Tahap 5: Dekati meja di Ruang 1, klik kiri & seret meja sampai pas ke bayangan biru!"
		Stage.COMPLETE:
			teks_papan = "SELESAI!\n\nMeja sudah simetris sempurna!\nBuka HP [Tab] atau tekan [M] untuk evaluasi."
			teks_hud = "Hebat! Posisi meja sudah simetris. Tekan [M] atau buka HP [Tab] untuk evaluasi misi."

	if instruction_label:
		instruction_label.text = teks_papan
	if hud_label:
		hud_label.text = teks_hud
