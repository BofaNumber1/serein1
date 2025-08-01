extends Node3D

@export var camera_target: Node3D
@export var follow_target: Node3D
@export var follow_target_height_offset := 1.5
@export var pitch_max := 50 
@export var pitch_min := -50
@export var yaw_sensitivity := 0.002
@export var pitch_sensitivity := 0.002

@export var camera: Camera3D  # Reference to the actual Camera3D node

# FOV Settings
@export var normal_fov := 70.0
@export var walk_fov := 75.0
@export var sprint_fov := 85.0
@export var fov_lerp_speed := 8.0

# Optional: export or set from player script
var is_moving := false
var is_sprinting := false

var yaw := 0.0
var pitch := 0.0

# New exported variable for left offset when walking
@export var walk_offset_x := 5.0  # Adjust this value for how far left camera moves when walking

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	top_level = true

func _input(event):
	if Input.is_action_just_pressed("exit") and event.is_pressed():
		if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	if event is InputEventMouseMotion and Input.get_mouse_mode() != Input.MOUSE_MODE_VISIBLE:
		yaw += -event.relative.x * yaw_sensitivity
		pitch += event.relative.y * pitch_sensitivity
		pitch = clamp(pitch, deg_to_rad(pitch_min), deg_to_rad(pitch_max))

func _physics_process(delta):
	# Yaw and pitch rotation
	camera_target.rotation.y = lerpf(camera_target.rotation.y, yaw, delta * 10)
	camera_target.rotation.x = lerpf(camera_target.rotation.x, pitch, delta * 10)

	if not follow_target:
		return

	# Calculate horizontal offset: 0 when idle, walk_offset_x when walking, no offset when sprinting
	var x_offset = 0.0
	if is_sprinting:
		x_offset = 0.0  # Centered for sprinting, or you can set another value if you want
	elif is_moving:
		x_offset = walk_offset_x

	# Follow player with offset behind (-20 Z), above, and slight x offset
	global_position = follow_target.global_position + Vector3(x_offset, follow_target_height_offset, -20)

	# FOV zoom logic
	if camera:
		var target_fov = normal_fov
		if is_sprinting:
			target_fov = sprint_fov
		elif is_moving:
			target_fov = walk_fov

		camera.fov = lerp(camera.fov, target_fov, fov_lerp_speed * delta)
