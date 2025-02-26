extends Node3D

@onready var spec_1 = $Spectator_1
@onready var spec_2 = $Spectator_2
@onready var spec_dice = $Spectator_Dice

var active_camera
var player_cam

# Sensitivitas zoom dan batas zoom
var zoom_sensitivity = 2.0  
var min_fov = 30.0
var max_fov = 90.0

# Perubahan posisi kamera saat zoom
var zoom_position_offset = Vector3(0, -0.5, -0.5)
var zoom_rotation_offset = Vector3(-2, 0, 0)

func _ready():
	# Set kamera awal ke Spectator_1
	active_camera = spec_1
	spec_1.current = true
	spec_2.current = false  
	spec_dice.current = false  # Nonaktifkan awalnya

	# Ambil referensi posisi tengah dari Map
	var map = get_parent().get_node("Map")  
	if map:
		var center_pos = map.get_center_position(map)  
		spec_dice.position = center_pos + Vector3(0, 20, 0) 

	print("Kamera dice ditempatkan di:", spec_dice.position)


func set_player_camera(cam: Camera3D):
	"""Menyimpan referensi kamera player."""
	player_cam = cam

func switch_camera():
	"""Mengganti antara kamera Spectator 1, Spectator 2, Player, dan Spec Dice."""
	if active_camera == spec_1:
		active_camera = spec_2
	elif active_camera == spec_2:
		active_camera = spec_dice
	elif active_camera == spec_dice:
		active_camera = player_cam if player_cam else spec_1
	else:
		active_camera = spec_1  

	# Update status kamera
	spec_1.current = (active_camera == spec_1)
	spec_2.current = (active_camera == spec_2)
	spec_dice.current = (active_camera == spec_dice)
	if player_cam:
		player_cam.current = (active_camera == player_cam)

	print("Kamera berpindah ke:", active_camera.name if active_camera else "None")
