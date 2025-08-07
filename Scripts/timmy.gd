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

# === SIMPLE VAULT SYSTEM ===
@export_group("Vault Settings")
@export var vault_detection_distance := 20.0  # Adjusted for 0.1 scale
@export var table_height_min := 8.0  # Min table height in scaled units
@export var table_height_max := 12.0  # Max table height in scaled units

# Vault raycasts (to be added manually to scene)
@onready var vault_forward: RayCast3D = $VaultForward
@onready var vault_down: RayCast3D = $VaultDown

var can_vault_table = false


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
	
	# Check for table vaulting only when sprinting straight forward
	check_table_vault()
	
	# Vault input - only works when sprinting straight ahead
	var vault_pressed = Input.is_action_just_pressed("vault")
	if vault_pressed and can_vault_table and is_sprinting:
		trigger_table_vault()

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


func check_table_vault():
	"Check if there's a table ahead that can be vaulted - only when sprinting forward"
	can_vault_table = false
	
	# Only check when sprinting and moving forward
	if !is_sprinting or is_vaulting or !is_on_floor():
		return
	
	# Make sure we're moving mostly forward (not sideways)
	var input_vector = Vector2(
		Input.get_axis("left", "right"),
		Input.get_axis("backward", "forward")
	)
	
	# Only allow vaulting when moving straight forward (minimal sideways input)
	if abs(input_vector.x) > 0.3 or input_vector.y <= 0.7:
		return
	
	# Update raycast direction based on player facing
	var forward_dir = -transform.basis.z
	vault_forward.target_position = forward_dir * vault_detection_distance
	vault_forward.force_raycast_update()
	
	# Check if we hit something
	if !vault_forward.is_colliding():
		return
	
	var hit_point = vault_forward.get_collision_point()
	
	# Check if it's table height by casting down from above the obstacle
	vault_down.global_position = hit_point + Vector3.UP * 15.0  # Start above potential table
	vault_down.target_position = Vector3.DOWN * 25.0  # Cast down to find top
	vault_down.force_raycast_update()
	
	if vault_down.is_colliding():
		var table_top = vault_down.get_collision_point()
		var table_height = table_top.y - global_position.y
		
		# Check if it's within table height range
		if table_height >= table_height_min and table_height <= table_height_max:
			can_vault_table = true


func trigger_table_vault():
	"Perform a table vault - randomly pick Vault or Vault2"
	if is_vaulting:
		return
	
	is_vaulting = true
	anim_canmove = false
	
	# Randomly choose between the two vault animations
	var use_vault2 = randi() % 2 == 1
	
	# Reset conditions and set the chosen one
	animation_tree.set("parameters/conditions/Vault", false)
	animation_tree.set("parameters/conditions/Vault2", false)
	
	if use_vault2:
		animation_tree.set("parameters/conditions/Vault2", true)
		current_vault_animation = 1
	else:
		animation_tree.set("parameters/conditions/Vault", true)
		current_vault_animation = 0
	
	# Wait for vault animation to complete
	await get_tree().create_timer(1.0).timeout
	
	# Reset vault state
	is_vaulting = false
	anim_canmove = true
	animation_tree.set("parameters/conditions/Vault", false)
	animation_tree.set("parameters/conditions/Vault2", false)
	can_vault_table = false


# Legacy vault function (kept for compatibility)
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


# Audio and Camera Functions
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
