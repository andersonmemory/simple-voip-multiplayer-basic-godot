extends CharacterBody3D

var mouse_sensivity := 0.5
var screen_paused = false

# Player attributes
var speed := 5
var inventory = []

# Radio 1 and radio 2 locationn
@onready var radio1 = get_node("../Radio1")
@onready var radio2 = get_node("../Radio2") 
@export var radioPath : NodePath

func _enter_tree() -> void:
	set_multiplayer_authority(str(name).to_int())

func _ready():
	# Avoid player from colliding with itself when joining - teleporting randomly
	collision_mask = 1  # Enable only environment at first
	await get_tree().create_timer(0.1).timeout
	collision_mask = 3  # Enable both layers after a delay
	
	if not is_multiplayer_authority(): return
	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	$Head/Camera3D.current = true

func _physics_process(_delta):
	
	if not is_multiplayer_authority(): return
	
	# Make the audio follow the player
	$AudioManager.global_position = global_position
	
	var direction := Vector3.ZERO
	direction = direction_handler(direction)
	
	var movement = (transform.basis * direction)
	
	velocity.x = movement.x * speed
	velocity.z = movement.z * speed

	move_and_slide()
	
	# If player is grabbing radio, then, update radio's position
	if inventory:
		if Input.is_action_pressed("grab_radio"):
			inventory[0].global_position.z = $Head/ItemPos.global_position.z
			inventory[0].global_position.x = $Head/ItemPos.global_position.x
			
			if inventory[0].name == "Radio1":
				get_node(radioPath).global_position = get_node("../Radio2").global_position
				get_node(radioPath).visible = true
				update_radio_pos.rpc("1")
			elif inventory[0].name == "Radio2":
				get_node(radioPath).global_position = get_node("../Radio1").global_position
				get_node(radioPath).visible = true
				update_radio_pos.rpc("2")
		else:
			update_radio_pos.rpc("remove")
			get_node(radioPath).global_position = Vector3(0, 0, 0)
			get_node(radioPath).visible = false
	else:
			update_radio_pos.rpc("remove")
			get_node(radioPath).global_position = Vector3(0, 0, 0)
			get_node(radioPath).visible = false

		
@rpc("any_peer")
func update_radio_pos(radio_number):
	match radio_number:
		"1":
			get_node(radioPath).global_position = get_node("../Radio2").global_position
			get_node(radioPath).visible = true
			
			inventory[0].global_position.z = $Head/ItemPos.global_position.z
			inventory[0].global_position.x = $Head/ItemPos.global_position.x
		"2":
			get_node(radioPath).global_position = get_node("../Radio1").global_position
			get_node(radioPath).visible = true
			
			inventory[0].global_position.z = $Head/ItemPos.global_position.z
			inventory[0].global_position.x = $Head/ItemPos.global_position.x
		"remove":
			get_node(radioPath).global_position = Vector3(0, 0, 0)
			get_node(radioPath).visible = false
			
			

#region Mouse movement and esc key
func _unhandled_input(event):
	if not is_multiplayer_authority(): return
	
	if Input.is_action_just_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		screen_paused = true
	
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		screen_paused = false
	
	if not screen_paused:
		if event is InputEventMouseMotion:
			self.rotation_degrees.y -= event.relative.x * mouse_sensivity
			$Head.rotation_degrees.x -= event.relative.y * mouse_sensivity
		
#endregion
#region Direction handling
func direction_handler(direction):
	if not is_multiplayer_authority(): return
	
	if Input.is_action_pressed("move_forward"):
		direction.z = -1
		
	if Input.is_action_pressed("move_back"):
		direction.z = 1
		
	if Input.is_action_pressed("move_right"):
		direction.x = 1
		
	if Input.is_action_pressed("move_left"):
		direction.x = -1
	
	return direction
#endregion

func _on_radio_detector_area_entered(area: Area3D) -> void:
	if area.is_in_group("radio"):
		print("radio found! (%s) " % area.name)
		inventory.append(area)
		print(inventory)
		
func _on_radio_detector_area_exited(area: Area3D) -> void:
	if area in inventory:
		print("removed %s " % area.name)
		inventory = []
		print(inventory)
