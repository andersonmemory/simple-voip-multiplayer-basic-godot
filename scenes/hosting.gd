extends Node3D
 
var peer = ENetMultiplayerPeer.new()
@export var player_scene: PackedScene

func _on_host_pressed():
	peer.create_server(9999, 4)
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_add_player)
	_add_player(multiplayer.get_unique_id())
	
func _add_player(id):
	print("peer connected")
	var player = player_scene.instantiate()
	player.name = str(id)
	$Players.call_deferred("add_child", player)
	
	pass
	
func _on_join_pressed():
	
	var address = $"Join/ip-address".text
	
	if address == "":
		address = "127.0.0.1"
	
	peer.create_client(address, 9999)
	multiplayer.multiplayer_peer = peer
