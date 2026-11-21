extends Node

var current_level: int = 1
var unlocked_level: int = 1

var level_scenes: Dictionary = {
	1: "res://scene/Level01.tscn",
}

func load_level(level_num: int) -> void:
	if level_scenes.has(level_num):
		current_level = level_num
		get_tree().paused = false
		get_tree().change_scene_to_file(level_scenes[level_num])
	else:
		print("Scene untuk Level %d belum dibuat!" % level_num)

func lanjutkan_game() -> void:
	load_level(current_level)
