extends Node3D

@export var camera_target : Node3D
@export var pitch_max = 50
@export var pitch_min = -50
@export var camera_distance = 5.0  # New variable to control camera distance (adjust this to zoom in)
var yaw = float()
var pitch = float()
var yaw_sens = 0.002
var pitch_sens = 0.002

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	# Optionally set initial camera position if needed
	if camera_target.get_node_or_null("Camera3D"):
		var camera = camera_target.get_node("Camera3D")
		camera.transform.origin = Vector3(0, 0, camera_distance)  # Move camera closer

func _input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() != 0:
		yaw += -event.relative.x * yaw_sens
		pitch += event.relative.y * pitch_sens
		pitch = clamp(pitch, deg_to_rad(pitch_min), deg_to_rad(pitch_max))

func _physics_process(delta):
	camera_target.rotation.y = lerpf(camera_target.rotation.y, yaw, delta * 10)
	camera_target.rotation.x = lerpf(camera_target.rotation.x, pitch, delta * 10)
	# Ensure camera stays at desired distance
	if camera_target.get_node_or_null("Camera3D"):
		var camera = camera_target.get_node("Camera3D")
		camera.transform.origin = Vector3(0, 0, camera_distance)  # Maintain distance
