extends CharacterBody3D

# Animation Parameters
@export var animation_tree: AnimationTree
@export var animation_player: AnimationPlayer
@onready var animation_state = animation_tree.get("parameters/playback")
@onready var footstep = $footstep
@onready var idle1 = $IdleVoiceLine1

# Camera Target and Parent
@export var camera_target: Node3D
@export var camera_parent: Node3D
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

# Mouse sensitivity (assuming you have this)
var mouse_sensitivity := 0.002
var camera_pitch := 0.0
var max_pitch := deg_to_rad(80)
var min_pitch := deg_to_rad(-80)

func _ready():
	current_x_offset = left_offset_x
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	if event is InputEventMouseMotion:
		mouse_moved_timer = 0.0  # Reset mouse idle timer
		camera_target.rotate_y(-event.relative.x * mouse_sensitivity)
		camera_pitch = clamp(camera_pitch + event.relative.y * mouse_sensitivity, min_pitch, max_pitch)
		camera_parent.rotation.x = camera_pitch


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
	var camera_T = camera_target.global_transform.basis.get_euler().y

	# Get input direction
	inputdir = Vector3(horizontal, 0, vertical).normalized()

	if inputdir != Vector3.ZERO:
		direction = inputdir.rotated(Vector3.UP, camera_T).normalized()
		anim_canmove = true
	else:
		anim_canmove = false

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

	# Vault condition — sprinting and holding E ("vault" input action)
	var is_vaulting = is_sprinting and Input.is_action_pressed("vault") 

	# Animation conditions (including vault)
	animation_tree.set("parameters/conditions/startmove", anim_canmove)
	animation_tree.set("parameters/conditions/Idle", !anim_canmove)
	animation_tree.set("parameters/conditions/Run", is_sprinting)
	animation_tree.set("parameters/conditions/Jump", is_jumping)
	animation_tree.set("parameters/conditions/Walk", anim_canmove and !is_sprinting)
	animation_tree.set("parameters/conditions/Beam", anim_canmove and is_sprinting and is_jumping)
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

	# Smooth rotation
	if anim_canmove:
		rotation.y = lerp_angle(rotation.y, atan2(direction.x, direction.z), turn_speed * delta)

	# Idle voice line logic — only plays when not moving (ignores mouse movement)
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

# === ORIGINAL CAMERA FUNCTION from your very first script ===
func camera_smooth_follow(delta):
	var camera_T = camera_target.global_transform.basis.get_euler().y

	# Side offset
	var target_x = left_offset_x if !anim_canmove else 0.0
	current_x_offset = lerp(current_x_offset, target_x, lerp_speed * delta)

	# Basic offset (up + back)
	var offset = Vector3(current_x_offset, base_y, base_z).rotated(Vector3.UP, camera_T)
	var desired_pos = global_transform.origin + offset

	# Start with no offset
	var shake_offset = Vector3.ZERO

	# Sprint camera shake
	if is_sprinting:
		shake_timer += delta * shake_speed
		shake_offset += Vector3(
			sin(shake_timer * 10.0),
			cos(shake_timer * 15.0),
			0
		) * shake_strength

	# Walk bobbing (only when walking, not sprinting)
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
	camera_parent.global_transform.origin = camera_parent.global_transform.origin.lerp(desired_pos, cam_timer)

func player_sound():
	footstep.playing = true
