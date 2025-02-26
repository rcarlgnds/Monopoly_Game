#extends RigidBody3D
#
#@export var dice_scene: PackedScene
#
#func roll_and_jump():
	#if not dice_scene:
		#dice_scene = load("res://scenes/Dice/Dice.tscn")
		#
	#if not dice_scene:
		#print("Error: Dice scene not assigned!")
		#return
#
	## Tunggu sejenak jika perlu, pastikan posisi player sudah benar
	#await get_tree().process_frame
#
	## Ambil posisi player yang benar
	#var player_pos = position
	#print("Current Player Position:", player_pos)  # Debugging posisi player
#
	## Tentukan posisi spawn dadu (di atas kepala player)
	#var head_offset = 1.8  # Bisa sesuaikan agar dadu tidak spawn di dalam player
	#var dice_position = global_position + Vector3(0, head_offset, 0)  # Spawn tepat di atas player
#
	## Spawn dadu
	#var dice1 = dice_scene.instantiate()
	#var dice2 = dice_scene.instantiate()
	#get_parent().add_child(dice1)
	#get_parent().add_child(dice2)
#
	## Set posisi awal dadu
	#dice1.global_position = dice_position
	#dice2.global_position = dice_position + Vector3(1, 0, 0)  # Sedikit ke samping
#
	#print("Dice Spawn Position 1:", dice1.global_position)  # Debugging posisi dice
	#print("Dice Spawn Position 2:", dice2.global_position)
#
	## Lempar dadu
	#dice1.roll_dice_at_position(dice1.global_position)
	#dice2.roll_dice_at_position(dice2.global_position)
#
	## Tunggu hasil lemparan
	#var roll_result1 = await dice1.roll_finished
	#var roll_result2 = await dice2.roll_finished
	#var total_roll = roll_result1 + roll_result2
#
	#print("Dadu 1:", roll_result1, "Dadu 2:", roll_result2, "Total Lompat:", total_roll)
#
	## Hapus dadu setelah digunakan
	#dice1.queue_free()
	#dice2.queue_free()
#
	## Lompat sesuai hasil dadu
	#jumps(total_roll)
