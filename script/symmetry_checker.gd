extends Node

# Batas toleransi ketepatan simetris (dalam piksel)
const TOLERANSI: float = 6.0

func hitung_evaluasi() -> Dictionary:
	var all_items = get_parent().find_children("*", "InteractiveItem", true, false)
	
	var items_ruang1 = {}
	var items_ruang2 = {}
	
	for item in all_items:
		if item.global_position.x < 0:
			items_ruang1[item.item_id] = item
		else:
			items_ruang2[item.item_id] = item

	var total_barang: int = items_ruang2.size()
	if total_barang == 0:
		return {
			"grade": "sad",
			"status": "game_over",
			"text": "GAME OVER\n(0/0)"
		}

	var berhasil_count: int = 0

	for id in items_ruang2:
		var item_r2 = items_ruang2[id]
		if not items_ruang1.has(id):
			continue
			
		var item_r1 = items_ruang1[id]
		var ref_pos = item_r2.initial_position
		var target_x = -ref_pos.x
		var target_y = ref_pos.y
		
		var selisih_x = abs(item_r1.global_position.x - target_x)
		var selisih_y = abs(item_r1.global_position.y - target_y)
		var selisih_total = sqrt(selisih_x * selisih_x + selisih_y * selisih_y)
		
		if selisih_total <= TOLERANSI:
			berhasil_count += 1

	var rasio: float = float(berhasil_count) / float(total_barang)
	
	if rasio >= 0.8:
		return {
			"grade": "happy",
			"status": "success",
			"text": "BERHASIL!\n(%d/%d)" % [berhasil_count, total_barang]
		}
	elif rasio >= 0.4:
		return {
			"grade": "neutral",
			"status": "medium",
			"text": "SEDANG\n(%d/%d)" % [berhasil_count, total_barang]
		}
	else:
		return {
			"grade": "sad",
			"status": "game_over",
			"text": "GAME OVER\n(%d/%d)" % [berhasil_count, total_barang]
		}
