extends Node3D

@export var follow_target: Node3D
@export var camera: Camera3D

# Camera positioning
@export_group("Camera Position")
@export var distance_behind := 4.0
@export var height_offset := 1.5
@export var shoulder_offset := 0.0  # Positive = right shoulder, negative = left shoulder

# Camera sensitivity
@export_group("Camera Control")
@export var mouse_sensitivity := 0.002
@export var pitch_limit_up := 80.0
@export var pitch_limit_down := -60.0

# FOV settings
@export_group("Field of View")
@export var enable_dynamic_fov := true  # Toggle to disable FOV changes
@export var normal_fov := 70.0
@export var sprint_fov := 85.0
@export var aim_fov := 50.0
@export var fov_lerp_speed := 8.0

# Smoothing
@export_group("Camera Smoothing")
@export var position_smoothing := 10.0
@export var rotation_smoothing := 12.0

# Camera states
var yaw := 0.0
var pitch := 0.0
var current_fov := 70.0
var target_fov := 70.0

# State tracking
var is_moving := false
var is_sprinting := false
var is_aiming := false

# FOV stabilization
var movement_state_timer := 0.0
var sprint_state_timer := 0.0
@export var state_change_delay := 0.1  # Delay before changing FOV states

# Internal nodes
@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera_arm: Node3D = $CameraPivot/CameraArm

func _ready():
	# Set up the camera hierarchy if not already done
	if not camera_pivot:
		_setup_camera_hierarchy()
	
	# Capture mouse
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	current_fov = normal_fov
	target_fov = normal_fov

func _setup_camera_hierarchy():
	# Create camera pivot
	camera_pivot = Node3D.new()
	camera_pivot.name = "CameraPivot"
	add_child(camera_pivot)
	
	# Create camera arm
	camera_arm = Node3D.new()
	camera_arm.name = "CameraArm"
	camera_pivot.add_child(camera_arm)
	
	# Move camera to arm if it exists, otherwise create it
	if camera:
		if camera.get_parent():
			camera.get_parent().remove_child(camera)
		camera_arm.add_child(camera)
	else:
		camera = Camera3D.new()
		camera.name = "Camera3D"
		camera_arm.add_child(camera)

func _input(event):
	# Toggle mouse capture
	if Input.is_action_just_pressed("pause"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# Handle mouse movement - Camera rotation is completely independent of player rotation
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		yaw -= event.relative.x * mouse_sensitivity
		pitch -= event.relative.y * mouse_sensitivity
		pitch = clamp(pitch, deg_to_rad(-pitch_limit_up), deg_to_rad(-pitch_limit_down))

func _physics_process(delta):
	if not follow_target or not camera:
		return
	
	# Update camera position
	_update_camera_position(delta)
	
	# Update camera rotation
	_update_camera_rotation(delta)
	
	# Update FOV
	_update_fov(delta)

func _update_camera_position(delta):
	# Calculate target position behind the follow target
	var target_position = follow_target.global_position
	target_position.y += height_offset
	
	# Smooth position following
	global_position = global_position.lerp(target_position, position_smoothing * delta)

func _update_camera_rotation(delta):
	# Apply yaw to camera pivot
	camera_pivot.rotation.y = lerp_angle(camera_pivot.rotation.y, yaw, rotation_smoothing * delta)
	
	# Apply pitch to camera pivot
	camera_pivot.rotation.x = lerp_angle(camera_pivot.rotation.x, pitch, rotation_smoothing * delta)
	
	# Position camera arm behind the target
	var local_position = Vector3(shoulder_offset, 0, -distance_behind)
	camera_arm.position = camera_arm.position.lerp(local_position, position_smoothing * delta)

func _update_fov(delta):
	# Skip FOV changes if disabled
	if not enable_dynamic_fov:
		camera.fov = normal_fov
		return
	
	# Update state timers for stabilization
	if is_moving:
		movement_state_timer += delta
	else:
		movement_state_timer = 0.0
	
	if is_sprinting:
		sprint_state_timer += delta
	else:
		sprint_state_timer = 0.0
	
	# Determine target FOV based on stable state
	var new_target_fov = normal_fov
	
	if is_aiming:
		new_target_fov = aim_fov
	elif is_sprinting and sprint_state_timer > state_change_delay:
		new_target_fov = sprint_fov
	elif is_moving and movement_state_timer > state_change_delay:
		new_target_fov = normal_fov  # Keep normal FOV when just moving
	else:
		new_target_fov = normal_fov
	
	# Only update target_fov if it's significantly different to avoid micro-changes
	if abs(new_target_fov - target_fov) > 1.0:
		target_fov = new_target_fov
	
	# Smooth FOV transition with slower speed to reduce jitter
	current_fov = lerp(current_fov, target_fov, (fov_lerp_speed * 0.5) * delta)
	camera.fov = current_fov

# Public methods to control camera state
func set_movement_state(moving: bool, sprinting: bool = false):
	is_moving = moving
	is_sprinting = sprinting

func set_aiming(aiming: bool):
	is_aiming = aiming

func set_shoulder_offset(offset: float):
	shoulder_offset = offset

func set_over_shoulder_right():
	set_shoulder_offset(1.2)

func set_over_shoulder_left():
	set_shoulder_offset(-1.2)

func set_center():
	set_shoulder_offset(0.0)

# Get camera reference for external use
func get_camera() -> Camera3D:
	return camera
