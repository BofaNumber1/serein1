extends CharacterBody3D

#character speeds
var speed = 10.0
var turn_speed = 30

#get gravity from project settings
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

#player parent node
var parent

#amount to jump
@export var jump_impulse = 10

# h and v from camera rig
@onready var cam_h = $CamRoot/h
@onready var cam_v = $CamRoot/h/v

# running / jumping states
var running := true
var jumping := true

func _ready():
	# set mouse mode captured so it locks in middle of screen
	capture_mouse()
	
	# set parent
	parent = get_parent()

func _unhandled_input(event):
	# if "exit" (esc) is pressed, close game
	if Input.is_action_just_pressed("exit"):
		get_tree().quit()
		
func _process(delta):
	# set parent position to equal CharacterBody position for every frame
	parent.position = position

func _physics_process(delta):
	# turn player inputs into a vector
	var input_dir = Input.get_vector("left", "right", "foward", "backward")
	
	# get direction from camera
	var direction = (cam_h.transform.basis * Vector3(input_dir.x, 0, input_dir.y))
	
	# if playerBody isn't on the floor, activate gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
		# play falling animation when player is in the air  
		$AnimationPlayer.play("falling", 0.6,0.6)
	else:
		if (direction and !running) or (direction and running):
			# player is running
			$AnimationPlayer.play("running", 0.1, 1)
			running = false
		if jumping:
			# player is idle after jumping and hitting the ground
			$AnimationPlayer.play("offensive_idle", 0.1, 1)
			jumping = false
	
	if direction:
		# player movement
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		
		# change player model rotation relative to the camera
		rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), turn_speed * delta)

	else:
		# player should stop moving with no input
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)
		
	# make player jump
	if is_on_floor() and Input.is_action_just_pressed("jump"):
		$AnimationPlayer.play("jump", 0.2, 0.2)
		velocity.y = jump_impulse
		jumping = true
	
	# apply movement to player
	move_and_slide()

func capture_mouse():
	# capture the mouse pointer so we can use it to control the camera
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func release_mouse():
	# allow player to use mouse
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
