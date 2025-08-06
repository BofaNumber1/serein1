extends CharacterBody3D

# Animation Parameters
@export var animation_tree: AnimationTree
@export var animation_player: AnimationPlayer
var animation_state
@onready var footstep = $footstep
@onready var idle1 = $IdleVoiceLine1
var current_vault_animation = 0
# Camera Nodes (Legacy - for compatibility with old system)
@export var camera_root: Node3D
@export var camera_target: Node3D

# New Camera System
@export var third_person_camera: Node3D

# Camera Follow Offsets (Legacy)
@export var follow_target_height_offset := 1.5
@export var camera_back_offset := -4.0

# Movement and rotation
@export var turn_speed := 10
@export var rotation_speed := 6.0

# Player Parameters
var direction = Vector3()
var anim_canmove = false
var is_sprinting = false
var is_jumping = false
var is_vaulting = false

# Movement speeds
@export var walk_speed := 55.0
@export var sprint_speed := 650.0
@export var jump_velocity := 200.0
@export var gravity := -500.0

# Jump Timing System
@export var jump_velocity_delay := 1.2  # Delay in seconds before applying upward velocity
var jump_timer := 0.0
var jump_velocity_pending := false

# Idle Voice Line Timer
var idle_timer := 0.0
@export var idle_trigger_time := 15.0
@export var idle1_interval := 10.0
var last_idle1_time := 0.0

func _can_vault() -> bool:
	if !is_on_floor():
		return false

	var front_ray = $VaultFrontRay
	var down_ray = $VaultDownRay

	if !front_ray.is_colliding():
		print("No obstacle in front")
		return false

	var obstacle = front_ray.get_collider()
	if obstacle == null:
		print("Front ray collider is null")
		return false

	var obstacle_pos = front_ray.get_collision_point()
	var player_pos = global_transform.origin
	var height_diff = obstacle_pos.y - player_pos.y

	# Adjust these values to match your scale (0.1)
	if height_diff < 0.2 or height_diff > 0.6:
		print("Obstacle height not vaultable:", height_diff)
		return false

	if !down_ray.is_colliding():
		print("No landing spot detected")
		return false

	print("Vault possible!")
	return true


func _ready():
	animation_state = animation_tree.get("parameters/playback")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	$VaultFrontRay.position = Vector3(0, 0.4, 0.3)
	$VaultFrontRay.target_position = Vector3(0, 0.0, 1.0)

	$VaultDownRay.position = Vector3(0, 0.6, 0.6)
	$VaultDownRay.target_position = Vector3(0, -1.0, 1.0)
	
	$VaultFrontRay.enabled = true
	$VaultDownRay.enabled = true


func _input(event):
	if event is InputEventMouseMotion:
		idle_timer = 0.0

func _process(delta):
	if anim_canmove:
		var root_pos = animation_tree.get_root_motion_position()
		var current_rotation = animation_tree.get_root_motion_rotation_accumulator().inverse() * get_quaternion()
		var root_velocity = current_rotation * root_pos / delta
		var root_rotation = animation_tree.get_root_motion_rotation()
		set_quaternion(get_quaternion() * root_rotation)
	else:
		var root_velocity = Vector3.ZERO

func _physics_process(delta):
	var input_vector = Vector2(
		Input.get_axis("left", "right"),
		Input.get_axis("backward", "forward")
	)

	var is_moving = input_vector.length() > 0.1
	is_sprinting = Input.is_action_pressed("sprint") and is_moving
	
	# Vault input
	var vault_pressed = Input.is_action_just_pressed("vault")
	if vault_pressed and !is_vaulting:
		trigger_vault()

	if third_person_camera and third_person_camera.has_method("set_movement_state"):
		third_person_camera.set_movement_state(is_moving, is_sprinting)

	if is_moving:
		input_vector = input_vector.normalized()
		if !jump_velocity_pending:
			anim_canmove = true

		var cam_basis = third_person_camera.global_transform.basis
		var cam_forward = -cam_basis.z.normalized()
		var cam_right = cam_basis.x.normalized()

		var move_dir = (cam_forward * input_vector.y + cam_right * input_vector.x).normalized()

		var target_rotation = atan2(move_dir.x, move_dir.z)
		rotation.y = lerp_angle(rotation.y, target_rotation, rotation_speed * delta)

		direction = move_dir
	else:
		anim_canmove = false
		direction = Vector3.ZERO

	if is_on_floor():
		if Input.is_action_just_pressed("jump"):
			is_jumping = true
			if !anim_canmove:
				jump_velocity_pending = true
				jump_timer = 0.0
			else:
				velocity.y = jump_velocity
		else:
			if !jump_velocity_pending:
				is_jumping = false
	else:
		velocity.y += gravity * delta

	if jump_velocity_pending:
		jump_timer += delta
		if jump_timer >= jump_velocity_delay:
			velocity.y = jump_velocity
			jump_velocity_pending = false
			jump_timer = 0.0

	animation_tree.set("parameters/conditions/startmove", anim_canmove)
	animation_tree.set("parameters/conditions/Idle", !anim_canmove)
	animation_tree.set("parameters/conditions/Run", is_sprinting)
	animation_tree.set("parameters/conditions/Jump", is_jumping)
	animation_tree.set("parameters/conditions/Walk", anim_canmove and !is_sprinting)
	animation_tree.set("parameters/conditions/Beam", is_sprinting and is_jumping)

	var speed = sprint_speed if is_sprinting else walk_speed
	var horizontal_velocity = direction * speed
	velocity.x = horizontal_velocity.x
	velocity.z = horizontal_velocity.z

	if !anim_canmove:
		velocity.x = 0.0
		velocity.z = 0.0

	move_and_slide()

	if !is_moving and is_on_floor():
		idle_timer += delta
		if idle_timer >= idle_trigger_time:
			var now = Time.get_ticks_msec()
			if (now - last_idle1_time > idle1_interval * 1000) and idle1 and !idle1.playing:
				idle1.play()
				last_idle1_time = now
	else:
		idle_timer = 0.0

	if third_person_camera:
		pass
	elif camera_root and camera_target:
		var local_offset = Vector3(0, follow_target_height_offset, camera_back_offset)
		local_offset = local_offset.rotated(Vector3.UP, rotation.y)
		camera_root.position = local_offset

func trigger_vault():
	if is_vaulting:
		return
	current_vault_animation = randi() % 2
	is_vaulting = true
	anim_canmove = false

	animation_tree.set("parameters/conditions/Vault", current_vault_animation == 0)
	animation_tree.set("parameters/conditions/Vault2", current_vault_animation == 1)

	await get_tree().create_timer(1.0).timeout  # Adjust this duration to match your Vault/Vault2 animation

	is_vaulting = false
	anim_canmove = true
	animation_tree.set("parameters/conditions/Vault", false)
	animation_tree.set("parameters/conditions/Vault2", false)

func player_sound():
	footstep.playing = true

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
