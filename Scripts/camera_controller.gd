extends Node3D
class_name CameraController

# References
@onready var spring_arm: SpringArm3D = $SpringArm3D
@onready var camera: Camera3D = $SpringArm3D/Camera3D
@onready var player: CharacterBody3D = get_parent()

# Camera settings
@export var mouse_sensitivity: float = 0.3
@export var spring_length: float = 6.0
@export var camera_height: float = 2.0

# Movement-based positioning
@export var shoulder_offset: Vector3 = Vector3(1.0, 0, 0)  # Over-shoulder when moving
@export var stationary_offset: Vector3 = Vector3(0, 0, 0)  # Behind player when stationary
@export var position_lerp_speed: float = 5.0

# FOV settings
@export var default_fov: float = 70.0
@export var movement_fov: float = 85.0
@export var fov_lerp_speed: float = 8.0

# Camera bob
@export var bob_frequency: float = 2.0
@export var bob_amplitude: float = 0.1
@export var bob_lerp_speed: float = 12.0

# Camera shake
@export var shake_decay: float = 5.0
@export var max_shake_offset: float = 0.3

# Internal variables
var mouse_input: Vector2
var rotation_x: float = 0.0
var rotation_y: float = 0.0
var bob_timer: float = 0.0
var current_shake_strength: float = 0.0
var shake_offset: Vector3 = Vector3.ZERO
var current_offset: Vector3 = Vector3.ZERO

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	# Configure SpringArm3D
	spring_arm.spring_length = spring_length
	spring_arm.collision_mask = 1  # Adjust collision layers as needed
	spring_arm.add_excluded_object(player)  # Exclude player from collision
	position.y = camera_height  # Set the pivot height

func _input(event):
	if event is InputEventMouseMotion:
		mouse_input = event.relative

func _process(delta):
	
	handle_camera_rotation(delta)
	handle_camera_positioning(delta)
	handle_fov_changes(delta)
	handle_camera_bob(delta)
	handle_camera_shake(delta)

func handle_camera_rotation(delta):
	# Apply mouse input to rotation
	rotation_y -= mouse_input.x * mouse_sensitivity * delta
	rotation_x -= mouse_input.y * mouse_sensitivity * delta
	
	# Clamp vertical rotation
	rotation_x = clamp(rotation_x, -80, 80)
	
	# Apply rotations to the SpringArm, completely independent of parent rotation
	spring_arm.rotation = Vector3.ZERO
	spring_arm.rotate_y(rotation_y)
	spring_arm.rotate_object_local(Vector3.RIGHT, rotation_x)
	
	# Clear mouse input
	mouse_input = Vector2.ZERO

func handle_camera_positioning(delta):
	var player_velocity = player.velocity
	var is_moving = player_velocity.length() > 0.1
	
	# Calculate target offset based on movement
	var target_offset = stationary_offset
	if is_moving:
		target_offset = shoulder_offset
	
	# Smoothly interpolate the offset in local space
	current_offset = current_offset.lerp(target_offset, position_lerp_speed * delta)
	
	# Apply offset directly in local space - this stays relative to the SpringArm
	spring_arm.position = current_offset
	
	# Update spring length if needed
	spring_arm.spring_length = spring_length

func handle_fov_changes(delta):
	var player_velocity = player.velocity
	var speed = player_velocity.length()
	
	# Determine target FOV based on speed
	var target_fov = default_fov
	if speed > 0.1:
		# Increase FOV based on speed (you can adjust the multiplier)
		var speed_factor = min(speed / 10.0, 1.0)  # Normalize to 0-1
		target_fov = lerp(default_fov, movement_fov, speed_factor)
	
	# Smoothly transition FOV
	camera.fov = lerp(camera.fov, target_fov, fov_lerp_speed * delta)

func handle_camera_bob(delta):
	var player_velocity = player.velocity
	var horizontal_speed = Vector2(player_velocity.x, player_velocity.z).length()
	
	if horizontal_speed > 0.1:
		bob_timer += delta * bob_frequency * (horizontal_speed / 5.0)  # Scale with speed
		var bob_offset = Vector3(
			sin(bob_timer) * bob_amplitude * 0.5,  # Horizontal bob
			sin(bob_timer * 2.0) * bob_amplitude,  # Vertical bob (twice the frequency)
			0
		)
		
		# Apply bob to camera
		var target_pos = Vector3(0, 0, 0) + bob_offset + shake_offset
		camera.position = camera.position.lerp(target_pos, bob_lerp_speed * delta)
	else:
		# Return to center when not moving
		bob_timer = 0.0
		var target_pos = Vector3(0, 0, 0) + shake_offset
		camera.position = camera.position.lerp(target_pos, bob_lerp_speed * delta)

func handle_camera_shake(delta):
	if current_shake_strength > 0:
		# Generate random shake offset
		shake_offset = Vector3(
			randf_range(-current_shake_strength, current_shake_strength),
			randf_range(-current_shake_strength, current_shake_strength),
			0
		) * max_shake_offset
		
		# Decay shake over time
		current_shake_strength -= shake_decay * delta
		current_shake_strength = max(current_shake_strength, 0)
	else:
		shake_offset = Vector3.ZERO

# Call this function to trigger camera shake
func add_camera_shake(strength: float):
	current_shake_strength = min(current_shake_strength + strength, 1.0)

# Optional: Call this from your player script based on movement speed
func _on_player_speed_changed(speed: float):
	if speed > 8.0:  # Adjust threshold as needed
		add_camera_shake(0.1)  # Adjust shake intensity
