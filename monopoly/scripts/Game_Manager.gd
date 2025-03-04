extends Node3D

var map_generator: Node

@onready var camera_manager = $Map/Camera

var PlayerHelper = preload("res://scripts/Helper/Player_Helper.gd").new()
@onready var knight = preload("res://scenes/Player/Model/Knight_Model.tscn")
@onready var mage = preload("res://scenes/Player/Model/Mage_Model.tscn")
@onready var barbarian = preload("res://scenes/Player/Model/Barbarian_Model.tscn")
@onready var assassin = preload("res://scenes/Player/Model/Assassin_Model.tscn")
@onready var rogue = preload("res://scenes/Player/Model/Rogue_Model.tscn")

# Data 
var players = []
var tiles = []  

var current_turn = 0 
var is_turn_active = false  


func _ready():
	set_process_input(true)
	var map = Map.new(9, 9, 9, -1, 4, "Default")
	map_generator = preload("res://scripts/Helper/Map_Helper.gd").new()
	add_child(map_generator)

	await get_tree().process_frame 

	if map_generator.connect("tiles_ready", Callable(self, "_set_player_position")):
		print("Sinyal tiles_ready berhasil dihubungkan!")
	else:
		print("GAGAL menghubungkan sinyal tiles_ready!")

	map_generator.create_map(map)


func _input(event):
	if event.is_action_pressed("down"):
		if camera_manager:
			camera_manager.switch_camera()
		else:
			print("ERROR: camera_manager belum terinisialisasi!")
	
	if Input.is_action_just_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			get_tree().quit()

	if Input.is_action_just_pressed("up"):
		roll_dice()


func create_player(p_id: String, p_nickname: String, p_skin: String) -> Node3D:
	var player_instance
	
	match p_skin:
		"Knight":
			player_instance = knight.instantiate()
		"Mage":
			player_instance = mage.instantiate()
		"Barbarian":
			player_instance = barbarian.instantiate()
		"Assassin":
			player_instance = assassin.instantiate()
		"Rogue":
			player_instance = rogue.instantiate()
		_:
			print("WARNING: Skin tidak dikenal, default ke Knight.")
			player_instance = knight.instantiate() 
			
	player_instance.init_player(p_id, p_nickname, p_skin) 
	add_child(player_instance) 
	return player_instance

	
func _set_player_position():
	if map_generator.has_method("get_tiles"):
		tiles = map_generator.get_tiles()  
		print("Tiles Generated:", tiles.size())  

		if tiles.size() > 0:
			var first_tile = tiles[0]  
			var first_tile_pos = first_tile.tile_coordinate + Vector3(0, 5, 0)  
			spawn_player(first_tile_pos)
		else:
			print("ERROR: Tidak ada tile yang tersedia!")
	else:
		print("ERROR: map_generator tidak memiliki method get_tiles!")


func spawn_player(spawn_pos: Vector3):
	var player_1 = create_player("001", "IO", "Barbarian")
	var player_2 = create_player("002", "JZ", "Mage")
	var player_3 = create_player("003", "ZZ", "Knight")

	add_child(player_1)
	add_child(player_2)
	add_child(player_3)

	players.append(player_1)
	players.append(player_2)
	players.append(player_3)

	# Atur posisi pemain di awal
	var spawn_offsets = [
		Vector3(0, 0, 0),
		Vector3(2, 0, 0),
		Vector3(-2, 0, 0)
	]

	player_1.set_spawn_position(spawn_pos + spawn_offsets[0])
	player_2.set_spawn_position(spawn_pos + spawn_offsets[1])
	player_3.set_spawn_position(spawn_pos + spawn_offsets[2])

	player_1.set_tile_objects(tiles)
	player_2.set_tile_objects(tiles)
	player_3.set_tile_objects(tiles)

	print("Player 1 spawned:", player_1.nickname)
	print("Player 2 spawned:", player_2.nickname)
	print("Player 3 spawned:", player_3.nickname)



# Dice & Turn
@export var dice_scene: PackedScene

var total_dice_result = 0  
var pending_dice_rolls = 0 

func get_center_position(map_size: int, tile_size: float) -> Vector3:
	var total_size = (map_size - 1) * tile_size
	var center_x = total_size / 2
	var center_z = total_size / 2
	
	return Vector3(center_x, 4.5, center_z)
	
	
func roll_dice():
	if is_turn_active:
		print("Player masih berjalan! Tunggu giliran selesai.")
		return  

	is_turn_active = true 

	if not dice_scene:
		dice_scene = load("res://scenes/Dice/Dice.tscn")  
		
	if not dice_scene:
		print("Error: Dice scene not assigned!")
		return

	await get_tree().process_frame  

	var dice_positions = [
		get_center_position(11, 2) + Vector3(33, 5, 15),
		get_center_position(11, 2) + Vector3(25, 5, 17)
	]

	total_dice_result = 0  
	pending_dice_rolls = dice_positions.size()  

	for pos in dice_positions:
		var dice_instance = dice_scene.instantiate()
		get_parent().add_child(dice_instance)  
		dice_instance.roll_dice_at_position(pos)

		dice_instance.roll_finished.connect(_on_dice_roll_finished)

		print("Dadu dilempar di posisi:", pos)



func _on_dice_roll_finished(dice_result: int):
	total_dice_result += dice_result  
	pending_dice_rolls -= 1  

	if pending_dice_rolls == 0:  
		print("Total hasil dadu:", total_dice_result)
		var current_player = players[current_turn]
		
		print("Giliran:", current_player.nickname)
		current_player.jumps(total_dice_result)  

		await current_player.finished_moving  

		next_turn()  

func next_turn():
	current_turn = (current_turn + 1) % players.size()  
	is_turn_active = false  
	print("Sekarang giliran:", players[current_turn].nickname)
