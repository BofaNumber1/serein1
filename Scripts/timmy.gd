extends CharacterBody3D

# Animation Parameters
@export var animation_tree: AnimationTree
@export var animation_player: AnimationPlayer
var animation_state
@onready var footstep = $footstep
@onready var idle1 = $IdleVoiceLine1

# Camera Nodes
@export var camera_root: Node3D        # The top Node3D controlling camera rig position relative to player
@export var camera_target: Node3D      # The node that handles camera rotation (yaw/pitch)

# Camera Follow Offsets
@export var follow_target_height_offset := 1.5
@export var camera_back_offset := -4.0  # Distance behind player

# Movement and rotation
@export var turn_speed := 10

# Player Parameters
var inputdir = Vector3()
var direction = Vector3()
var anim_canmove = false
var is_sprinting = false
var is_jumping = false
var is_vaulting = false

# Input
var horizontal = 0.0
var vertical = 0.0

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
	horizontal = -Input.get_axis("left", "right")
	vertical = Input.get_axis("backward", "forward")

	if anim_canmove:
		var root_pos = animation_tree.get_root_motion_position()
		var current_rotation = animation_tree.get_root_motion_rotation_accumulator().inverse() * get_quaternion()
		var root_velocity = current_rotation * root_pos / delta
		var root_rotation = animation_tree.get_root_motion_rotation()
		set_quaternion(get_quaternion() * root_rotation)
	else:
		var root_velocity = Vector3.ZERO

func _physics_process(delta):
	is_sprinting = Input.is_action_pressed("sprint") and inputdir != Vector3.ZERO
	is_vaulting = is_sprinting and Input.is_action_pressed("vault")

	var camera_yaw_angle = 0.0
	if camera_target:
		camera_yaw_angle = camera_target.global_transform.basis.get_euler().y

	inputdir = Vector3(horizontal, 0, vertical)
	if inputdir != Vector3.ZERO:
		inputdir = inputdir.normalized()

	if is_vaulting:
		anim_canmove = true
		direction = Vector3(0, 0, 1).rotated(Vector3.UP, rotation.y)
	else:
		if inputdir != Vector3.ZERO:
			direction = inputdir.rotated(Vector3.UP, camera_yaw_angle).normalized()
			anim_canmove = true
			var target_rotation = atan2(direction.x, direction.z)
			rotation.y = lerp_angle(rotation.y, target_rotation, turn_speed * delta)
		else:
			anim_canmove = false

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

	if horizontal == 0 and vertical == 0 and is_on_floor():
		idle_timer += delta
		if idle_timer >= idle_trigger_time:
			var now = Time.get_ticks_msec()
			if (now - last_idle1_time > idle1_interval * 1000) and idle1 and !idle1.playing:
				idle1.play()
				last_idle1_time = now
	else:
		idle_timer = 0.0

	# CAMERA POSITIONING: set camera_root local position relative to player
	if camera_root and camera_target:
		var local_offset = Vector3(0, follow_target_height_offset, camera_back_offset)
		local_offset = local_offset.rotated(Vector3.UP, rotation.y)
		camera_root.position = local_offset

func player_sound():
	footstep.playing = true
