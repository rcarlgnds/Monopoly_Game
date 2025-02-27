extends Node3D

@onready var anim_player = $AnimationPlayer

func jump_animation():
	anim_player.play("Jump_Full_Short")
