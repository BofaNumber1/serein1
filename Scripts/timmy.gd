extends CharacterBody3D

# Animation Parameters
@export var animation_tree: AnimationTree
@export var animation_player: AnimationPlayer
var animation_state
@onready var footstep = $footstep
@onready var idle1 = $IdleVoiceLine1

# Camera Nodes (Legacy - for compatibility with old system)
@export var camera_root: Node3D        # The top Node3D controlling camera rig position relative to player
@export var camera_target: Node3D      # The node that handles camera rotation (yaw/pitch)

# New Camera System
@export var third_person_camera: Node3D  # Reference to ThirdPersonCamera scene

# Camera Follow Offsets (Legacy)
@export var follow_target_height_offset := 1.5
@export var camera_back_offset := -4.0  # Distance behind player

# Movement and rotation (Tank Controls)
@export var turn_speed := 10
@export var rotation_speed := 3.0  # How fast Timmy rotates with left/right input

# Player Parameters
var inputdir = Vector3()
var direction = Vector3()
var anim_canmove = false
var is_sprinting = false
var is_jumping = false
var is_vaulting = false

# Input (Tank Style)
var move_input = 0.0  # Forward/backward movement
var turn_input = 0.0  # Left/right rotation

# Movement speeds
@export var walk_speed := 55.0
@export var sprint_speed := 650.0
@export var jump_velocity := 200.0
@export var gravity := -500.0

# Idle Voice Line Timer
var idle_timer := 0.0
@export var idle_trigger_time := 15.0
@export var idle1_interval := 10.0
var last_idle1_time := 0.0

func _ready():
	animation_state = animation_tree.get("parameters/playback")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	if event is InputEventMouseMotion:
		idle_timer = 0.0

func _process(delta):
	# Tank-style controls: 
	# - Forward/Backward for movement
	# - Left/Right for rotation
	move_input = Input.get_axis("backward", "forward")
	turn_input = Input.get_axis("right", "left")

	if anim_canmove:
		var root_pos = animation_tree.get_root_motion_position()
		var current_rotation = animation_tree.get_root_motion_rotation_accumulator().inverse() * get_quaternion()
		var root_velocity = current_rotation * root_pos / delta
		var root_rotation = animation_tree.get_root_motion_rotation()
		set_quaternion(get_quaternion() * root_rotation)
	else:
		var root_velocity = Vector3.ZERO

func _physics_process(delta):
	# Determine if we're moving or sprinting
	var is_moving = abs(move_input) > 0.0
	is_sprinting = Input.is_action_pressed("sprint") and is_moving
	is_vaulting = is_sprinting and Input.is_action_pressed("vault")

	# Update camera state if using new camera system
	if third_person_camera and third_person_camera.has_method("set_movement_state"):
		third_person_camera.set_movement_state(is_moving, is_sprinting)

	# Tank-style rotation: Left/Right input rotates the player directly
	if abs(turn_input) > 0.0:
		rotation.y += turn_input * rotation_speed * delta

	# Tank-style movement: Forward/Backward moves in the direction Timmy is facing
	if is_vaulting:
		anim_canmove = true
		direction = Vector3(0, 0, 1).rotated(Vector3.UP, rotation.y)
	else:
		if is_moving:
			# Move forward/backward relative to Timmy's current rotation
			direction = Vector3(0, 0, move_input).rotated(Vector3.UP, rotation.y).normalized()
			anim_canmove = true
		else:
			anim_canmove = false
			direction = Vector3.ZERO

	if is_on_floor():
		if Input.is_action_just_pressed("jump") and !anim_canmove:
			velocity.y = jump_velocity
			is_jumping = true
		else:
			is_jumping = false
	else:
		velocity.y += gravity * delta

	animation_tree.set("parameters/conditions/startmove", anim_canmove)
	animation_tree.set("parameters/conditions/Idle", !anim_canmove)
	animation_tree.set("parameters/conditions/Run", is_sprinting)
	animation_tree.set("parameters/conditions/Jump", is_jumping)
	animation_tree.set("parameters/conditions/Walk", anim_canmove and !is_sprinting)
	animation_tree.set("parameters/conditions/Beam", is_sprinting and is_jumping)
	animation_tree.set("parameters/conditions/Vault", is_vaulting)

	var speed = sprint_speed if is_sprinting else walk_speed
	var horizontal_velocity = direction * speed
	velocity.x = horizontal_velocity.x
	velocity.z = horizontal_velocity.z

	if !anim_canmove:
		velocity.x = 0.0
		velocity.z = 0.0

	move_and_slide()

	if move_input == 0 and turn_input == 0 and is_on_floor():
		idle_timer += delta
		if idle_timer >= idle_trigger_time:
			var now = Time.get_ticks_msec()
			if (now - last_idle1_time > idle1_interval * 1000) and idle1 and !idle1.playing:
				idle1.play()
				last_idle1_time = now
	else:
		idle_timer = 0.0

	# CAMERA POSITIONING: Handle both new and legacy camera systems
	if third_person_camera:
		# New camera system handles positioning automatically via follow_target
		pass
	elif camera_root and camera_target:
		# Legacy camera system
		var local_offset = Vector3(0, follow_target_height_offset, camera_back_offset)
		local_offset = local_offset.rotated(Vector3.UP, rotation.y)
		camera_root.position = local_offset

func player_sound():
	footstep.playing = true

# Camera control functions for the new system
func set_camera_over_right_shoulder():
	if third_person_camera and third_person_camera.has_method("set_over_shoulder_right"):
		third_person_camera.set_over_shoulder_right()

func set_camera_over_left_shoulder():
	if third_person_camera and third_person_camera.has_method("set_over_shoulder_left"):
		third_person_camera.set_over_shoulder_left()

func set_camera_center():
	if third_person_camera and third_person_camera.has_method("set_center"):
		third_person_camera.set_center()

func set_camera_aiming(is_aiming: bool):
	if third_person_camera and third_person_camera.has_method("set_aiming"):
		third_person_camera.set_aiming(is_aiming)
