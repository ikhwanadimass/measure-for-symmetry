extends Node

const SAVE_PATH = "user://saves.json"
const OLD_SLOT_PATH = "user://save_slots.json"
const OLD_SINGLE_PATH = "user://save_data.json"
const DEFAULT_LEVEL_SCENE: String = "res://scene/level/Level01.tscn"

# Status Profil Save yang Sedang Aktif
var active_save_id: String = ""
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
	6: "res://scene/level/Level06.tscn",
	7: "res://scene/level/Level07.tscn",
	8: "res://scene/level/Level08.tscn",
	9: "res://scene/level/Level09.tscn",
	10: "res://scene/level/Level10.tscn",
}

# Daftar profil save dinamis (setiap buat game baru, bertambah 1)
var saves_list: Array = []

func _ready() -> void:
	load_from_disk()

func get_mode_info() -> Dictionary:
	return mode_data.get(current_mode, mode_data[1])

func buat_save_baru(nama: String, mode_idx: int) -> String:
	var p_name = nama.strip_edges()
	if p_name.is_empty():
		p_name = "Player %d" % (saves_list.size() + 1)
		
	var new_id = "save_%d_%d" % [int(Time.get_unix_time_from_system()), randi() % 1000]
	var new_save = {
		"id": new_id,
		"save_name": p_name,
		"current_mode": mode_idx,
		"current_level": 1,
		"unlocked_level": 1,
		"timestamp": Time.get_datetime_string_from_system(false, true)
	}
	saves_list.append(new_save)
	load_save_by_id(new_id)
	print("Game Baru Berhasil Dibuat! ID: %s | Nama: %s | Mode: %s" % [new_id, p_name, mode_data[current_mode]["name"]])
	return new_id

func load_save_by_id(save_id: String) -> bool:
	for s in saves_list:
		if s.get("id", "") == save_id:
			active_save_id = save_id
			save_name = s.get("save_name", "Player")
			current_mode = int(s.get("current_mode", 1))
			current_level = int(s.get("current_level", 1))
			unlocked_level = int(s.get("unlocked_level", 1))
			has_save = true
			save_to_disk()
			print("Profil Save Dimuat: %s | Level Terbuka: %d" % [save_name, unlocked_level])
			return true
	return false

func delete_save_by_id(save_id: String) -> void:
	for i in range(saves_list.size() - 1, -1, -1):
		if saves_list[i].get("id", "") == save_id:
			saves_list.remove_at(i)
			break
			
	if active_save_id == save_id:
		has_save = false
		if not saves_list.is_empty():
			load_save_by_id(saves_list[0].get("id", ""))
		else:
			active_save_id = ""
			save_name = "Player 1"
			current_level = 1
			unlocked_level = 1
			has_save = false
			
	save_to_disk()
	print("Save dengan ID %s Berhasil Dihapus!" % save_id)

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
	
	# Simpan progres ke save yang sedang aktif
	for s in saves_list:
		if s.get("id", "") == active_save_id:
			s["unlocked_level"] = unlocked_level
			s["current_level"] = current_level
			s["timestamp"] = Time.get_datetime_string_from_system(false, true)
			break
			
	save_to_disk()
	print("Level Baru Terbuka! Level tertinggi: %d (aktif: %d) pada Save: %s" % [unlocked_level, current_level, save_name])
	return next_lvl

# ===== SIMPAN & MUAT DARI FILE DISK =====
func save_to_disk() -> void:
	var data = {
		"active_save_id": active_save_id,
		"saves": saves_list
	}
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()

func load_from_disk() -> void:
	# 1. Cek file saves.json
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file:
			var json_str = file.get_as_text()
			file.close()
			var parsed = JSON.parse_string(json_str)
			if parsed is Dictionary and parsed.has("saves"):
				saves_list = parsed.get("saves", [])
				active_save_id = str(parsed.get("active_save_id", ""))
				
				# Terapkan save aktif
				if not load_save_by_id(active_save_id) and not saves_list.is_empty():
					load_save_by_id(saves_list[0].get("id", ""))
				return

	# 2. Migrasi dari save_slots.json jika ada
	if FileAccess.file_exists(OLD_SLOT_PATH):
		var file = FileAccess.open(OLD_SLOT_PATH, FileAccess.READ)
		if file:
			var json_str = file.get_as_text()
			file.close()
			var parsed = JSON.parse_string(json_str)
			if parsed is Dictionary and parsed.has("slots"):
				var slots = parsed.get("slots", {})
				for k in slots.keys():
					var s = slots[k]
					if not s.get("is_empty", true):
						var mig_id = "save_migrated_%s" % k
						saves_list.append({
							"id": mig_id,
							"save_name": s.get("save_name", "Player %s" % k),
							"current_mode": s.get("current_mode", 1),
							"current_level": s.get("current_level", 1),
							"unlocked_level": s.get("unlocked_level", 1),
							"timestamp": s.get("timestamp", Time.get_datetime_string_from_system(false, true))
						})
				if not saves_list.is_empty():
					load_save_by_id(saves_list[0]["id"])
					save_to_disk()
					print("Migrasi dari save_slots.json Berhasil!")
					return

	# 3. Migrasi dari save_data.json lama sekali jika ada
	if FileAccess.file_exists(OLD_SINGLE_PATH):
		var file = FileAccess.open(OLD_SINGLE_PATH, FileAccess.READ)
		if file:
			var json_str = file.get_as_text()
			file.close()
			var parsed = JSON.parse_string(json_str)
			if parsed is Dictionary and parsed.get("has_save", false):
				var mig_id = "save_migrated_old"
				saves_list.append({
					"id": mig_id,
					"save_name": parsed.get("save_name", "Player 1"),
					"current_mode": parsed.get("current_mode", 1),
					"current_level": parsed.get("current_level", 1),
					"unlocked_level": parsed.get("unlocked_level", 1),
					"timestamp": Time.get_datetime_string_from_system(false, true)
				})
				load_save_by_id(mig_id)
				save_to_disk()
				print("Migrasi dari save_data.json Berhasil!")

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
