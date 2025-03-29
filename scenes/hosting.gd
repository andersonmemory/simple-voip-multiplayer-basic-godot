extends Node3D

var serverIsReady : bool
var peer = ENetMultiplayerPeer.new()
@export var player_scene: PackedScene
var players = {}  # Store players by their unique ID

@export var max_voice_distance : float = 10.0
@export var position_update_interval : float = 0.1
var last_position_update_time : float = 0.0

var position_smooth_time : float = 0.2
var last_known_positions : Dictionary = {}
var current_smooth_positions : Dictionary = {}

func _ready():
	pass

func _process(delta):
	if serverIsReady:
		peer.poll()

		# Update audio position for each player
		for id in players.keys():
			var player = players[id]
			if player:
				var audio_manager = player.get_node("AudioManager")
				if audio_manager:
					audio_manager.set_position(player.global_position)

	# Periodically update the host's position to other peers
	last_position_update_time += delta
	if last_position_update_time >= position_update_interval:
		last_position_update_time = 0.0
		if is_multiplayer_authority():
			var host_position = global_position
			send_position_update(multiplayer.get_unique_id(), host_position)

@rpc("any_peer", "call_remote", "unreliable_ordered")
func send_position_update(id: int, position: Vector3):
	print("Sending position update for id:", id, "Position:", position)  # Debugging line
	var player = players.get(id, null)
	if player:
		last_known_positions[id] = position
		var audio_manager = player.get_node("AudioManager")
		if audio_manager:
			audio_manager.set_position(position)

# Add player to the game
func _add_player(id):
	print("peer connected")
	var player = player_scene.instantiate()
	player.name = str(id)
	add_child(player)

	player.get_node("AudioManager").setupAudio(multiplayer.get_unique_id())
	players[id] = player
	rpc("spawn_player", id)

@rpc("any_peer")
func spawn_player(id):
	var player = player_scene.instantiate()
	player.name = str(id)
	add_child(player)
	player.get_node("AudioManager").setupAudio(id)

	players[id] = player

# Interpolating player positions smoothly
func interpolate_position(id: int, target_position: Vector3, delta: float):
	if not current_smooth_positions.has(id):
		current_smooth_positions[id] = target_position
	
	var current_position = current_smooth_positions[id]
	var new_position = current_position.linear_interpolate(target_position, position_smooth_time * delta)
	
	var player = players.get(id, null)
	if player:
		player.global_position = new_position
		var audio_manager = player.get_node("AudioManager")
		if audio_manager:
			audio_manager.set_position(new_position)

@rpc("any_peer")
func update_position(id: int, target_position: Vector3):
	print("Updating position for", id, "to", target_position)  # Debugging line
	var player = players.get(id, null)
	if player:
		interpolate_position(id, target_position, get_process_delta_time())  

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
	serverIsReady = true
