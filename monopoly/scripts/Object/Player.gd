#class_name Player
#extends Node3D 
#
#var id: String
#var nickname: String
#var skin: String
#var current_tile: int
#var money: float
#
#func _init(p_id: String, p_nickname: String, p_skin: String):
	#id = p_id
	#nickname = p_nickname
	#skin = p_skin
	#current_tile = 0
	#money = 0.0
#
#
#func jump_animation():
	#print("Jumps")
