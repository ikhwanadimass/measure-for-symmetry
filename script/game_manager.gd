extends Node

const SAVE_PATH = "user://save_data.json"

# Status Save & Pemain
var has_save: bool = false
var save_name: String = "Player 1"
var current_level: int = 1
var unlocked_level: int = 1
var current_mode: int = 1 # 0: Ringan, 1: Biasa, 2: Hard, 3: Bebas

# Penanda apakah pemain sedang mengulang level (agar tidak dilempar ke menu utama)
var is_replaying: bool = false

# Data Pengaturan Tiap Mode
var mode_data: Dictionary = {
	0: {"name": "Mode Ringan", "waktu": 180.0, "max_masuk": 5},
	1: {"name": "Mode Biasa", "waktu": 120.0, "max_masuk": 3},
	2: {"name": "Mode Hard", "waktu": 60.0, "max_masuk": 2},
	3: {"name": "Mode Bebas", "waktu": 0.0, "max_masuk": 9999}
}

var level_scenes: Dictionary = {
	1: "res://scene/Level01.tscn",
}

func _ready() -> void:
	load_from_disk()

func get_mode_info() -> Dictionary:
	return mode_data.get(current_mode, mode_data[1])

func buat_save_baru(nama: String, mode_idx: int) -> void:
	save_name = nama if nama.strip_edges() != "" else "Player 1"
	current_mode = mode_idx
	current_level = 1
	unlocked_level = 1
	has_save = true
	save_to_disk()
	print("Save Baru Dibuat & Disimpan ke Disk! Nama: %s | Mode: %s" % [save_name, mode_data[current_mode]["name"]])

func buka_level_berikutnya() -> void:
	if current_level == unlocked_level:
		unlocked_level += 1
	current_level += 1
	save_to_disk()
	print("Level Baru Terbuka! Level tertinggi: %d" % unlocked_level)

# ===== SIMPAN & MUAT DARI FILE DISK =====
func save_to_disk() -> void:
	var data = {
		"has_save": has_save,
		"save_name": save_name,
		"current_level": current_level,
		"unlocked_level": unlocked_level,
		"current_mode": current_mode
	}
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()

func load_from_disk() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var json_str = file.get_as_text()
		file.close()
		var parsed = JSON.parse_string(json_str)
		if parsed is Dictionary:
			has_save = parsed.get("has_save", false)
			save_name = parsed.get("save_name", "Player 1")
			current_level = int(parsed.get("current_level", 1))
			unlocked_level = int(parsed.get("unlocked_level", 1))
			current_mode = int(parsed.get("current_mode", 1))
			print("Data Save Berhasil Dimuat dari Disk! Pemain: %s" % save_name)

func load_level(level_num: int) -> void:
	if level_scenes.has(level_num):
		current_level = level_num
		get_tree().paused = false
		get_tree().change_scene_to_file(level_scenes[level_num])
	else:
		print("Scene untuk Level %d belum dibuat!" % level_num)
