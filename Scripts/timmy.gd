extends CharacterBody3D

# Animation Parameters
@export var animation_tree: AnimationTree
@export var animation_player: AnimationPlayer
var animation_state
@onready var footstep = $footstep
@onready var idle1 = $IdleVoiceLine1

# Camera Controller Reference
@onready var camera_controller: CameraController = $CameraController

# Camera rotation (legacy fallback)
@export var camera_yaw: Node3D
@export var mouse_sensitivity: float = 0.002 

# Idle Voice Line Timer
var idle_timer := 0.0
@export var idle_trigger_time := 15.0
@export var idle1_interval := 10.0
var last_idle1_time := 0.0

# Mouse Idle Timer
var mouse_moved_timer := 0.0
@export var mouse_idle_threshold := 0.3

# Player Parameters
var inputdir = Vector3()
var direction = Vector3()
var turn_speed = 10
var root_velocity = Vector3()
var anim_canmove = false
var is_sprinting = false
var is_jumping = false

# Input
var horizontal = 0.0
var vertical = 0.0

# Movement speeds
@export var walk_speed := 5.5
@export var sprint_speed := 10.0
@export var jump_velocity := 8.0
@export var gravity := 15.0

func _ready():
	animation_state = animation_tree.get("parameters/playback")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	if event is InputEventMouseMotion:
		mouse_moved_timer = 0.0

func _process(delta):
	mouse_moved_timer += delta

	horizontal = Input.get_axis("right", "left")
	vertical = Input.get_axis("backward", "forward")

	if anim_canmove:
		var root_pos = animation_tree.get_root_motion_position()
		var current_rotation = animation_tree.get_root_motion_rotation_accumulator().inverse() * get_quaternion()
		root_velocity = current_rotation * root_pos / delta
		var root_rotation = animation_tree.get_root_motion_rotation()
		set_quaternion(get_quaternion() * root_rotation)
	else:
		root_velocity = Vector3.ZERO

func _physics_process(delta):
	var camera_yaw_angle = 0.0
	if camera_controller:
		camera_yaw_angle = camera_controller.rotation_y
	elif camera_yaw:
		camera_yaw_angle = camera_yaw.global_transform.basis.get_euler().y
	
	var is_vaulting = is_sprinting and Input.is_action_pressed("vault")

	# Correct input axis order for consistent controls
	horizontal = Input.get_axis("right", "left")
	vertical = Input.get_axis("forward", "backward")

	# Calculate camera-relative movement direction
	var camera_forward = Vector3.FORWARD.rotated(Vector3.UP, camera_yaw_angle)
	var camera_right = Vector3.RIGHT.rotated(Vector3.UP, camera_yaw_angle)

	var input_vector = (camera_forward * vertical) + (camera_right * horizontal)

	if input_vector.length() > 1:
		input_vector = input_vector.normalized()

	direction = input_vector.normalized() if input_vector.length() > 0 else Vector3.ZERO
	inputdir = direction

	if not is_vaulting:
		if inputdir != Vector3.ZERO:
			anim_canmove = true

			# Rotate player toward movement direction smoothly
			var target_rotation = atan2(direction.x, direction.z)
			rotation.y = lerp_angle(rotation.y, target_rotation, turn_speed * delta)
		else:
			anim_canmove = false
			direction = Vector3.ZERO
	else:
		anim_canmove = true
		direction = Vector3(0, 0, 1).rotated(Vector3.UP, rotation.y)

	is_sprinting = Input.is_action_pressed("sprint") and inputdir != Vector3.ZERO

	if is_on_floor():
		if Input.is_action_just_pressed("jump") and !anim_canmove:
			velocity.y = jump_velocity
			is_jumping = true
		else:
			is_jumping = false
	else:
		velocity.y -= gravity * delta

	# Animation state updates
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

	# Camera shake for sprinting
	if camera_controller:
		var horizontal_speed = Vector2(velocity.x, velocity.z).length()
		if is_sprinting and horizontal_speed > 8.0:
			camera_controller.add_camera_shake(0.05)

	# Idle voice line logic
	if horizontal == 0 and vertical == 0 and is_on_floor():
		idle_timer += delta
		if idle_timer >= idle_trigger_time:
			var now = Time.get_ticks_msec()
			if (now - last_idle1_time > idle1_interval * 1000) and idle1 and !idle1.playing:
				print("Idle voice line played")
				idle1.play()
				last_idle1_time = now
	else:
		idle_timer = 0.0


func player_sound():
	footstep.playing = true
