extends CharacterBody3D

# Animation Parameters
@export var animation_tree: AnimationTree
@export var animation_player: AnimationPlayer
var animation_state
@onready var footstep = $footstep
@onready var idle1 = $IdleVoiceLine1

# Camera Nodes
@export var camera_yaw: Node3D
@export var camera_pitch: Node3D
@export var actual_camera: Camera3D 

# Camera Follow Variables
@export var left_offset_x := 50.0
@export var lerp_speed := 1.0
var base_y = 40.0
var base_z = -200.0
var current_x_offset := 0.0

# Camera Shake Variables
@export var shake_strength := 0.25
@export var shake_speed := 30.0
var shake_timer := 0.0

# Camera Bobbing Variables
@export var bob_strength := 0.15
@export var bob_speed := 6.0
var bob_timer := 0.0

# Camera FOV Zoom
@export var normal_fov := 70.0
@export var walk_fov := 75.0
@export var sprint_fov := 85.0
@export var fov_lerp_speed := 8.0

# Idle Voice Line Timer
var idle_timer := 0.0
@export var idle_trigger_time := 15.0     # Seconds before first voice line plays
@export var idle1_interval := 10.0       # Seconds between voice lines
var last_idle1_time := 0.0

# Mouse Idle Timer
var mouse_moved_timer := 0.0
@export var mouse_idle_threshold := 0.3  # Seconds of no mouse movement before considered idle

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
@export var walk_speed := 55.0
@export var sprint_speed := 650.0
@export var jump_velocity := 200.0
@export var gravity := -500.0

func _ready():
	animation_state = animation_tree.get("parameters/playback")
	current_x_offset = left_offset_x
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	if event is InputEventMouseMotion:
		mouse_moved_timer = 0.0  # Reset mouse idle timer

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
		root_velocity = Vector3.ZERO  # Prevent movement while idle

	# FOV zoom
	var target_fov = normal_fov
	if is_sprinting:
		target_fov = sprint_fov
	elif anim_canmove:
		target_fov = walk_fov

	actual_camera.fov = lerp(actual_camera.fov, target_fov, fov_lerp_speed * delta)

func _physics_process(delta):
	var camera_yaw_angle = camera_yaw.global_transform.basis.get_euler().y
	var is_vaulting = is_sprinting and Input.is_action_pressed("vault")

	inputdir = Vector3(horizontal, 0, vertical).normalized()

	if not is_vaulting:
		if inputdir != Vector3.ZERO:
			direction = inputdir.rotated(Vector3.UP, camera_yaw_angle).normalized()
			anim_canmove = true
			var target_rotation = atan2(direction.x, direction.z)
			rotation.y = lerp_angle(rotation.y, target_rotation, turn_speed * delta)
		else:
			anim_canmove = false
	else:
		# Vaulting: move forward only, no rotation changes
		anim_canmove = true
		direction = Vector3(0, 0, 1).rotated(Vector3.UP, rotation.y)

	is_sprinting = Input.is_action_pressed("sprint") and inputdir != Vector3.ZERO

	# Jumping
	if is_on_floor():
		if Input.is_action_just_pressed("jump") and !anim_canmove:
			velocity.y = jump_velocity
			is_jumping = true
		else:
			is_jumping = false
	else:
		velocity.y += gravity * delta

	# Animation conditions
	animation_tree.set("parameters/conditions/startmove", anim_canmove)
	animation_tree.set("parameters/conditions/Idle", !anim_canmove)
	animation_tree.set("parameters/conditions/Run", is_sprinting)
	animation_tree.set("parameters/conditions/Jump", is_jumping)
	animation_tree.set("parameters/conditions/Walk", anim_canmove and !is_sprinting)
	animation_tree.set("parameters/conditions/Beam", is_sprinting and is_jumping)
	animation_tree.set("parameters/conditions/Vault", is_vaulting)

	# Movement
	var speed = sprint_speed if is_sprinting else walk_speed
	var horizontal_velocity = direction * speed
	velocity.x = horizontal_velocity.x
	velocity.z = horizontal_velocity.z

	if !anim_canmove:
		velocity.x = 0.0
		velocity.z = 0.0

	move_and_slide()

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

	camera_smooth_follow(delta)

func camera_smooth_follow(delta):
	var camera_yaw_angle = camera_yaw.global_transform.basis.get_euler().y

	# Side offset
	var target_x = left_offset_x if !anim_canmove else 0.0
	current_x_offset = lerp(current_x_offset, target_x, lerp_speed * delta)

	# Basic offset (up + back)
	var offset = Vector3(current_x_offset, base_y, base_z).rotated(Vector3.UP, camera_yaw_angle)
	var desired_pos = global_transform.origin + offset

	# Camera shake & bobbing
	var shake_offset = Vector3.ZERO
	if is_sprinting:
		shake_timer += delta * shake_speed
		shake_offset += Vector3(
			sin(shake_timer * 10.0),
			cos(shake_timer * 15.0),
			0
		) * shake_strength
	elif anim_canmove and !is_sprinting:
		bob_timer += delta * bob_speed
		shake_offset += Vector3(
			sin(bob_timer),
			abs(cos(bob_timer * 2.0)),
			0
		) * bob_strength
	else:
		bob_timer = 0.0
		shake_timer = 0.0

	desired_pos += shake_offset

	var cam_speed = 250
	var cam_timer = clamp(delta * cam_speed / 20.0, 0.0, 1.0)
	camera_pitch.global_transform.origin = camera_pitch.global_transform.origin.lerp(desired_pos, cam_timer)

func player_sound():
	footstep.playing = true
