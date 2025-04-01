extends Node3D

@onready var input : AudioStreamPlayer3D = $Input
var index : int 
var effect : AudioEffectCapture 
var playback : AudioStreamGeneratorPlayback
@export var outputPath : NodePath
var inputThreshold = 0.006
var receivedBuffer : PackedFloat32Array = PackedFloat32Array()
@export var max_voice_distance : float = 10.0
var can_talk : bool = false

func _ready():
	pass

func setupAudio(id):
	set_multiplayer_authority(id)
	input = $Input
	if is_multiplayer_authority():
		input.stream = AudioStreamMicrophone.new()
		input.play()
		index = AudioServer.get_bus_index("Record")
		effect = AudioServer.get_bus_effect(index, 0)
	
	
	playback = get_node(outputPath).get_stream_playback()
	
	print(playback)

func _process(_delta):
	
	if playback == null:
		playback = get_node(outputPath).get_stream_playback()
		
	if is_multiplayer_authority():
		processMic()
	processVoice()

func processMic():
	if effect == null: return
	var stereoData : PackedVector2Array = effect.get_buffer(effect.get_frames_available())
	if stereoData.size() > 0:
		var data = PackedFloat32Array()
		data.resize(stereoData.size())
		var maxAmplitude := 0.0
		for i in range(stereoData.size()):
			var value = (stereoData[i].x + stereoData[i].y) / 2
			maxAmplitude = max(value, maxAmplitude)
			data[i] = value
		if maxAmplitude < inputThreshold:
			return
			
		sendData.rpc(data)

func processVoice():

	if receivedBuffer.size() <= 0:
		return
		
	if playback == null:
		print("null")
		return
	
	for i in range(min(playback.get_frames_available(), receivedBuffer.size())):
		playback.push_frame(Vector2(receivedBuffer[0], receivedBuffer[0]))
		receivedBuffer.remove_at(0)

@rpc("any_peer", "call_remote", "unreliable_ordered")
func sendData(data : PackedFloat32Array):
	receivedBuffer.append_array(data)
