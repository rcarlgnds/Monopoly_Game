extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const TILE_SIZE = 2.0  # Ukuran tile (sesuai dengan ukuran map)

#@onready var game_manager = get_tree().get_root().get_node("Game_Manager")
@export var sens = 0.002  
@export_range(0.0, 1.0) var mouse_sensitivity := 0.25

@export_group("Camera")
@onready var _camera_pivot: Node3D = %CameraPivot
@onready var model_animation = get_node("Knight")

@onready var player_camera = %Camera3D


var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var _camera_input_direction := Vector2.ZERO
var _last_movement_direction := Vector3.BACK

# Buat dapetin tiles object dr game manager
var tile_array = []
func set_tile_objects(tiles):
	tile_array = tiles
	print("Received tile_objects in Player_Helper:")
	for i in range(tile_array.size()):
		print("Tile", i, ":", tile_array[i].tile_coordinate)


func _ready():
	await get_tree().process_frame  # Tunggu satu frame agar semua node siap
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	# Load dice scene secara manual jika belum diassign

func _input(event):
	if event.is_action_pressed("left_click"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		
	if Input.is_action_just_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			get_tree().quit()

	if Input.is_action_just_pressed("up"):
		roll_and_jump()


func _unhandled_input(event: InputEvent) -> void:
	var is_camera_motion := (
		event is InputEventMouseMotion and 
		Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
	)
	
	if is_camera_motion:
		_camera_input_direction = event.screen_relative * mouse_sensitivity
		

func _physics_process(delta: float) -> void:
	_camera_pivot.rotation.x += _camera_input_direction.y * delta
	_camera_pivot.rotation.x = clamp(_camera_pivot.rotation.x, -PI / 6.0, PI / 3.0)
	_camera_pivot.rotation.y -= _camera_input_direction.x * delta
	
	_camera_input_direction = Vector2.ZERO
	
	if not is_on_floor():
		velocity.y -= gravity * delta

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		
	move_and_slide()

func get_center_position(map_size: int, tile_size: float) -> Vector3:
	# Pastikan map_size adalah jumlah tile (bukan panjang total)
	var total_size = (map_size - 1) * tile_size
	var center_x = total_size / 2
	var center_z = total_size / 2
	
	# Tinggi dice bisa disesuaikan
	return Vector3(center_x, 4.5, center_z)


func set_spawn_position(spawn_pos: Vector3):
	"""Atur posisi spawn player di atas tile pertama."""
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
	var tile_size = 6.5  # Ukuran tile (berdasarkan pola koordinat)
	var offset = 2  # Seberapa jauh player lompat ke luar

	# 4. Hitung vektor perubahan posisi antar tile
	var delta = next_tile.tile_coordinate - current_tile.tile_coordinate

	# 5. Tentukan arah lompat berdasarkan delta
	var jump_target = next_tile.tile_coordinate

	if abs(delta.x) > abs(delta.z):  
		if delta.x > 0: 
			jump_target += Vector3(0, 5.5, -offset)
		else: 
			jump_target += Vector3(0, 5.5, offset)
	else:  
		if delta.z > 0:  
			jump_target += Vector3(offset, 5.5, 0)
		else: 
			jump_target += Vector3(-offset, 5.5, 0)

	# 6. Hitung arah ke target
	var direction = (jump_target - position).normalized()

	# 7. Konversi arah ke rotasi Yaw
	var target_rotation = atan2(direction.x, direction.z)
	var current_yaw = global_rotation.y
	
	var diff = target_rotation - current_yaw
	if diff > PI:
		diff -= TAU
	elif diff < -PI:
		diff += TAU
	var shortest_target = current_yaw + diff

	# 8. Buat muter dulu sebelum lompat
	var tween = get_tree().create_tween()
	tween.tween_property(self, "global_rotation:y", shortest_target, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tween.finished

	# 9. Animasi lompat
	tween = get_tree().create_tween()
	tween.tween_property(self, "position", jump_target, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	print("Jumping to:", jump_target, "(Tile Index:", next_index, ") Facing Direction:", direction)


func jumps(dice_result: int):
	# Lompat sesuai angka yang didapat
	for i in range(dice_result):
		jump()
		await get_tree().create_timer(0.8).timeout

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


# Dice
@export var dice_scene: PackedScene

var total_dice_result = 0  # Variabel untuk menyimpan total hasil dadu
var pending_dice_rolls = 0  # Menghitung jumlah dadu yang sedang diproses

func roll_and_jump():
	if not dice_scene:
		dice_scene = load("res://scenes/Dice/Dice.tscn")  # Load jika belum terhubung
		
	if not dice_scene:
		print("Error: Dice scene not assigned!")
		return

	await get_tree().process_frame  # Tunggu satu frame agar posisi aman

	var dice_positions = [
		get_center_position(11, 2) + Vector3(33, 5, 15),
		get_center_position(11, 2) + Vector3(27, 5, 15)  # Tambah jarak biat kaga nabrak daduny
	]

	total_dice_result = 0  # Reset hasil total
	pending_dice_rolls = dice_positions.size()  # Hitung jumlah dadu yang akan dilempar

	for pos in dice_positions:
		var dice_instance = dice_scene.instantiate()
		get_parent().add_child(dice_instance)  # Add dadu ke scene

		dice_instance.roll_dice_at_position(pos)

		# Connect sinyal roll_finished ke fungsi yang mengumpulkan hasil
		dice_instance.roll_finished.connect(_on_dice_roll_finished)

		print("Dadu dilempar di posisi:", pos)

func _on_dice_roll_finished(dice_result: int):
	total_dice_result += dice_result  # Tambahkan hasil dadu ke total
	pending_dice_rolls -= 1  # Kurangi jumlah dadu yang belum selesai

	if pending_dice_rolls == 0:  # Jika semua dadu sudah selesai
		print("Total hasil dadu:", total_dice_result)
		jumps(total_dice_result)  # Lompat sesuai hasil total
