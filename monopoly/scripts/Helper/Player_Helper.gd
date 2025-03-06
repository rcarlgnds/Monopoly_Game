extends CharacterBody3D

@export var player_id: String = "" 
# Object
var id: String
var nickname: String
var skin: String
var current_tile: int
var money: float

func init_player(p_id: String, p_nickname: String, p_skin: String):
	id = p_id
	nickname = p_nickname
	skin = p_skin
	current_tile = 0
	money = 50.0


# Animation
@onready var model = $Rig
@onready var anim_tree = $AnimationTree
@onready var anim_state = $AnimationTree.get("parameters/playback")

var melee_attack_animation = [
	"One_Handed_A",
	"One_Handed_B",
	"One_Handed_C",
	"Dual_A",
	"Dual_B",
	"Kick"
]

var magic_attack_animation = [
	"Magic_A",
	"Magic_B"
]

var ranged_attack_animation = [
	"Shoot",
	"Kick"
]

const JUMP_VELOCITY = 4.5
var jumping = false
var last_floor = true
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")


# Buat dapetin tiles object dr game manager
var tile_array = []
func set_tile_objects(tiles):
	tile_array = tiles
	print("Received tile_objects in Player_Helper:")
	for i in range(tile_array.size()):
		print("Tile", i, ":", tile_array[i].tile_coordinate)


func _ready():
	await get_tree().process_frame  
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

		
func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("down") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		jumping = true
		anim_tree.set("parameters/conditions/jumping", true)
		anim_tree.set("parameters/conditions/grounded", false)
	if is_on_floor() and not last_floor:
		jumping = false
		anim_tree.set("parameters/conditions/jumping", false)
		anim_tree.set("parameters/conditions/grounded", true)
	if not is_on_floor() and not jumping:
		anim_state.travel("Jump_Idle")
		anim_tree.set("parameters/conditions/grounded", false)
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	last_floor = is_on_floor()
	move_and_slide()
	

func set_spawn_position(spawn_pos: Vector3):
	position = spawn_pos
	print("Player spawned at:", position)


func jump():
	if tile_array.is_empty():
		print("No tiles available!")
		return

	# 1. Cari tile terdekat dari posisi sekarang
	var current_tile = find_nearest_tile(position, tile_array)
	if current_tile == null:
		print("No tile found near player position!")
		return
	
	# 2. Ambil index tile sekarang
	var current_index = tile_array.find(current_tile)
	if current_index == -1:
		print("Current tile not found in array!")
		return
	
	# 3. Tentukan tile target
	var next_index = current_index - 1
	if next_index < 0:
		next_index = tile_array.size() - 1 

	var next_tile = tile_array[next_index]
	var tile_size = 6.5 
	var offset = 2 

	# 4. Hitung batas koordinat untuk deteksi tile pojok
	var min_x = tile_array[0].tile_coordinate.x
	var max_x = min_x
	var min_z = tile_array[0].tile_coordinate.z
	var max_z = min_z

	for tile in tile_array:
		min_x = min(min_x, tile.tile_coordinate.x)
		max_x = max(max_x, tile.tile_coordinate.x)
		min_z = min(min_z, tile.tile_coordinate.z)
		max_z = max(max_z, tile.tile_coordinate.z)

	# 5. Cek apakah next_tile adalah tile pojok
	var is_corner_tile = (
		(next_tile.tile_coordinate.x == min_x and next_tile.tile_coordinate.z == min_z) or  # Pojok kiri atas
		(next_tile.tile_coordinate.x == max_x and next_tile.tile_coordinate.z == min_z) or  # Pojok kanan atas
		(next_tile.tile_coordinate.x == min_x and next_tile.tile_coordinate.z == max_z) or  # Pojok kiri bawah
		(next_tile.tile_coordinate.x == max_x and next_tile.tile_coordinate.z == max_z)     # Pojok kanan bawah
	)

	# 6. Jika tile pojok, lompat ke tengahnya
	var jump_target
	var jump_height = 6.5
	if is_corner_tile:
		jump_target = next_tile.tile_coordinate + Vector3(0, jump_height, 0) 
	else:
		# 7. Hitung vektor perubahan posisi antar tile
		var delta = next_tile.tile_coordinate - current_tile.tile_coordinate

		# 8. Tentukan arah lompat berdasarkan delta
		jump_target = next_tile.tile_coordinate

		if abs(delta.x) > abs(delta.z):  
			if delta.x > 0: 
				jump_target += Vector3(0, jump_height, offset)
			else: 
				jump_target += Vector3(0, jump_height, -offset)
		else:  
			if delta.z > 0:  
				jump_target += Vector3(-offset, jump_height, 0)
			else: 
				jump_target += Vector3(offset, jump_height, 0)

	# 9. Hitung arah ke target
	var direction = (jump_target - position).normalized()

	# 10. Konversi arah ke rotasi Yaw
	var target_rotation = atan2(direction.x, direction.z)
	var current_yaw = global_rotation.y
	
	var diff = target_rotation - current_yaw
	if diff > PI:
		diff -= TAU
	elif diff < -PI:
		diff += TAU
	var shortest_target = current_yaw + diff

	# 11. Buat muter dulu sebelum lompat
	var tween = get_tree().create_tween()
	tween.tween_property(self, "global_rotation:y", shortest_target, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tween.finished

	# 12. Animasi lompat
	tween = get_tree().create_tween()
	tween.tween_property(self, "position", jump_target, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	print("Jumping to:", jump_target, "(Tile Index:", next_index, ") Facing Direction:", direction)

signal finished_moving
func jumps(dice_result: int):
	for i in range(dice_result):
		jump()
		await get_tree().create_timer(1.2).timeout
	 
	finished_moving.emit()


func find_nearest_tile(player_pos: Vector3, tile_objects):
	"""Cari tile terdekat dengan posisi player berdasarkan koordinatnya."""
	var closest_tile = null
	var closest_distance = INF
	
	for tile in tile_objects:
		var tile_pos = tile.tile_coordinate  
		var dist = player_pos.distance_to(tile_pos)
		if dist < closest_distance:
			closest_distance = dist
			closest_tile = tile
	
	return closest_tile


func set_player_id(id:String):
	player_id = id
	print(player_id)
	
	
func get_player_id() -> String:
	return player_id
	
