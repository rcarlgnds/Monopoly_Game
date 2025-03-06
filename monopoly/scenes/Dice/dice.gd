extends RigidBody3D

@onready var raycasts = $Raycasts.get_children()

var start_pos
var roll_strength = 30
var is_rolling = false
signal roll_finished(value)

var dice_values = {
	"DiceRaycast1": 6,
	"DiceRaycast2": 5,
	"DiceRaycast3": 4,
	"DiceRaycast4": 3,
	"DiceRaycast5": 2,
	"DiceRaycast6": 1
}


func _ready():
	start_pos = global_position
	mass = 10

func roll_dice_at_position(pos, rotation, throw_vector):
	global_position = pos + Vector3(35, 15, 35)
	_roll(rotation, throw_vector)

func _roll(rotation, throw_vector_dice):
	sleeping = false
	freeze = false
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	
	transform.basis = Basis(Vector3.RIGHT, rotation[0]) * transform.basis
	transform.basis = Basis(Vector3.UP, rotation[1]) * transform.basis
	transform.basis = Basis(Vector3.FORWARD, rotation[2]) * transform.basis
	print("dice vector data:", throw_vector_dice)
	
	var throw_vector = Vector3(throw_vector_dice[0], throw_vector_dice[1], throw_vector_dice[2]).normalized()
	
	angular_velocity = throw_vector * roll_strength / 2 
	apply_central_force(throw_vector * roll_strength)
	is_rolling = true
	
	
func _on_sleeping_state_changed() -> void:
	print("Sleeping: ", sleeping)
	if sleeping:
		var landed_value = null

		for raycast in raycasts:
			raycast.force_raycast_update()
			var is_hit = raycast.is_colliding()
		
			print("Is Hit: ", is_hit)
			
			if is_hit:
				print("Dadu mendarat pada: %s" % raycast.name)
				landed_value = dice_values.get(raycast.name, null)  
				
				if landed_value == null:
					print("❌ ERROR: %s tidak ditemukan di dice_values!" % raycast.name)
				else:
					print("✅ Nilai dadu:", landed_value)
					break 

		if landed_value != null:
			roll_finished.emit(landed_value)  # Kirim sinyal dengan angka dadu
			await get_tree().create_timer(2.0).timeout  # Tunggu sebelum hapus
			queue_free()  # Hapus dadu
		else:
			print("❌ ERROR: Tidak ada raycast yang mendeteksi tabrakan!")
