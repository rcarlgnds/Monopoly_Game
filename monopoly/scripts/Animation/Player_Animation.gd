extends Node3D

func idle():
	state_machine.travel("Idle")
