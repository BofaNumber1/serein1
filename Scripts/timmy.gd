extends CharacterBody3D

# Animation Parameters
@export var animation_tree: AnimationTree
@export var animation_player: AnimationPlayer
var animation_state
@onready var footstep = $footstep
@onready var idle1 = $IdleVoiceLine1
var current_vault_animation = 0

@export var camera_root: Node3D
@export var camera_target: Node3D

# New Camera System
@export var third_person_camera: Node3D

# Camera Follow Offsets (Legacy)
@export var follow_target_height_offset := 1.5
@export var camera_back_offset := -4.0

# Movement and rotation
@export var turn_speed := 4
@export var rotation_speed := 5

# Player Parameters
var direction = Vector3()
var anim_canmove = false
var is_sprinting = false
var is_jumping = false
var is_vaulting = false

# Movement speeds
@export var walk_speed := 5
@export var sprint_speed := 30.0
@export var jump_velocity := 20.0
@export var gravity := -200.0

# Jump Timing System
@export var jump_velocity_delay := 1.2  # Delay in seconds before applying upward velocity
var jump_timer := 0.0
var jump_velocity_pending := false

# Idle Voice Line Timer
var idle_timer := 0.0
@export var idle_trigger_time := 15.0
@export var idle1_interval := 10.0
var last_idle1_time := 0.0

# === VAULT DETECTION SYSTEM ===
@export_group("Vault Settings")
@export var vault_detection_distance := 20.0  # Adjusted for 0.1 scale
@export var table_height_min := 8.0  # Min table height in scaled units
@export var table_height_max := 12.0  # Max table height in scaled units

# Vault Detection Raycasts
@export var vault_raycast: RayCast3D
@export var vault_height_raycast: RayCast3D
@export var vault_clearance_raycast: RayCast3D

# Vault Detection Variables
var can_vault = false
var vault_object = null


func _ready():
	animation_state = animation_tree.get("parameters/playback")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


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
	var vault_pressed = Input.is_action_just_pressed("vault")
	
	# Update vault detection
	can_vault = check_vault_conditions()
	
	# Check vault input with detection system
	if vault_pressed and is_sprinting and !is_vaulting and can_vault:
		print("Triggering vault!")
		trigger_vault()
	elif vault_pressed and is_sprinting and !is_vaulting:
		print("Vault pressed but can_vault is false")

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

	# Set animation conditions
	animation_tree.set("parameters/conditions/startmove", anim_canmove)
	animation_tree.set("parameters/conditions/Idle", !anim_canmove)
	animation_tree.set("parameters/conditions/Run", is_sprinting)
	animation_tree.set("parameters/conditions/Jump", is_jumping)
	animation_tree.set("parameters/conditions/Walk", anim_canmove and !is_sprinting)
	animation_tree.set("parameters/conditions/Beam", is_sprinting and is_jumping)
	# Reset vault conditions when not vaulting to prevent auto-triggering
	if !is_vaulting:
		animation_tree.set("parameters/conditions/Vault", false)
		animation_tree.set("parameters/conditions/Vault2", false)

	var speed = sprint_speed if is_sprinting else walk_speed
	var horizontal_velocity = direction * speed
	velocity.x = horizontal_velocity.x
	velocity.z = horizontal_velocity.z

	if !anim_canmove:
		velocity.x = 0.0
		velocity.z = 0.0

	move_and_slide()

	# Handle idle voice lines
	if !is_moving and is_on_floor():
		idle_timer += delta
		if idle_timer >= idle_trigger_time:
			var now = Time.get_ticks_msec()
			if (now - last_idle1_time > idle1_interval * 1000) and idle1 and !idle1.playing:
				idle1.play()
				last_idle1_time = now
	else:
		idle_timer = 0.0

	# Update camera
	if third_person_camera:
		pass
	elif camera_root and camera_target:
		var local_offset = Vector3(0, follow_target_height_offset, camera_back_offset)
		local_offset = local_offset.rotated(Vector3.UP, rotation.y)
		camera_root.position = local_offset


# === VAULT DETECTION SYSTEM ===
func check_vault_conditions() -> bool:
	# If raycasts aren't set up yet, allow vaulting (fallback to old behavior)
	if !vault_raycast or !vault_height_raycast or !vault_clearance_raycast:
		print("Vault raycasts not set up - allowing vault anyway")
		return true
	
	print("Checking vault conditions...")
	
	# Enable the raycasts
	vault_raycast.enabled = true
	vault_height_raycast.enabled = true
	vault_clearance_raycast.enabled = true
	
	# Check if there's an obstacle in front
	if !vault_raycast.is_colliding():
		print("No collision detected by vault_raycast")
		return false
	
	print("Vault raycast is colliding")
	
	var hit_object = vault_raycast.get_collider()
	if !hit_object:
		print("No hit object found")
		return false
	
	print("Hit object: ", hit_object.name)
	
	# Check if the obstacle is the right height for vaulting
	var hit_point = vault_raycast.get_collision_point()
	var player_y = global_position.y
	var obstacle_height = hit_point.y - player_y
	
	print("Obstacle height: ", obstacle_height, " Min: ", table_height_min * 0.1, " Max: ", table_height_max * 0.1)
	
	# Check if height is within vaultable range (scaled for 0.1 player)
	if obstacle_height < table_height_min * 0.1 or obstacle_height > table_height_max * 0.1:
		print("Height outside vaultable range")
		return false
	
	print("Height is good for vaulting")
	
	# Check if there's clearance above the obstacle for landing
	vault_clearance_raycast.global_position = hit_point + Vector3(0, obstacle_height + 0.2, 0)
	vault_clearance_raycast.force_raycast_update()
	
	if vault_clearance_raycast.is_colliding():
		print("No clearance above obstacle")
		return false  # Not enough clearance above
	
	vault_object = hit_object
	print("Vault conditions met!")
	return true


# === VAULT FUNCTIONS ===
func trigger_vault():
	if is_vaulting:
		return
	current_vault_animation = randi() % 2
	is_vaulting = true
	anim_canmove = false

	animation_tree.set("parameters/conditions/Vault", current_vault_animation == 0)
	animation_tree.set("parameters/conditions/Vault2", current_vault_animation == 1)

	await get_tree().create_timer(1.0).timeout

	is_vaulting = false
	anim_canmove = true
	animation_tree.set("parameters/conditions/Vault", false)
	animation_tree.set("parameters/conditions/Vault2", false)


# === AUDIO AND CAMERA FUNCTIONS ===
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
