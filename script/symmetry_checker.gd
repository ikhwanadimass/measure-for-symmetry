extends Node

# Batas toleransi ketepatan (dalam piksel)
const TOLERANSI: float = 6.0

# Pasangan ruang (work_room, reference_room). Untuk 4 ruang: [Vector2i(1, 2), Vector2i(3, 4)]
@export var room_pairs: Array[Vector2i] = [Vector2i(1, 2)]

func evaluate_symmetry(center_x: float = 0.0, pixels_per_meter: float = 40.0) -> Dictionary:
	var all_items: Array[Node] = get_parent().find_children("*", "InteractiveItem", true, false)

	var rooms_map: Dictionary = {}
	for node: Node in all_items:
		var item := node as InteractiveItem
		if item == null:
			continue
		var r_id: int = item.room_id if item.room_id > 0 else (1 if item.global_position.x < center_x else 2)
		if not rooms_map.has(r_id):
			rooms_map[r_id] = {}
		(rooms_map[r_id] as Dictionary)[item.item_id] = item

	var results: Array[Dictionary] = []
	var matched_count: int = 0
	var total_count: int = 0
	var safe_ppm: float = maxf(pixels_per_meter, 1.0)

	for pair: Vector2i in room_pairs:
		var work_items: Dictionary = rooms_map.get(pair.x, {}) as Dictionary
		var ref_items: Dictionary = rooms_map.get(pair.y, {}) as Dictionary
		total_count += ref_items.size()

		for id_key in ref_items.keys():
			var item_id: String = str(id_key)
			var item_ref: InteractiveItem = ref_items[id_key] as InteractiveItem

			if not work_items.has(id_key):
				results.append({
					"item_id": item_id,
					"display_name": item_ref.get_display_name(),
					"room_pair": pair,
					"passed": false,
					"delta_px": -1.0,
					"delta_m": -1.0,
					"missing_in_room1": true,
				})
				continue

			var item_work: InteractiveItem = work_items[id_key] as InteractiveItem
			var ref_pos: Vector2 = item_ref.initial_position
			var target_x: float = 2.0 * center_x - ref_pos.x
			var target_y: float = ref_pos.y

			var selisih_x: float = absf(item_work.global_position.x - target_x)
			var selisih_y: float = absf(item_work.global_position.y - target_y)
			var selisih_total: float = sqrt(selisih_x * selisih_x + selisih_y * selisih_y)
			var item_passed: bool = selisih_total <= TOLERANSI
			if item_passed:
				matched_count += 1

			results.append({
				"item_id": item_id,
				"display_name": item_ref.get_display_name(),
				"room_pair": pair,
				"passed": item_passed,
				"delta_px": selisih_total,
				"delta_m": selisih_total / safe_ppm,
				"missing_in_room1": false,
			})

	var won: bool = total_count > 0 and matched_count == total_count
	return {
		"won": won,
		"matched_count": matched_count,
		"total_count": total_count,
		"items": results,
	}
