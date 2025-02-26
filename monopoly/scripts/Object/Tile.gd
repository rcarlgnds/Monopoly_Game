class_name Tile
extends Node3D

var tile_id: int
var tile_name: String
var tile_content: String = "Empty"  
var tile_status: String = "Active" 
var tile_coordinate: Vector3
var tile_owner_id: String = ""  
var tile_stage: int = 1  

func _init(id: int, t_name: String, position: Vector3):
	tile_id = id
	tile_name = t_name
	tile_coordinate = position
