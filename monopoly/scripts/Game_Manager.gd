extends Node3D

var map_generator: Node
@onready var player_scene = preload("res://scenes/Player_A.tscn")  
@onready var camera_manager = $Map/Camera

var player  
var tile_objects = []  

var PlayerHelper = load("res://scripts/Helper/Player_Helper.gd")
var player_helper = PlayerHelper.new()  

func _ready():
	set_process_input(true)

	# Buat instance map baru
	var map = Map.new(9, 9, 6.5, -0.2, 3.2, "Default")

	map_generator = preload("res://scripts/Helper/Map_Helper.gd").new()
	add_child(map_generator)

	await get_tree().process_frame 

	if map_generator.connect("tiles_ready", Callable(self, "_set_player_position")):
		print("Sinyal tiles_ready berhasil dihubungkan!")
	else:
		print("GAGAL menghubungkan sinyal tiles_ready!")

	map_generator.create_map(map)  # Generate map

func _set_player_position():
	if map_generator.has_method("get_tiles"):
		tile_objects = map_generator.get_tiles()  
		print("Tiles Generated:", tile_objects.size())  

		if tile_objects.size() > 0:
			var first_tile = tile_objects[0]  
			var first_tile_pos = first_tile.tile_coordinate + Vector3(0, 5, 0)  
			spawn_player(first_tile_pos)
		else:
			print("ERROR: Tidak ada tile yang tersedia!")
	else:
		print("ERROR: map_generator tidak memiliki method get_tiles!")

func spawn_player(spawn_pos: Vector3):
	if player == null:
		player = player_scene.instantiate()
		add_child(player)
		print("Player spawned!")

		player.set_spawn_position(spawn_pos)
		player.set_tile_objects(tile_objects)

func _input(event):
	if event.is_action_pressed("down"):
		if camera_manager:
			camera_manager.switch_camera()
		else:
			print("ERROR: camera_manager belum terinisialisasi!")
