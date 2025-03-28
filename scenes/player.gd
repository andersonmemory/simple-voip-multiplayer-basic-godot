extends CharacterBody3D

var mouse_sensivity := 0.5
var screen_paused = false

# Player attributes
var speed := 5

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
	
	var direction := Vector3.ZERO
	direction = direction_handler(direction)
	
	var movement = (transform.basis * direction)
	
	velocity.x = movement.x * speed
	velocity.z = movement.z * speed

	move_and_slide()

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
