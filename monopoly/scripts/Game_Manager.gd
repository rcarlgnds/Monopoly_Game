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
var players = {}
var tiles = []

var current_turn = 0 
var is_turn_active = false  

# Socket
var ws_client: SocketClient

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
	
	# Init Socket Client
	ws_client = SocketClient.new()
	add_child(ws_client)
	
	if ws_client:
		ws_client.connect_to_server()
		ws_client.connect("player_joined", Callable(self, "_on_player_joined"))
		ws_client.connect("player_left", Callable(self, "_on_player_left"))
		ws_client.connect("dice_rolled", Callable(self, "_on_dice_rolled"))
		ws_client.connect("player_jumped", Callable(self, "_on_player_jump"))
		ws_client.connect("turn_synced", Callable(self, "_on_turn_synced"))
	else:
		print("❌ Failed To Connect to Socket Server!")
		
	await get_tree().create_timer(1.0).timeout 
	init_dice()


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
		"Knight": player_instance = knight.instantiate()
		"Mage": player_instance = mage.instantiate()
		"Barbarian": player_instance = barbarian.instantiate()
		"Assassin": player_instance = assassin.instantiate()
		"Rogue": player_instance = rogue.instantiate()
		_: player_instance = knight.instantiate()

	player_instance.init_player(p_id, p_nickname, p_skin) 
	add_child(player_instance) 
	return player_instance

func spawn_player(playerID: String, spawn_pos: Vector3, p_skin: String):
	if players.has(playerID):
		return

	var new_player = create_player(playerID, "Player" + str(players.size() + 1), p_skin)
	new_player.global_transform.origin = spawn_pos 
	new_player.set_spawn_position(spawn_pos)
	new_player.set_tile_objects(tiles)
	new_player.set_player_id(playerID)
	players[playerID] = new_player
	
func _set_player_position():
	if map_generator.has_method("get_tiles"):
		tiles = map_generator.get_tiles()  
		print("Tiles Generated:", tiles.size())  
	else:
		print("ERROR: map_generator tidak memiliki method get_tiles!")

func _on_player_joined(player_id: String, spawn_pos: Vector3, player_skin: String):
	if ws_client and ws_client.player_id == player_id:
		return

	if not players.has(player_id):
		spawn_player(player_id, spawn_pos, player_skin)

func _on_player_left(player_id: String):
	if players.has(player_id):
		var player_to_remove = players[player_id]
		if player_to_remove:
			player_to_remove.queue_free()  
			await get_tree().process_frame  
		players.erase(player_id)

# Dice & Turn
@export var dice_scene: PackedScene

var total_dice_result = 0  
var pending_dice_rolls = 0 

func get_center_position(map_size: int, tile_size: float) -> Vector3:
	var total_size = (map_size - 1) * tile_size
	return Vector3(total_size / 2, 4.5, total_size / 2)

func roll_dice():
	if is_turn_active or players.size() == 0:
		return  

	print("turn:", ws_client.current_turn_player_id)
	print("player kuntul", ws_client.player_id)
	if ws_client.player_id != ws_client.current_turn_player_id:
		print("⛔ Not your turn! Current turn:", ws_client.current_turn_player_id)
		return  

	is_turn_active = true  
	var current_player = players[ws_client.current_turn_player_id]
	print("🎲 Player rolling dice:", current_player.get_player_id())

	await get_tree().create_timer(0.2).timeout

	if not dice_scene:
		dice_scene = load("res://scenes/Dice/Dice.tscn")  
	if not dice_scene:
		print("❌ Error: Dice scene not assigned!")
		return

	var dice_positions = [
		get_center_position(11, 2) + Vector3(33, 5, 15),
		get_center_position(11, 2) + Vector3(25, 5, 17)
	]

	for child in get_children():
		if child.name.begins_with("Dice"):
			child.queue_free()

	total_dice_result = 0  
	pending_dice_rolls = dice_positions.size()  

	var dice_data = {
		"player_id": current_player.get_player_id(),
		"dice_positions": []
	}

	for pos in dice_positions:
		dice_data["dice_positions"].append({"x": pos.x, "y": pos.y, "z": pos.z})  

	print("📡 Broadcasting Dice Roll:", JSON.stringify(dice_data))
	ws_client.send_to_server("roll_dice", dice_data)



func _spawn_dice(pos: Vector3, rotations:Vector3, throw_vector: Vector3) -> Node3D:
	print("🛠️ Spawning dice at:", pos)
	var dice_instance = dice_scene.instantiate()
	add_child(dice_instance) 
	dice_instance.global_transform.origin = pos
	dice_instance.roll_dice_at_position(pos, rotations, throw_vector)
	dice_instance.roll_finished.connect(_on_dice_roll_finished)
	return dice_instance

func _on_dice_rolled(dice_positions, rotations, throw_vector):
	print("🎲 Dice positions received:", dice_positions)
	print("rotations:", rotations)
	print("throw vector:", throw_vector)

	var rotation_vec = Vector3.ZERO
	if typeof(rotations) == TYPE_ARRAY and rotations.size() >= 3:
		rotation_vec = Vector3(float(rotations[0]), float(rotations[1]), float(rotations[2]))

	if typeof(dice_positions) == TYPE_ARRAY:
		for pos in dice_positions:
			if typeof(pos) == TYPE_DICTIONARY and "x" in pos and "y" in pos and "z" in pos:
				var spawn_pos = Vector3(float(pos["x"]), float(pos["y"]), float(pos["z"]))
				_spawn_dice(spawn_pos, rotation_vec, throw_vector)  
				print("✅ Dice spawned at", spawn_pos)
			else:
				print("⚠️ Invalid dice position format:", pos)
	else:
		print("❌ Error: dice_positions bukan Array!", dice_positions)

		
func _on_dice_roll_finished(dice_result: int):
	total_dice_result += dice_result  
	pending_dice_rolls -= 1  

	if pending_dice_rolls == 0:  
		#var current_player = players.values()[current_turn]
		var current_player = players[ws_client.current_turn_player_id]
		print("testt:",current_player.id)
		print("Players Dictionary:", players)
		print("Current Turn Player ID:", ws_client.current_turn_player_id)
		print("Player Exists:", players.has(ws_client.current_turn_player_id))

		#var current_player = players[ws_client.current_turn_player_id.id
		print("roll dice current player", current_player)
		var move_data = {
			"player_id": current_player.get_player_id(),
			"steps": total_dice_result
		}
		
		ws_client.send_to_server("player_jump", move_data)
		
		current_player.jumps(total_dice_result)  
		await current_player.finished_moving  
		next_turn()
		
func _on_player_jump(player_id: String, steps: int):
	print("player jump", steps)
	print("Players", players[player_id].id)
	if players.has(player_id):
		var player = players[player_id]
		player.jumps(steps)
	else:
		print("Failed to jump")
		
	
func _on_turn_synced(player_id):
	print("🌀 Turn Synced! Now it's Player", player_id, "'s turn!")

func next_turn():
	if players.size() == 0:
		print("⚠️ No players available for the next turn!")
		return
	
	is_turn_active = false
	print("🎲 It's Player", players.keys()[current_turn], "'s turn!")


	
func init_dice():
	if not dice_scene:
		dice_scene = load("res://scenes/Dice/Dice.tscn")
	if not dice_scene:
		print("❌ Error: Dice scene not assigned!")
		return

	var dice_positions = [
		get_center_position(11, 2) + Vector3(33, 5, 15),
		get_center_position(11, 2) + Vector3(25, 5, 17)
	]
#

	
