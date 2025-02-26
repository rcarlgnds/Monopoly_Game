class_name Map
extends Node3D

var size_a : int
var size_b : int
var tile_gap : float
var tile_height : float
var tile_scale : float
var theme : String


func _init(m_size_a: int, m_size_b: int, m_tile_gap: float, m_tile_height: float, m_scale: float, m_theme: String):
	size_a = m_size_a
	size_b = m_size_b
	tile_gap = m_tile_gap
	tile_height = m_tile_height
	tile_scale = m_scale
	theme = m_theme	
