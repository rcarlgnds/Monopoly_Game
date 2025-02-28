extends Node3D

var map_generator: Node

@onready var camera_manager = $Map/Camera

var player  
var tile_objects = []  


# Player
var Players = []
var PlayerHelper = preload("res://scripts/Helper/Player_Helper.gd").new()
var player_scenes = {
	"Knight": preload("res://scenes/Player/Instance/Knight.tscn"),
	"Mage": preload("res://scenes/Player/Instance/Mage.tscn")
}


func _ready():
	set_process_input(true)

	# Buat instance map baru
	var map = Map.new(9, 9, 8.5, -1, 4, "Default")

	map_generator = preload("res://scripts/Helper/Map_Helper.gd").new()
	add_child(map_generator)

	await get_tree().process_frame 

	if map_generator.connect("tiles_ready", Callable(self, "_set_player_position")):
		print("Sinyal tiles_ready berhasil dihubungkan!")
	else:
		print("GAGAL menghubungkan sinyal tiles_ready!")

	map_generator.create_map(map)  # Generate map

func create_player(p_id: String, p_nickname: String, p_skin: String) -> Node3D:
	var player_instance = knight_scene.instantiate()  # Buat instance player dari scene
	player_instance.init_player(p_id, p_nickname, p_skin)  # Set ID, Nickname, Skin, dll.
	add_child(player_instance)  # Tambahkan ke scene game
	return player_instance
	
	
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
	var new_player = create_player("001", "IO", "Knight")
	add_child(new_player)
	
	Players.append(new_player)
	new_player.set_spawn_position(spawn_pos)
	new_player.set_tile_objects(tile_objects)
	
	print("Player spawned:", new_player.nickname)


func _input(event):
	if event.is_action_pressed("down"):
		if camera_manager:
			camera_manager.switch_camera()
		else:
			print("ERROR: camera_manager belum terinisialisasi!")
