extends CharacterBody3D

# Animation Parameters
@export var animation_tree: AnimationTree
@export var animation_player: AnimationPlayer
@onready var animation_state = animation_tree.get("parameters/playback")

# Camera Target
@export var camera_target: Node3D
@export var camera_parent: Node3D

# Player Parameters
var inputdir = Vector3()

# Animation condition states
var anim_canmove = false
var is_sprinting = false

# Physics values
var direction = Vector3()
var vertical_velocity = Vector3()
var turn_speed = 10
var root_velocity = Vector3()

# Input
var horizontal = 0.0
var vertical = 0.0

# Movement speeds
@export var walk_speed := 55.0
@export var sprint_speed := 85.0

func _process(delta):
	# FIXED INPUT AXES ORDER HERE:
	horizontal = Input.get_axis("left", "right")
	vertical = Input.get_axis("forward", "backward")

	var root_pos = animation_tree.get_root_motion_position()
	var current_rotation = (animation_tree.get_root_motion_rotation_accumulator().inverse() * get_quaternion())
	root_velocity = current_rotation * root_pos / delta
	var root_rotation = animation_tree.get_root_motion_rotation()
	set_quaternion(get_quaternion() * root_rotation)

func _physics_process(delta):
	# Get camera's Y rotation
	var camera_T = camera_target.global_transform.basis.get_euler().y

	# Input direction, before rotation
	inputdir = Vector3(horizontal, 0, vertical).normalized()

	if inputdir != Vector3.ZERO:
		# Rotate input direction based on camera angle
		direction = Vector3(horizontal, 0, vertical).rotated(Vector3.UP, camera_T).normalized()
		anim_canmove = true
	else:
		anim_canmove = false

	# Sprint detection
	is_sprinting = Input.is_action_pressed("sprint") and anim_canmove

	# Animation Tree conditions
	animation_tree.set("parameters/conditions/startmove", anim_canmove)
	animation_tree.set("parameters/conditions/Idle", !anim_canmove)
	animation_tree.set("parameters/conditions/Run", is_sprinting)

	# Movement and rotation
	var speed = sprint_speed if is_sprinting else walk_speed
	velocity = direction * speed
	move_and_slide()

	if anim_canmove:
		rotation.y = lerp_angle(rotation.y, atan2(direction.x, direction.z), turn_speed * delta)

	# Smooth camera follow
	camera_smooth_follow(delta)

func camera_smooth_follow(delta):
	var camera_T = camera_target.global_transform.basis.get_euler().y
	
	# Offset: Backward and slightly up
	var cam_offset = Vector3(0, 1.5, -6).rotated(Vector3.UP, camera_T)
	
	var cam_speed = 250
	var cam_timer = clamp(delta * cam_speed / 20.0, 0.0, 1.0)

	camera_parent.global_transform.origin = camera_parent.global_transform.origin.lerp(
		self.global_transform.origin + cam_offset,
		cam_timer
	)
