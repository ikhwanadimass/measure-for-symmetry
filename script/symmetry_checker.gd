extends Node

# Batas toleransi ketepatan (dalam piksel)
const TOLERANSI: float = 6.0

func _unhandled_input(event: InputEvent) -> void:
	# Tekan tombol ENTER untuk mengecek
	if event.is_action_pressed("ui_accept"):
		evaluasi_simetri()

func evaluasi_simetri() -> void:
	var all_items = get_parent().find_children("*", "InteractiveItem", true, false)
	
	var items_ruang1 = {}
	var items_ruang2 = {}
	
	for item in all_items:
		if item.global_position.x < 0:
			items_ruang1[item.item_id] = item
		else:
			items_ruang2[item.item_id] = item

	print("\n================== 📊 PENGECEKAN SIMETRI ==================")
	
	if items_ruang2.is_empty():
		print("⚠️ Tidak ada barang acuan di Ruang 2!")
		return
		
	for id in items_ruang2:
		var item_r2 = items_ruang2[id]
		
		if not items_ruang1.has(id):
			print("❌ Barang '%s' belum ditaruh di Ruang 1!" % id)
			continue
			
		var item_r1 = items_ruang1[id]
		
		# Patokan adalah POSISI AWAL Ruang 2 sebelum digeser-geser pemain
		var ref_pos = item_r2.initial_position
		var target_x = -ref_pos.x
		var target_y = ref_pos.y
		
		var selisih_x = abs(item_r1.global_position.x - target_x)
		var selisih_y = abs(item_r1.global_position.y - target_y)
		var selisih_total = sqrt(selisih_x * selisih_x + selisih_y * selisih_y)
		
		print("📦 Barang: [%s]" % id)
		print("   Posisi Awal Ruang 2 (Patokan) : (X: %.1f, Y: %.1f)" % [ref_pos.x, ref_pos.y])
		print("   Target Simetris Ruang 1       : (X: %.1f, Y: %.1f)" % [target_x, target_y])
		print("   Posisi Anda di Ruang 1        : (X: %.1f, Y: %.1f)" % [item_r1.global_position.x, item_r1.global_position.y])
		print("   Selisih Jarak                 : %.1f px (ΔX: %.1f px, ΔY: %.1f px)" % [selisih_total, selisih_x, selisih_y])
		
		# Validasi Simpel Sesuai Permintaan Anda:
		if selisih_total <= TOLERANSI:
			print("   🎉 STATUS: BERHASIL SIMETRIS! (Dapat ⭐)")
		else:
			print("   ❌ STATUS: BELUM SIMETRIS (Meleset %.1f px)" % selisih_total)

	print("==========================================================\n")
