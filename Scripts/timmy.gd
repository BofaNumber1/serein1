extends CharacterBody3D

# Animation Parameters
@export var animation_tree: AnimationTree
@export var animation_player: AnimationPlayer
@onready var animation_state = animation_tree.get("parameters/playback")

# Camera Target and Parent
@export var camera_target: Node3D
@export var camera_parent: Node3D

# Player Parameters
var inputdir = Vector3()

# Animation condition states
var anim_canmove = false
var is_sprinting = false
var is_jumping = false

# Physics values
var direction = Vector3()
var turn_speed = 10
var root_velocity = Vector3()

# Input
var horizontal = 0.0
var vertical = 0.0

# Movement speeds
@export var walk_speed := 55.0
@export var sprint_speed := 85.0
@export var jump_velocity := 200.0
@export var gravity := -500.0

func _process(delta):
	horizontal = Input.get_axis("right", "left")
	vertical = Input.get_axis("backward", "forward")

	var root_pos = animation_tree.get_root_motion_position()
	var current_rotation = (animation_tree.get_root_motion_rotation_accumulator().inverse() * get_quaternion())
	root_velocity = current_rotation * root_pos / delta
	var root_rotation = animation_tree.get_root_motion_rotation()
	set_quaternion(get_quaternion() * root_rotation)

func _physics_process(delta):
	var camera_T = camera_target.global_transform.basis.get_euler().y
	inputdir = Vector3(horizontal, 0, vertical).normalized()

	if inputdir != Vector3.ZERO:
		direction = inputdir.rotated(Vector3.UP, camera_T).normalized()
		anim_canmove = true
	else:
		anim_canmove = false

	is_sprinting = Input.is_action_pressed("sprint") and anim_canmove

	# Handle jump ONLY when idle (not moving)
	if is_on_floor():
		if Input.is_action_just_pressed("jump") and !anim_canmove:
			velocity.y = jump_velocity
			is_jumping = true
		else:
			is_jumping = false
	else:
		velocity.y += gravity * delta  # Apply gravity when in air

	# Update animation conditions
	animation_tree.set("parameters/conditions/startmove", anim_canmove)
	animation_tree.set("parameters/conditions/Idle", !anim_canmove)
	animation_tree.set("parameters/conditions/Run", is_sprinting)
	animation_tree.set("parameters/conditions/Jump", is_jumping)

	var speed = sprint_speed if is_sprinting else walk_speed
	var horizontal_velocity = direction * speed
	velocity.x = horizontal_velocity.x
	velocity.z = horizontal_velocity.z

	move_and_slide()

	if anim_canmove:
		rotation.y = lerp_angle(rotation.y, atan2(direction.x, direction.z), turn_speed * delta)

	camera_smooth_follow(delta)

func camera_smooth_follow(delta):
	var camera_T = camera_target.global_transform.basis.get_euler().y
	var cam_offset = Vector3(0, 40, -200).rotated(Vector3.UP, camera_T)
	var cam_speed = 250
	var cam_timer = clamp(delta * cam_speed / 20.0, 0.0, 1.0)

	camera_parent.global_transform.origin = camera_parent.global_transform.origin.lerp(
		global_transform.origin + cam_offset,
		cam_timer
	)
