@tool
extends EditorScript

func _run() -> void:
	var scene = get_scene()
	if not scene:
		print("Buka scene Level01.tscn terlebih dahulu!")
		return
		
	var tilemap = scene.get_node_or_null("TileMapLayer") as TileMapLayer
	if not tilemap:
		print("Node TileMapLayer tidak ditemukan!")
		return

	var cells = tilemap.get_used_cells()
	var count = 0
	
	for cell in cells:
		# Hanya ambil ubin yang ada di sisi kiri (Ruang 1, x < 0)
		if cell.x < 0:
			var source_id = tilemap.get_cell_source_id(cell)
			var atlas_coords = tilemap.get_cell_atlas_coords(cell)
			var alt_tile = tilemap.get_cell_alternative_tile(cell)
			
			# Cerminkan posisinya ke sisi kanan (Ruang 2)
			var mirrored_x = -cell.x - 1
			var mirrored_cell = Vector2i(mirrored_x, cell.y)
			
			tilemap.set_cell(mirrored_cell, source_id, atlas_coords, alt_tile)
			count += 1

	print("Berhasil! Sebanyak %d ubin telah dicerminkan ke Ruang 2." % count)
