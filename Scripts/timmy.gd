extends CharacterBody3D

# Animation Parameters
@export var animation_player: AnimationPlayer
@onready var footstep = $footstep
@onready var idle1 = $IdleVoiceLine1

# Animation state tracking
var current_animation = ""
var previous_animation = ""
var animation_blend_time = 0.3

# Debug options
@export var debug_animations = false
var fall_start_height = 0.0
var min_fall_distance = 2.0

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
var is_falling = false
var is_stopping = false
var is_rolling = false

# Movement speeds
@export var walk_speed := 5
@export var sprint_speed := 30.0
@export var jump_velocity := 50.0
@export var gravity := -98.0

# Jump Timing System
var jump_timer := 0.0

# Idle Voice Line Timer
var idle_timer := 0.0
@export var idle_trigger_time := 15.0
@export var idle1_interval := 10.0
var last_idle1_time := 0.0

# === VAULT DETECTION SYSTEM ===
@export_group("Vault Settings")
@export var vault_detection_distance := 20.0
@export var table_height_min := 8.0
@export var table_height_max := 12.0

# Vault Detection Raycasts
@export var vault_raycast: RayCast3D
@export var vault_height_raycast: RayCast3D
@export var vault_clearance_raycast: RayCast3D

# Vault Detection Variables
var can_vault = false
var vault_object = null

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if animation_player:
		animation_player.animation_finished.connect(_on_animation_finished)
	play_animation("Idle0")

func _input(event):
	if event is InputEventMouseMotion:
		idle_timer = 0.0

func _process(delta):
	# Root motion handling would go here if needed
	pass

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
		if debug_animations:
			print("Triggering vault!")
		trigger_vault()
	elif vault_pressed and is_sprinting and !is_vaulting:
		if debug_animations:
			print("Vault pressed but can_vault is false")

	if third_person_camera and third_person_camera.has_method("set_movement_state"):
		third_person_camera.set_movement_state(is_moving, is_sprinting)

	if is_moving:
		input_vector = input_vector.normalized()
		if !is_vaulting:
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

	# Handle jumping
	if is_on_floor():
		if is_falling:
			var fall_distance = fall_start_height - global_position.y
			if debug_animations:
				print("Landed! Fall distance: ", fall_distance)
			is_falling = false
			
			# Only play roll if fell more than min distance
			if fall_distance > min_fall_distance:
				if debug_animations:
					print("Playing roll animation - fell ", fall_distance, " units")
				is_rolling = true
				play_animation("FallingToRoll0", 0.3)
			else:
				if debug_animations:
					print("No roll needed - only fell ", fall_distance, " units")
				play_animation("Idle0", 0.5)
		
		if Input.is_action_just_pressed("jump") and !is_vaulting:
			if debug_animations:
				print("Jump triggered!")
			is_jumping = true
			play_animation("VaultBothHands0", 0.2)  # Using VaultBothHands0 as jump animation
			velocity.y = jump_velocity
		else:
			if !is_vaulting:
				is_jumping = false
	else:
		velocity.y += gravity * delta
		if velocity.y < -10 and !is_jumping and !is_vaulting and !is_falling:
			is_falling = true
			fall_start_height = global_position.y
			if debug_animations:
				print("Started falling from height: ", fall_start_height)
			# Don't play falling animation, just track the fall

	# Removed jump velocity pending system for more responsive jumping

	# Animation logic
	handle_animations()

	var speed = sprint_speed if is_sprinting else walk_speed
	var horizontal_velocity = direction * speed
	velocity.x = horizontal_velocity.x
	velocity.z = horizontal_velocity.z

	if !anim_canmove and !is_stopping:
		velocity.x = 0.0
		velocity.z = 0.0
	elif is_stopping:
		# Gradually slow down during run_to_stop animation
		velocity.x = lerp(velocity.x, 0.0, 3.0 * delta)
		velocity.z = lerp(velocity.z, 0.0, 3.0 * delta)

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

func handle_animations():
	if is_vaulting or is_jumping or is_stopping or is_rolling:
		if debug_animations and (is_vaulting or is_jumping or is_stopping or is_rolling):
			print("Blocking animation change - vaulting:", is_vaulting, " jumping:", is_jumping, " stopping:", is_stopping, " rolling:", is_rolling)
		return  # Don't change animations during special states
	
	var target_animation = ""
	
	if anim_canmove:
		if is_sprinting:
			target_animation = "Running0"  # Use running animation
		else:
			target_animation = "Walking0"  # Use walking animation
	else:
		# Check if we were running and need to transition to stop
		if current_animation == "Running0":
			target_animation = "RunToStop0"  # Use run_to_stop animation
			is_stopping = true
		else:
			target_animation = "Idle0"  # Use idle animation
	
	if target_animation != current_animation:
		if debug_animations:
			print("Animation change: ", current_animation, " -> ", target_animation)
		play_animation(target_animation, 0.3)

func play_animation(animation_name: String, blend_time: float = -1.0):
	if !animation_player or animation_name == current_animation:
		return
	
	if blend_time < 0:
		blend_time = animation_blend_time
	
	previous_animation = current_animation
	current_animation = animation_name
	
	if animation_player.has_animation(animation_name):
		# Use the blend argument in play() for smooth transitions
		animation_player.play(animation_name, blend_time)
		if debug_animations:
			print("Playing animation: ", animation_name, " with blend: ", blend_time)
	else:
		print("Animation not found: ", animation_name)

func _on_animation_finished(animation_name: String):
	# Handle animation finish events
	match animation_name:
		"VaultBothHands0":
			# After vault/jump animation finishes
			if debug_animations:
				print("VaultBothHands0 finished - is_vaulting: ", is_vaulting, " is_jumping: ", is_jumping)
			is_vaulting = false
			is_jumping = false
			
			if !is_on_floor():
				# Still in air, start tracking fall
				if debug_animations:
					print("Still in air after jump/vault, tracking fall")
				is_falling = true
				fall_start_height = global_position.y
			else:
				# Direct landing - just go to idle
				if debug_animations:
					print("Direct landing from jump/vault")
				anim_canmove = true
				play_animation("Idle0", 0.4)
		
		"RunToStop0":
			# After run stop animation, go to idle
			is_stopping = false
			play_animation("Idle0", 0.4)
		
		# Removed Jumping02 - not using this animation anymore
		
		"FallingToRoll0":
			# After rolling animation, go to idle
			if debug_animations:
				print("Roll animation finished")
			is_rolling = false
			anim_canmove = true
			play_animation("Idle0", 0.4)

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
	
	is_vaulting = true
	anim_canmove = false
	play_animation("VaultBothHands0", 0.1)  # Quick blend into vault

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
