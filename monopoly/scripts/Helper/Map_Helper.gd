extends Node3D

signal tiles_ready

var tiles: Array = []
var tile_id_counter: int = 0 

# Fungsi ini sekarang mengembalikan array objek Tile, bukan hanya posisi
func get_tiles():
	return tiles
	

func create_map(map: Map):
	# Apus semua tile sebelumnya
	for tile in tiles:
		tile.queue_free()
	tiles.clear()
	tile_id_counter = 0  # Reset ID

	var ordered_tiles = []  # Simpen urutan tile

	# Utk tile di sisi atas (dari kiri ke kanan)
	for z in range(map.size_b):
		ordered_tiles.append(Vector2(0, z))

	# Utk tile di sisi kanan (dari atas ke bawah)
	for x in range(1, map.size_a):
		ordered_tiles.append(Vector2(x, map.size_b - 1))

	# Utk tile di sisi bawah (dari kanan ke kiri)
	for z in range(map.size_b - 2, -1, -1):
		ordered_tiles.append(Vector2(map.size_a - 1, z))

	# Utk tile di sisi kiri (dari bawah ke atas)
	for x in range(map.size_a - 2, 0, -1):
		ordered_tiles.append(Vector2(x, 0))

	# Buat tile berdasarkan urutan 
	for tile_pos in ordered_tiles:
		var x = tile_pos.x
		var z = tile_pos.y
		var tile = create_tile(x, z, map)
		if tile:
			tiles.append(tile)

	# Utk 4 tile di tengah arena
	create_center_tiles(map)

	print("Tiles selesai dibuat dalam urutan yang benar:", tiles.size())

	emit_signal("tiles_ready")
	print("Sinyal tiles_ready dipancarkan!")



func create_tile(x: int, z: int, map: Map) -> Tile:
	var tile_asset_path = "res://Assets/Terrain_Assets/Models/GLB format/block-grass-large.glb"
	var tile_scene = load(tile_asset_path)
	if not tile_scene:
		print("ERROR: Model GLB gagal di-load!")
		return null

	var tile_position = Vector3(x * map.tile_gap, map.tile_height, z * map.tile_gap)
	var tile_instance = tile_scene.instantiate()

	if tile_instance:
		# Buat objek Tile dengan properti
		var tile_name = "Tile_" + str(tile_id_counter)
		var tile_obj = Tile.new(tile_id_counter, tile_name, tile_position)

		# Tambajin instance Tile ke scene
		tile_instance.position = tile_position
		tile_instance.scale = Vector3(map.tile_scale, map.tile_scale, map.tile_scale)
		tile_instance.set_meta("tile_data", tile_obj)  # Simpan Tile sebagai metadata

		add_child(tile_instance)
		print("Tile Generated:", tile_obj.tile_name, "at", tile_obj.tile_coordinate)

		tile_id_counter += 1  
		return tile_obj
	else:
		print("ERROR: instantiate() gagal!")
		return null


func create_center_tiles(map: Map):
	var tile_asset_path = "res://Assets/Terrain_Assets/Models/GLB format/block-moving-blue.glb"
	var fence_asset_path = "res://Assets/Terrain_Assets/Models/GLB format/fence-corner-curved.glb"

	var tile_scene = load(tile_asset_path)
	var fence_scene = load(fence_asset_path)

	if not tile_scene or not fence_scene:
		print("ERROR: Model GLB gagal di-load!")
		return

	var center_tile_count = floor(min(map.size_a, map.size_b) / 3)
	var center_x = (map.size_a - center_tile_count) / 2.0
	var center_z = (map.size_b - center_tile_count) / 2.0

	var tile_scale_factor = 2.5
	var fence_scale_factor = 2.3

	# 🟦 Buat center tiles
	for dx in range(center_tile_count):
		for dz in range(center_tile_count):
			var tile_instance = tile_scene.instantiate()
			if tile_instance:
				var tile_position = Vector3(
					(center_x + dx) * map.tile_gap,
					map.tile_height,
					(center_z + dz) * map.tile_gap
				)
				tile_instance.position = tile_position
				tile_instance.scale = Vector3(
					map.tile_scale * tile_scale_factor, 
					map.tile_scale * tile_scale_factor, 
					map.tile_scale * tile_scale_factor
				)
				add_child(tile_instance)

	# Tambahin pagar buat center tile  
	var fence_positions = [
		Vector3(center_x * map.tile_gap, map.tile_height, center_z * map.tile_gap),  # Kiri Atas
		Vector3((center_x + center_tile_count - 1) * map.tile_gap, map.tile_height, center_z * map.tile_gap),  # Kanan Atas
		Vector3(center_x * map.tile_gap, map.tile_height, (center_z + center_tile_count - 1) * map.tile_gap),  # Kiri Bawah
		Vector3((center_x + center_tile_count - 1) * map.tile_gap, map.tile_height, (center_z + center_tile_count - 1) * map.tile_gap)  # Kanan Bawah
	]

	var fence_rotations = [-90, 180, 0, 90]  # Rotasi untuk masing-masing sudut

	for i in range(4):
		var fence_instance = fence_scene.instantiate()
		if fence_instance:
			fence_instance.position = fence_positions[i] + Vector3(0, 3, 0)  # 🔼 Naikkan tinggi pagar
			fence_instance.rotation_degrees.y = fence_rotations[i]  # Putar pagar sesuai posisinya
			fence_instance.scale = Vector3(
				map.tile_scale * fence_scale_factor, 
				map.tile_scale * fence_scale_factor, 
				map.tile_scale * fence_scale_factor
			)
			add_child(fence_instance)
			print("Pagar ditambahkan di", fence_positions[i], "dengan rotasi", fence_rotations[i])
