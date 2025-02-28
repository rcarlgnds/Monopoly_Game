extends Node

# Data-data state
var players = {}
var current_turn = 0


func update_player_position(player_id, new_position):
	if players.has(player_id):
		players[player_id]["position"] = new_position


func next_turn():
	current_turn = (current_turn + 1) % players.size()
	
func get_current_player():
	return players.keys()[current_turn]
