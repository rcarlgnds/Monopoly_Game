extends Node
class_name SocketClient

# Signal to socket
signal player_joined(player_id: String, pos: Vector3, skin: String)
signal player_left(player_id: String)
signal dice_rolled(dice_positions: Array, rotations: Array, throw_vector: Vector3)
signal player_jumped(player_id, steps)
signal turn_synced(player_id)


var websocket = WebSocketPeer.new()
var server_url = "ws://localhost:5049/ws"

var ping_interval := 5.0
var reconnect_interval := 3.0

var last_ping_time := 0 
var last_reconnect_time := 0
var players = {}
var player_id: String = "" 
var current_turn_player_id = ""

func _ready():
	print("Connect to Web Socket!")
	
	set_process(true)
	connect_to_server()
	
	last_ping_time = Time.get_ticks_msec()
	last_reconnect_time = Time.get_ticks_msec()
	
func connect_to_server():
	print("Try to connect", server_url)
	var err = websocket.connect_to_url(server_url)
	if err != OK:
		print("WebSocket failed:", err)

func _process(delta):
	websocket.poll()
	
	var current_time = Time.get_ticks_msec()
	
	# Send Ping to server each 5 seconds
	if websocket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		if current_time - last_ping_time >= int(ping_interval * 1000):
			_send_ping()
			last_ping_time = current_time
	else:
		if current_time - last_reconnect_time >= int(reconnect_interval * 1000):
			print("⚠️ WebSocket not open, attempting to reconnect...")
			connect_to_server()
			last_reconnect_time = current_time
			
	while websocket.get_available_packet_count() > 0:
		var message = websocket.get_packet().get_string_from_utf8()
		_on_message_received(message)
	
func _send_ping():
	if websocket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		var ping_message = JSON.stringify({"eventType": "ping"})
		print("Send Ping: ", ping_message)
		var result = websocket.send_text(ping_message)
		
		if result != OK:
			print("Send ping failed: ", result)	
			
func send_to_server(event: String, data: Dictionary):
	if websocket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		var message = {"eventType": event}
		message.merge(data)
		var json_message = JSON.stringify(message)
		
		var result = websocket.send_text(json_message)
		if result != OK:
			print("Failed to send message to server: ", result)
		else:
			print("✅ Message sent to server:", json_message)
	else:
		print("⚠️ Connection not open!")

		
		
func _on_message_received(message: String):
	print("📩 Received Message: ", message)

	var data = JSON.parse_string(message)
	if data == null:
		print("❌ Invalid JSON")
		return

	if "eventType" in data:
		match data["eventType"]:
			"sync_players":
				if "players" in data:
					players.clear()
					for player_id in data["players"].keys():
						var player_info = data["players"][player_id]

						var pos
						if "position" in player_info:
							pos = Vector3(
								player_info["position"].get("x", 0),
								player_info["position"].get("y", 0),
								player_info["position"].get("z", 0)
							)
						else:
							pos = Vector3(
								player_info.get("x", 0),
								player_info.get("y", 0),
								player_info.get("z", 0)
							)

						var skin = player_info.get("player_skin", "Knight")

						players[player_id] = {"pos": pos, "skin": skin}
						emit_signal("player_joined", player_id, pos, skin)


			"player_joined":
				print("player Joined: ", data)

				if "playerId" in data:  
					if player_id == "":
						player_id = data["playerId"]
						print("✅ Player ID set to:", player_id)

				var position = data.get("position", {}) 
				var x = position.get("x", 0)
				var y = position.get("y", 0)
				var z = position.get("z", 0)
				var pos = Vector3(x, y, z)

				var skin = data.get("player_skin", "Knight")

				print("🎨 Skin received from server:", skin) 

				players[data["playerId"]] = {"pos": pos, "skin": skin}
				
				emit_signal("player_joined", data["playerId"], pos, skin)

					
			"player_left":
				if "playerId" in data:
					var player_id = data["playerId"]
					if player_id in players:
						players.erase(player_id)
						emit_signal("player_left", player_id)
					else:
						print("⚠️ Player not found when leaving:", player_id)
						
			"roll_dice":
				if "playerId" in data and "dicePositions" in data and "rotations" in data and "throwVector" in data:
					print("🎲 Player", data["playerId"], "rolled dice!")

					var dice_positions = data["dicePositions"]
					var rotations = data["rotations"]
					var throw_vector = Vector3(data["throwVector"]["x"], 0, data["throwVector"]["z"])

					emit_signal("dice_rolled", dice_positions, rotations, throw_vector)
					
					if player_id != data["playerId"]:
						print("Another player rolled dice! Processing event...")
						
			"player_jump":
				if "playerId" in data and "steps" in data:
					print("🦘 Player", data["playerId"], "jumped!")

					var player_id = data["playerId"]
					var steps = data["steps"]

					# Emit sinyal agar sistem lain bisa menangani lompatan pemain
					emit_signal("player_jumped", player_id, steps)
			"sync_turn":
				current_turn_player_id = data["currentTurnPlayerId"]
				print("current turn",data["currentTurnPlayerId"])
				emit_signal("turn_synced", current_turn_player_id)
