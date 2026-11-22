extends Node

const SAVE_PATH = "user://save_data.json"
const DEFAULT_LEVEL_SCENE: String = "res://scene/level/Level01.tscn"

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
	1: "res://scene/level/Level01.tscn",
	2: "res://scene/level/Level02.tscn",
	3: "res://scene/level/Level03.tscn",
	4: "res://scene/level/Level04.tscn",
	5: "res://scene/level/Level05.tscn",
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

func get_total_objects_for_level(level_num: int = -1) -> int:
	var target_level: int = current_level if level_num <= 0 else level_num
	return LevelProgression.get_total_objects(target_level)

func get_min_pass_score_for_level(level_num: int = -1) -> int:
	return LevelProgression.get_min_pass_score(get_total_objects_for_level(level_num))

func get_max_level() -> int:
	var max_lvl: int = 1
	for k in level_scenes.keys():
		var lvl: int = int(k)
		if lvl > max_lvl:
			max_lvl = lvl
	return max_lvl

func has_level(level_num: int) -> bool:
	return level_scenes.has(level_num)

func buka_level_berikutnya() -> int:
	var max_lvl: int = get_max_level()
	var next_lvl: int = mini(current_level + 1, max_lvl)
	if unlocked_level < next_lvl:
		unlocked_level = next_lvl
	current_level = next_lvl
	save_to_disk()
	print("Level Baru Terbuka! Level tertinggi: %d (aktif: %d)" % [unlocked_level, current_level])
	return next_lvl

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

func load_level(level_num: int, auto_start: bool = true) -> void:
	current_level = maxi(1, level_num)
	is_replaying = auto_start

	var target_path: String = level_scenes.get(current_level, "")
	if target_path == "" or not ResourceLoader.exists(target_path):
		var tree := get_tree()
		if tree and tree.current_scene and tree.current_scene.scene_file_path != "":
			target_path = tree.current_scene.scene_file_path
		else:
			target_path = DEFAULT_LEVEL_SCENE

	var tree := get_tree()
	if not tree:
		return
	tree.paused = false
	if tree.current_scene and tree.current_scene.scene_file_path == target_path:
		tree.call_deferred("reload_current_scene")
	else:
		tree.call_deferred("change_scene_to_file", target_path)

func retry_current_level() -> void:
	is_replaying = true
	var tree := get_tree()
	if not tree:
		return
	tree.paused = false
	tree.call_deferred("reload_current_scene")
