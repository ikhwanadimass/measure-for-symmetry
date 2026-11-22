extends Node

# Batas toleransi ketepatan simetris (dalam piksel)
const TOLERANSI: float = 8.0

var skor_terakhir: float = 0.0

func evaluasi() -> Dictionary:
	return hitung_evaluasi()

func hitung_evaluasi() -> Dictionary:
	var all_items = get_parent().find_children("*", "InteractiveItem", true, false)
	
	var items_ruang1 = {}
	var items_ruang2 = {}
	
	for item in all_items:
		var item_id_bersih = item.item_id.strip_edges()
		if item.global_position.x < 0:
			items_ruang1[item_id_bersih] = item
		else:
			items_ruang2[item_id_bersih] = item

	var total_barang: int = items_ruang2.size()
	if total_barang == 0:
		skor_terakhir = 0.0
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
		# Posisi target simetri di Ruang 2 adalah cerminan dari Ruang 1
		var target_x = -item_r1.global_position.x
		var target_y = item_r1.global_position.y
		
		var selisih_x = abs(item_r2.global_position.x - target_x)
		var selisih_y = abs(item_r2.global_position.y - target_y)
		var selisih_total = sqrt(selisih_x * selisih_x + selisih_y * selisih_y)
		
		if selisih_total <= TOLERANSI:
			berhasil_count += 1

	var rasio: float = float(berhasil_count) / float(total_barang)
	skor_terakhir = rasio * 100.0
	
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
