extends Node3D

@export var camera_pitch_node: Node3D
@export var pitch_min = -50.0
@export var pitch_max = 50.0
var yaw := 0.0
var pitch := 0.0
var yaw_sensitivity := 0.002
var pitch_sensitivity := 0.002

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	# Reset rotations to zero to avoid leftover rotation issues
	rotation = Vector3.ZERO
	camera_pitch_node.rotation = Vector3.ZERO

func _input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() != Input.MOUSE_MODE_VISIBLE:
		yaw -= event.relative.x * yaw_sensitivity
		pitch += event.relative.y * pitch_sensitivity  # NOTE the minus here to invert Y
		pitch = clamp(pitch, deg_to_rad(pitch_min), deg_to_rad(pitch_max))

func _physics_process(delta):
	# Yaw rotation: rotate around Y axis
	var yaw_basis = Basis(Vector3.UP, yaw)
	global_transform.basis = yaw_basis

	# Pitch rotation: rotate around X axis, applied to pitch node ONLY
	var pitch_basis = Basis(Vector3.RIGHT, pitch)
	# Multiply parent's basis (yaw) by pitch for local rotation
	camera_pitch_node.global_transform.basis = global_transform.basis * pitch_basis
