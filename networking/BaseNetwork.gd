extends Node

signal remove_player
signal all_disconnected

func _ready():
	reset_network()
	
	get_tree().connect("network_peer_disconnected", self, "_player_disconnected")

# Every network peer needs to clean up the disconnected client
func _player_disconnected(id : int):
	print("Player disconnected: " + str(id))
	GameData.players.erase(id)

	if GameData.players.size() == 0:
		emit_signal("all_disconnected")

	emit_signal("remove_player", id)
	print("Total players: %d" % GameData.players.size())

# Completely reset the game state and clear the network
func reset_network():
	var peer = get_tree().network_peer
	if peer != null:
		peer.close_connection()
	
	# Cleanup all state related to the game session
	GameData.reset()
