extends Node3D

var peer = ENetMultiplayerPeer.new()
@export var player_scene: PackedScene
var players = {}  # Store players by their unique ID

# Add player to the game
func _add_player(id):
	print("peer connected")
	var player = player_scene.instantiate()
	player.name = str(id)
	
	add_child(player)
	player.get_node("AudioManager").setupAudio(multiplayer.get_unique_id())
	players[id] = player

@rpc("any_peer")
func spawn_player(id):
	var player = player_scene.instantiate()
	player.name = str(id)
	add_child(player)
	player.get_node("AudioManager").setupAudio(id)

	players[id] = player

# Join or host buttons
func _on_join_pressed():
	var address = $"Join/ip-address".text
	if address == "":
		address = "127.0.0.1"
	
	peer.create_client(address, 9999)
	multiplayer.multiplayer_peer = peer  # Ensure the multiplayer peer is set to the correct peer
	_add_player(multiplayer.get_unique_id())

func _on_host_pressed():
	peer.create_server(9999, 4)
	multiplayer.multiplayer_peer = peer  # Set multiplayer peer to host server
	multiplayer.peer_connected.connect(_add_player)
	_add_player(multiplayer.get_unique_id())
