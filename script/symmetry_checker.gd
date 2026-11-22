extends Node

# Batas toleransi ketepatan simetris (dalam piksel)
const TOLERANSI: float = 8.0


func hitung_evaluasi() -> Dictionary:
	var all_items: Array[Node] = get_parent().find_children("*", "InteractiveItem", true, false)

	var items_ruang1: Dictionary[String, InteractiveItem] = {}
	var items_ruang2: Array[InteractiveItem] = []

	for node in all_items:
		var item := node as InteractiveItem
		if not item or not is_instance_valid(item) or item.is_queued_for_deletion() or not item.visible:
			continue

		var item_id_bersih: String = item.item_id.strip_edges()
		if item_id_bersih == "":
			continue

		var in_room1: bool = (item.override_home_room == 1) or (item.override_home_room != 2 and item.global_position.x < 0.0)
		if in_room1:
			items_ruang1[item_id_bersih] = item
		else:
			items_ruang2.append(item)

	var total_barang: int = items_ruang2.size()
	if total_barang == 0:
		return {
			"grade": "sad",
			"status": "game_over",
			"passed": false,
			"score": 0,
			"total": 0,
			"min_pass_score": 1,
			"text": "GAME OVER\n(0/0)"
		}

	var berhasil_count: int = 0
	var matched_ids: Dictionary[String, bool] = {}

	for item_r2 in items_ruang2:
		var id: String = item_r2.item_id.strip_edges()
		if matched_ids.has(id) or not items_ruang1.has(id):
			continue

		var item_r1: InteractiveItem = items_ruang1[id]
		# Posisi target simetri di Ruang 2 adalah cerminan horizontal dari Ruang 1
		var target_pos := Vector2(-item_r1.global_position.x, item_r1.global_position.y)
		var selisih_total: float = item_r2.global_position.distance_to(target_pos)

		if selisih_total <= TOLERANSI:
			matched_ids[id] = true
			berhasil_count += 1

	var min_pass_score: int = LevelProgression.get_min_pass_score(total_barang)
	if LevelProgression.is_level_passed(berhasil_count, total_barang):
		var is_perfect: bool = berhasil_count == total_barang
		var title: String = "BERHASIL!" if is_perfect else "LULUS!"
		return {
			"grade": "happy" if is_perfect else "neutral",
			"status": "success",
			"passed": true,
			"score": berhasil_count,
			"total": total_barang,
			"min_pass_score": min_pass_score,
			"text": "%s\n(%d/%d)" % [title, berhasil_count, total_barang]
		}

	return {
		"grade": "sad",
		"status": "game_over",
		"passed": false,
		"score": berhasil_count,
		"total": total_barang,
		"min_pass_score": min_pass_score,
		"text": "GAME OVER\n(%d/%d)" % [berhasil_count, total_barang]
	}
